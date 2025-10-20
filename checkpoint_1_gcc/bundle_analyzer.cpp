#include <elf.h>
#include <gelf.h>
#include <libelf.h>
#include <capstone/capstone.h>

#include <fcntl.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <unistd.h>

#include <iostream>
#include <fstream>
#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <string>
#include <algorithm>
#include <functional>
#include <cassert>
#include <ctime>

#include "nlohmann/json.hpp"
using json = nlohmann::json;

// --------------------- STRUCTS ----------------------

struct FuncSym {
    std::string name;
    uint64_t addr;
    uint64_t size;
    uint64_t end() const { return addr + size; }
};

struct Bundle {
    int id;
    std::string entry;
    std::vector<std::string> functions;
    uint64_t static_size_bytes;
    uint64_t reachable_bytes;
    uint64_t start;
    uint64_t end;
};

// --------------------- ELF READER ----------------------

bool read_elf_symbols(const std::string &binary,
                      std::vector<FuncSym> &functions,
                      uint64_t &text_vaddr,
                      uint64_t &text_offset,
                      uint64_t &text_size)
{
    if (elf_version(EV_CURRENT) == EV_NONE) {
        std::cerr << "libelf init failed\n";
        return false;
    }

    int fd = open(binary.c_str(), O_RDONLY);
    if (fd < 0) { perror("open"); return false; }

    Elf *e = elf_begin(fd, ELF_C_READ, nullptr);
    if (!e) { std::cerr << "elf_begin failed\n"; close(fd); return false; }

    size_t shstrndx;
    if (elf_getshdrstrndx(e, &shstrndx) != 0) {
        std::cerr << "elf_getshdrstrndx failed\n";
    }

    Elf_Scn *scn = nullptr, *sym_scn = nullptr;
    GElf_Shdr shdr;
    text_vaddr = text_offset = text_size = 0;

    while ((scn = elf_nextscn(e, scn)) != nullptr) {
        if (!gelf_getshdr(scn, &shdr)) continue;
        const char *name = elf_strptr(e, shstrndx, shdr.sh_name);
        if (!name) continue;
        std::string sname(name);
        if (sname == ".text") {
            text_vaddr = shdr.sh_addr;
            text_offset = shdr.sh_offset;
            text_size = shdr.sh_size;
        }
        if (sname == ".symtab") sym_scn = scn;
    }

    if (!sym_scn) {
        std::cerr << "No .symtab (binary likely stripped)\n";
        elf_end(e); close(fd);
        return false;
    }

    Elf_Data *sym_data = elf_getdata(sym_scn, nullptr);
    size_t symcount = gelf_getshdr(sym_scn, &shdr) ? (shdr.sh_size / shdr.sh_entsize) : 0;

    for (size_t i = 0; i < symcount; ++i) {
        GElf_Sym sym;
        if (!gelf_getsym(sym_data, i, &sym)) continue;
        if (GELF_ST_TYPE(sym.st_info) != STT_FUNC) continue;
        if (sym.st_size == 0) continue;
        if (sym.st_shndx == SHN_UNDEF) continue;

        FuncSym fs;
        fs.name = elf_strptr(e, shdr.sh_link, sym.st_name);
        fs.addr = sym.st_value;
        fs.size = sym.st_size;

        if (fs.addr >= text_vaddr && fs.end() <= text_vaddr + text_size)
            functions.push_back(fs);
    }

    std::sort(functions.begin(), functions.end(), [](auto &a, auto &b){return a.addr < b.addr;});
    elf_end(e);
    close(fd);
    return true;
}

// --------------------- DISASSEMBLY ----------------------

bool build_call_graph(const std::string &binary,
                      const std::vector<FuncSym> &functions,
                      std::vector<std::vector<size_t>> &children,
                      std::vector<std::vector<size_t>> &parents,
                      uint64_t text_vaddr, uint64_t text_offset)
{
    int fd = open(binary.c_str(), O_RDONLY);
    if (fd < 0) { perror("open"); return false; }

    struct stat st; fstat(fd, &st);
    size_t file_size = st.st_size;
    void *map_base = mmap(nullptr, file_size, PROT_READ, MAP_PRIVATE, fd, 0);
    if (map_base == MAP_FAILED) { perror("mmap"); close(fd); return false; }

    children.assign(functions.size(), {});
    parents.assign(functions.size(), {});

    csh handle;
    if (cs_open(CS_ARCH_X86, CS_MODE_64, &handle) != CS_ERR_OK) {
        std::cerr << "Capstone open failed\n";
        munmap(map_base, file_size); close(fd);
        return false;
    }
    cs_option(handle, CS_OPT_DETAIL, CS_OPT_ON);
    unsigned char *bytes = reinterpret_cast<unsigned char *>(map_base);

    auto find_func_by_addr = [&](uint64_t addr)->std::optional<size_t>{
        for (size_t i=0;i<functions.size();++i)
            if (addr>=functions[i].addr && addr<functions[i].end()) return i;
        return std::nullopt;
    };

    for (size_t i = 0; i < functions.size(); ++i) {
        const FuncSym &f = functions[i];
        uint64_t offset_in_file = (f.addr - text_vaddr) + text_offset;
        const uint8_t *code = bytes + offset_in_file;
        size_t size = f.size;

        cs_insn *insn;
        size_t count = cs_disasm(handle, code, size, f.addr, 0, &insn);
        for (size_t j = 0; j < count; ++j) {
            if (insn[j].id == X86_INS_CALL) {
                cs_x86 x86 = insn[j].detail->x86;
                for (int k = 0; k < x86.op_count; ++k)
                    if (x86.operands[k].type == X86_OP_IMM) {
                        uint64_t target = (uint64_t)x86.operands[k].imm;
                        auto idx = find_func_by_addr(target);
                        if (idx && *idx != i) {
                            children[i].push_back(*idx);
                            parents[*idx].push_back(i);
                        }
                    }
            }
        }
        cs_free(insn, count);
    }

    cs_close(&handle);
    munmap(map_base, file_size);
    close(fd);
    return true;
}

