#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Analysis/CallGraph.h"
#include <fstream>
#include <set>
#include <map>
#include <nlohmann/json.hpp>

using namespace llvm;
using json = nlohmann::json;

int main(int argc, char **argv) {
    if (argc < 2) {
        errs() << "Usage: callgraph_bundle <input.ll>\n";
        return 1;
    }

    LLVMContext Ctx;
    SMDiagnostic Err;
    auto Mod = parseIRFile(argv[1], Err, Ctx);
    if (!Mod) { Err.print(argv[0], errs()); return 1; }

    CallGraph CG(*Mod);
    json jroot;
    json jbundles = json::array();
    std::map<std::string, unsigned> funcSizes;

    // --- Step 1: measure each function ---
    for (Function &F : *Mod) {
        if (F.isDeclaration()) continue;
        unsigned instCount = 0;
        for (auto &BB : F) instCount += BB.size();
        funcSizes[F.getName().str()] = instCount;
    }

    // --- Step 2: build call graph output ---
    std::ofstream g("callgraph.txt");
    g << "Caller -> Callee\n";
    for (auto &nodePair : CG) {
        const Function *F = nodePair.first;
        if (!F || F->isDeclaration()) continue;
        auto *Node = nodePair.second.get();
        for (auto &CallRecord : *Node) {
            Function *Callee = CallRecord.second->getFunction();
            if (Callee && !Callee->isDeclaration())
                g << F->getName().str() << " -> " << Callee->getName().str() << "\n";
        }
    }
    g.close();

    // --- Step 2b: write DOT graph for visualization ---
    std::ofstream dot("callgraph.dot");
    dot << "digraph CallGraph {\n";
    dot << "  node [shape=box, style=filled, color=lightblue];\n";

    for (auto &nodePair : CG) {
        const Function *F = nodePair.first;
        if (!F || F->isDeclaration()) continue;
        auto *Node = nodePair.second.get();

        for (auto &CallRecord : *Node) {
            Function *Callee = CallRecord.second->getFunction();
            if (Callee && !Callee->isDeclaration()) {
                dot << "  \"" << F->getName().str() << "\" -> \"" 
                    << Callee->getName().str() << "\";\n";
            }
        }
    }
    dot << "}\n";
    dot.close();

    // --- Step 3: mark bundles with start/end instruction pointers ---
    const unsigned THRESHOLD = 50;
    std::map<const Instruction*, unsigned> instrIDMap; // assign unique ID to each instruction
    unsigned globalID = 0;

    for (Function &F : *Mod) {
        if (F.isDeclaration()) continue;

        for (auto &BB : F) {
            for (auto &I : BB) {
                instrIDMap[&I] = globalID++;
            }
        }
    }

    for (auto &it : funcSizes) {
        std::string fname = it.first;
        unsigned totalSize = it.second;

        // --- calculate reachable size including direct callees ---
        for (auto &nodePair : CG) {
            const Function *F = nodePair.first;
            if (!F || F->isDeclaration()) continue;
            if (F->getName() == fname) {
                auto *Node = nodePair.second.get();
                for (auto &CallRecord : *Node) {
                    Function *Callee = CallRecord.second->getFunction();
                    if (Callee && !Callee->isDeclaration())
                        totalSize += funcSizes[Callee->getName().str()];
                }
            }
        }

        if (totalSize >= THRESHOLD) {
            const Function *F = Mod->getFunction(fname);
            if (!F) continue;

            // Use instruction IDs as start/end PCs
            const Instruction* firstInst = nullptr;
            const Instruction* lastInst = nullptr;

            for (auto &BB : *F) {
                for (auto &I : BB) {
                    if (!firstInst) firstInst = &I;
                    lastInst = &I;
                }
            }

            if (!firstInst || !lastInst) continue;

            json b;
            b["function"] = fname;
            b["reachable_size"] = totalSize;
            b["start_pc"] = instrIDMap[firstInst];
            b["end_pc"] = instrIDMap[lastInst];
            jbundles.push_back(b);
        }
    }

    jroot["BundleEntries"] = jbundles;
    std::ofstream o("bundles.json");
    o << jroot.dump(4);
    o.close();

    outs() << "Generated callgraph.txt, callgraph.dot and bundles.json with instruction pointers\n";
    return 0;
}

