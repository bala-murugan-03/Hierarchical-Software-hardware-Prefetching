#!/usr/bin/env python3


import sys
import math


KEY_INSTR = "simInsts"
KEY_CYCLES = "system.cpu.numCycles"
KEY_IPC = "system.cpu.ipc"
KEY_CPI = "system.cpu.cpi"
KEY_L1D_MISS = "system.cpu.dcache.demandMisses::total"
KEY_L1I_MISS = "system.cpu.icache.demandMisses::total"
KEY_L2_MISS = "system.l2.demandMisses::total"

WANTED_KEYS = [
    KEY_INSTR, KEY_CYCLES, KEY_IPC, KEY_CPI,
    KEY_L1D_MISS, KEY_L1I_MISS, KEY_L2_MISS
]

def parse_stats(path):
    stats = {}
    try:
        with open(path, "r", errors="replace") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#') or line.startswith('-----'):
                    continue
                parts = line.split()
                if len(parts) < 2:
                    continue
                key = parts[0]
                # value might be NON-NUMERIC (e.g. "nan") — handle gracefully
                try:
                    val = float(parts[1])
                except:
                    try:
                        val = float(parts[1].replace(",", ""))
                    except:
                        continue
                if key in WANTED_KEYS:
                    stats[key] = val
    except FileNotFoundError:
        print(f"Error: file not found: {path}", file=sys.stderr)
        sys.exit(2)
    return stats

def safe_get(d, key):
    return d.get(key, None)

def mpki(misses, insts):
    if insts is None or insts == 0 or misses is None:
        return None
    return (misses / insts) * 1000.0

def print_summary(label, stats):
    insts = safe_get(stats, KEY_INSTR)
    cycles = safe_get(stats, KEY_CYCLES)
    ipc = safe_get(stats, KEY_IPC)
    cpi = safe_get(stats, KEY_CPI)
    l1d = safe_get(stats, KEY_L1D_MISS)
    l1i = safe_get(stats, KEY_L1I_MISS)
    l2 = safe_get(stats, KEY_L2_MISS)

    # fallback - derive IPC/CPI if missing but possible
    if ipc is None and insts and cycles:
        ipc = insts / cycles if cycles != 0 else None
    if cpi is None and insts and cycles:
        cpi = cycles / insts if insts != 0 else None

    print(f"--- {label} ---")
    def p(name, value, fmt="{:.6g}"):
        if value is None:
            print(f"{name:18s}: NOT FOUND")
        else:
            print(f"{name:18s}: {fmt.format(value)}")

    p("Instructions", insts, "{:.0f}")
    p("Cycles", cycles, "{:.0f}")
    p("IPC", ipc, "{:.6f}")
    p("CPI", cpi, "{:.6f}")
    p("L1D misses", l1d, "{:.0f}")
    lk = mpki(l1d, insts)
    p("L1D MPKI", lk, "{:.6f}")
    p("L1I misses", l1i, "{:.0f}")
    p("L1I MPKI", mpki(l1i, insts), "{:.6f}")
    p("L2 misses", l2, "{:.0f}")
    p("L2 MPKI", mpki(l2, insts), "{:.6f}")
    print()

def compare_stats(base, pref):
    b_ipc = safe_get(base, KEY_IPC)
    p_ipc = safe_get(pref, KEY_IPC)

    # derive if missing
    if b_ipc is None and base.get(KEY_INSTR) and base.get(KEY_CYCLES):
        b_ipc = base[KEY_INSTR] / base[KEY_CYCLES]
    if p_ipc is None and pref.get(KEY_INSTR) and pref.get(KEY_CYCLES):
        p_ipc = pref[KEY_INSTR] / pref[KEY_CYCLES]

    if b_ipc and p_ipc:
        speedup = p_ipc / b_ipc if b_ipc != 0 else math.nan
        print("=== Comparison ===")
        print(f"Baseline IPC: {b_ipc:.6f}")
        print(f"Prefetch  IPC: {p_ipc:.6f}")
        print(f"IPC Speedup (prefetch / baseline): {speedup:.6f}")
    else:
        print("IPC values not available for comparison.")

    # MPKI comparisons
    def print_mpki(key, label):
        b_mpki = mpki(base.get(key), base.get(KEY_INSTR))
        p_mpki = mpki(pref.get(key), pref.get(KEY_INSTR))
        if b_mpki is None or p_mpki is None:
            print(f"{label:10s}: MPKI not available for one of the runs")
            return
        delta = ((p_mpki - b_mpki) / b_mpki * 100.0) if b_mpki != 0 else float('inf')
        print(f"{label:10s}: baseline={b_mpki:.6f}, prefetch={p_mpki:.6f}, delta%={delta:.2f}%")

    print()
    print_mpki(KEY_L1D_MISS, "L1D MPKI")
    print_mpki(KEY_L2_MISS, "L2 MPKI")
    print_mpki(KEY_L1I_MISS, "L1I MPKI")
    print()

def main():
    if len(sys.argv) < 2:
        print("Usage: compute_m5_stats_clean.py baseline_stats.txt [prefetch_stats.txt]")
        sys.exit(1)

    base_path = sys.argv[1]
    base_stats = parse_stats(base_path)
    print_summary("Baseline", base_stats)

    if len(sys.argv) >= 3:
        pref_path = sys.argv[2]
        pref_stats = parse_stats(pref_path)
        print_summary("Prefetch", pref_stats)
        compare_stats(base_stats, pref_stats)

if __name__ == "__main__":
    main()

