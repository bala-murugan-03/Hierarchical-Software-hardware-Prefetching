#!/usr/bin/env python3

import sys
import math
import os
import matplotlib.pyplot as plt
import numpy as np

# --- stat keys used in your runs ---
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
        print(f"Warning: file not found: {path}", file=sys.stderr)
        return None
    return stats

def safe_get(d, key):
    if not d:
        return None
    return d.get(key, None)

def mpki(misses, insts):
    if insts is None or insts == 0 or misses is None:
        return None
    return (misses / insts) * 1000.0

def derive_ipc(stats):
    if not stats:
        return None
    ipc = safe_get(stats, KEY_IPC)
    if ipc is None:
        insts = safe_get(stats, KEY_INSTR)
        cycles = safe_get(stats, KEY_CYCLES)
        if insts is not None and cycles and cycles != 0:
            return insts / cycles
        return None
    return ipc

def extract_metrics(stats):

    if not stats:
        return (None, None, None, None)
    insts = safe_get(stats, KEY_INSTR)
    ipc = derive_ipc(stats)
    l1d = safe_get(stats, KEY_L1D_MISS)
    l1i = safe_get(stats, KEY_L1I_MISS)
    l2 = safe_get(stats, KEY_L2_MISS)
    return (ipc, mpki(l1i, insts), mpki(l1d, insts), mpki(l2, insts))

def pretty(x):
    if x is None or (isinstance(x, float) and (math.isnan(x) or math.isinf(x))):
        return "N/A"
    if isinstance(x, float) and abs(x) >= 1000:
        return f"{x:,.0f}"
    elif isinstance(x, float):
        return f"{x:.3f}"
    else:
        return str(x)

def plot_speedup_and_mpki(labels, metrics, out_png="m5_stats_speedup_mpki.png"):


    baseline_label, initial_label, improved_label = labels
    ipc_vals = metrics["IPC"]   # [baseline, initial, improved]
    l1i_vals = metrics["L1I"]
    l1d_vals = metrics["L1D"]
    l2_vals  = metrics["L2"]


    base_ipc = ipc_vals[0]
    speed_init = None
    speed_imp  = None
    if base_ipc and not (math.isnan(base_ipc) or base_ipc == 0):
        if ipc_vals[1]:
            speed_init = ipc_vals[1] / base_ipc
        if ipc_vals[2]:
            speed_imp = ipc_vals[2] / base_ipc

    # plotting setup
    fig, axes = plt.subplots(2,2, figsize=(11,7))
    axes = axes.flatten()
    bar_width = 0.35 
    x_inds = np.arange(2)  

  
    colors = {
        "speedup": "#1f77b4",   # blue
        "l1i":     "#ff7f0e",   # orange
        "l1d":     "#2ca02c",   # green
        "l2":      "#d62728",   # red
    }

  
    ax = axes[0]
    speed_vals_plot = []
    speed_labels = []
    speed_vals = [speed_init, speed_imp]
    speed_labels = [initial_label, improved_label]
  
  
    speed_plot = [v if (v is not None and not (isinstance(v,float) and (math.isnan(v) or math.isinf(v)))) else 0.0 for v in speed_vals]
    bars = ax.bar(x_inds, speed_plot, bar_width, color=colors["speedup"], edgecolor="black")
    ax.set_xticks(x_inds)
    ax.set_xticklabels(speed_labels)
    ax.set_ylabel("Speedup (x)")
    ax.set_title("IPC Speedup vs Baseline")
    ax.grid(axis='y', linestyle=':', alpha=0.5)


    ax.axhline(1.0, color='gray', linestyle='--', linewidth=1.25, label=f"{baseline_label} = 1.0")
    ax.legend()


    for rect, v in zip(bars, speed_vals):
        label = pretty(v)
        h = rect.get_height()
        ax.text(rect.get_x() + rect.get_width()/2., h + 0.01 * max(1.0, h),
                label, ha='center', va='bottom', fontsize=9)



    mpki_sets = [
        ("L1I MPKI", [l1i_vals[0], l1i_vals[1], l1i_vals[2]], colors["l1i"], axes[1]),
        ("L1D MPKI", [l1d_vals[0], l1d_vals[1], l1d_vals[2]], colors["l1d"], axes[2]),
        ("L2 MPKI",  [l2_vals[0],  l2_vals[1],  l2_vals[2] ], colors["l2"],  axes[3]),
    ]
    x3 = np.arange(3)
    for title, vals, color, ax in mpki_sets:
        vals_plot = [v if (v is not None and not (isinstance(v,float) and (math.isnan(v) or math.isinf(v)))) else 0.0 for v in vals]
        bars = ax.bar(x3, vals_plot, bar_width, color=color, edgecolor='black')
        ax.set_xticks(x3)
        ax.set_xticklabels([baseline_label, initial_label, improved_label], rotation=12)
        ax.set_title(title)
        ax.grid(axis='y', linestyle=':', alpha=0.5)


        for rect, v in zip(bars, vals):
            label = pretty(v)
            h = rect.get_height()
            ax.text(rect.get_x() + rect.get_width()/2., h + 0.02 * max(1.0, h),
                    label, ha='center', va='bottom', fontsize=9)

    plt.tight_layout()
    fig.suptitle("m5 speedup and MPKI comparison (Baseline ref)", y=1.02, fontsize=14)
    plt.savefig(out_png, bbox_inches='tight', dpi=200)
    print(f"Saved plot to {out_png}")
    plt.show()


def main():


    default_paths = {
        "baseline":  "checkpoint_2_initial/m5out_baseline/stats.txt",
        "initial":   "checkpoint_2_initial/m5out_prefetch/stats.txt",
        "improved":  "checkpoint_2_improved/m5out_prefetch/stats.txt",
    }



    if len(sys.argv) == 4:
        base_p, init_p, imp_p = sys.argv[1], sys.argv[2], sys.argv[3]
    else:
        base_p = default_paths["baseline"]
        init_p = default_paths["initial"]
        imp_p  = default_paths["improved"]

    print("Using files:")
    print("  Baseline :", base_p)
    print("  Initial  :", init_p)
    print("  Improved :", imp_p)
    print("")

    base_stats = parse_stats(base_p)
    init_stats = parse_stats(init_p)
    imp_stats  = parse_stats(imp_p)

    labels = ["Baseline", "Initial", "Improved"]
    ipc_b, l1i_b, l1d_b, l2_b = extract_metrics(base_stats)
    ipc_i, l1i_i, l1d_i, l2_i = extract_metrics(init_stats) if init_stats else (None, None, None, None)
    ipc_m, l1i_m, l1d_m, l2_m = extract_metrics(imp_stats)  if imp_stats  else (None, None, None, None)

    metrics = {
        "IPC": [ipc_b, ipc_i, ipc_m],
        "L1I": [l1i_b, l1i_i, l1i_m],
        "L1D": [l1d_b, l1d_i, l1d_m],
        "L2":  [l2_b,  l2_i,  l2_m],
    }

    print("Metrics (Baseline / Initial / Improved):")
    def pval(x): return pretty(x)
    print("IPC   :", pval(ipc_b), "/", pval(ipc_i), "/", pval(ipc_m))
    print("L1I   :", pval(l1i_b), "/", pval(l1i_i), "/", pval(l1i_m))
    print("L1D   :", pval(l1d_b), "/", pval(l1d_i), "/", pval(l1d_m))
    print("L2    :", pval(l2_b), "/", pval(l2_i), "/", pval(l2_m))
    print("")

    plot_speedup_and_mpki(labels, metrics)


if __name__ == "__main__":
    main()