// --------------------- REACHABLE SIZE ----------------------

void compute_reachable(const std::vector<FuncSym> &functions,
                       const std::vector<std::vector<size_t>> &children,
                       std::vector<uint64_t> &reachable)
{
    size_t n = functions.size();
    reachable.assign(n, UINT64_MAX);
    std::function<uint64_t(size_t)> dfs = [&](size_t idx)->uint64_t {
        if (reachable[idx] != UINT64_MAX) return reachable[idx];
        uint64_t total = functions[idx].size;
        for (size_t c : children[idx]) total += dfs(c);
        reachable[idx] = total;
        return total;
    };
    for (size_t i = 0; i < n; ++i) dfs(i);
}

// --------------------- BUNDLE SELECTION ----------------------

void find_bundles(const std::vector<FuncSym> &functions,
                  const std::vector<std::vector<size_t>> &children,
                  const std::vector<std::vector<size_t>> &parents,
                  const std::vector<uint64_t> &reachable,
                  uint64_t threshold,
                  std::vector<Bundle> &out)
{
    for (size_t i = 0; i < functions.size(); ++i) {
        uint64_t sz = reachable[i];
        if (sz < threshold) continue;
        bool isEntry = false;
        if (parents[i].empty()) isEntry = true;
        else {
            for (size_t p : parents[i]) {
                uint64_t diff = (reachable[p] > sz) ? (reachable[p] - sz) : 0;
                if (diff > threshold && sz > threshold) {
                    isEntry = true;
                    break;
                }
            }
        }
        if (isEntry) {
            Bundle b;
            b.id = out.size() + 1;
            b.entry = functions[i].name;
            b.static_size_bytes = functions[i].size;
            b.reachable_bytes = sz;
            b.start = functions[i].addr;
            b.end = functions[i].end();
            std::unordered_set<size_t> visited;
            std::function<void(size_t)> dfs = [&](size_t idx){
                if (visited.count(idx)) return;
                visited.insert(idx);
                b.functions.push_back(functions[idx].name);
                for (size_t c : children[idx]) dfs(c);
            };
            dfs(i);
            out.push_back(b);
        }
    }
}

// --------------------- JSON WRITER ----------------------

void write_bundles_to_json(const std::vector<Bundle> &bundles,
                           const std::string &binary_name,
                           uint64_t threshold,
                           const std::string &output_path = "bundles.json")
{
    json out;
    out["binary"] = binary_name;
    out["threshold_bytes"] = threshold;
    std::time_t now = std::time(nullptr);
    out["timestamp"] = std::asctime(std::localtime(&now));
    out["BundleEntries"] = json::array();

    for (auto &b : bundles) {
        json jb;
        jb["id"] = b.id;
        jb["entry"] = b.entry;
        jb["functions"] = b.functions;
        jb["static_size_bytes"] = b.static_size_bytes;
        jb["reachable_bytes"] = b.reachable_bytes;
        jb["start"] = b.start;
        jb["end"] = b.end;
        out["BundleEntries"].push_back(jb);
    }

    std::ofstream ofs(output_path);
    ofs << out.dump(4);
    ofs.close();
    std::cout << "✅ Wrote " << bundles.size() << " bundles to " << output_path << "\n";
}

// --------------------- MAIN ----------------------

int main(int argc, char **argv)
{
    if (argc < 2) {
        std::cerr << "Usage: " << argv[0] << " <binary> [threshold_kb]\n";
        return 1;
    }

    std::string binary = argv[1];
    //uint64_t threshold = (argc >= 3) ? std::stoull(argv[2]) * 1024ULL : 200ULL * 1024ULL;
    uint64_t threshold = (argc >= 3) ? (uint64_t)(std::stod(argv[2]) * 1024.0) : 200ULL * 1024ULL;

    std::vector<FuncSym> functions;
    uint64_t text_vaddr=0, text_offset=0, text_size=0;

    if (!read_elf_symbols(binary, functions, text_vaddr, text_offset, text_size))
        return 1;

    std::vector<std::vector<size_t>> children, parents;
    if (!build_call_graph(binary, functions, children, parents, text_vaddr, text_offset))
        return 1;

    std::vector<uint64_t> reachable;
    compute_reachable(functions, children, reachable);

    std::vector<Bundle> bundles;
    find_bundles(functions, children, parents, reachable, threshold, bundles);

    write_bundles_to_json(bundles, binary, threshold);
    return 0;
}

