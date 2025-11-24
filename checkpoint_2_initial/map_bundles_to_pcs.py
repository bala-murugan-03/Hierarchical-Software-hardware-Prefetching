#!/usr/bin/env python3


import sys
import json
import subprocess
import re

if len(sys.argv) != 4:
    print("Usage: map_bundles_to_pcs.py <binary> <bundles.json> <out_bundles_pc.json>")
    sys.exit(1)

binary = sys.argv[1]
infile = sys.argv[2]
outfile = sys.argv[3]

# 1) get disassembly
p = subprocess.run(["objdump", "-d", binary], stdout=subprocess.PIPE, stderr=subprocess.PIPE, encoding='utf-8')
asm = p.stdout

# 2) build map: function_name -> (start_addr, end_addr)

func_starts = {}
func_order = []
for line in asm.splitlines():
    m = re.match(r'([0-9a-fA-F]+) <(.+)>:', line)
    if m:
        addr = int(m.group(1), 16)
        name = m.group(2)
        func_starts[name] = addr
        func_order.append((addr, name))

# sort functions by address so we can estimate end address as next func - 1

func_order.sort()

func_ranges = {}
for i, (addr, name) in enumerate(func_order):
    start = addr
    if i+1 < len(func_order):
        end = func_order[i+1][0] - 1
    else:
        # last function -> estimate end by scanning for ret or use start+4096
        end = start + 4096
    func_ranges[name] = (start, end)

# 3) load bundles.json and map functions to addresses
with open(infile) as f:
    j = json.load(f)

out = {"BundleEntries": []}

for b in j["BundleEntries"]:
    fname = b["function"]
    if fname in func_ranges:
        start_addr, end_addr = func_ranges[fname]
        nb = dict(b)  # copy
        # write as hex strings (easy to read & use)
        nb["start_pc"] = hex(start_addr)
        nb["end_pc"] = hex(end_addr)
        out["BundleEntries"].append(nb)
    else:
        print(f"Warning: function {fname} not found in binary symbols; skipping")

with open(outfile, "w") as f:
    json.dump(out, f, indent=4)

print("Wrote", outfile)

