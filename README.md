# Hierarchical-Software-hardware-Prefetching


# Checkpoint 1 (Using LLVM):

## Installation of required dependencies:

- **sudo apt install llvm clang libclang-dev llvm-dev** (Used to convert a C file which is similar to server workload to LLVM)
- **sudo apt install graphviz** (Used to convert the dot file into png)
- **sudo apt install nlohmann-json3-dev** (used in callgraph_bundle.cpp)

After the installation of above dependencies, change directory to checkpoint_1_llvm,

**clang -S -emit-llvm server_sim.c -o server_sim.ll**

The above line compiles the given C file into the required LLVM format which can be passed as an argument to callgraph_bundle.cpp

## Compilation of callgraph_bundle.cpp:

**clang++ callgraph_bundle.cpp -o callgraph_bundle \ `llvm-config --cxxflags --ldflags --system-libs --libs core irreader analysis` \ -std=c++17**
  

## Execution of callgraph_bundle with the generated server_sim.ll:

**./callgraph_bundle server_sim.ll**

After the successful execution we get the callgraph.txt and bundles.json (contains only the functions above some fixed threshold)
Then to see the callgraph.png from the generated dot file, the following command is executed, graphviz package is used for this, 

**dot -Tpng callgraph.txt -o callgraph.png**

# Checkpoint 2 

## GEM5 Installation

Before cloning the gem5 repositories there are some dependencies to be installed,

- **sudo apt install -y \ build-essential scons python3-dev python3-six \ python3-setuptools python3-pip git m4 \ libprotobuf-dev protobuf-compiler libgoogle-perftools-dev \ libboost-all-dev pkg-config zlib1g-dev libsqlite3-dev**

- **sudo apt install -y libpng-dev libelf-dev**
- **sudo apt install -y graphviz cmake ninja-build**

Now Clone the following repository using the command,

**git clone https://github.com/gem5/gem5.git**

Then change to gem5 directory and build gem5, we used gem5.fast version,

**scons -j$(nproc) build/X86/gem5.fast**

## Execution of files

### Initial Prefetching Strategy Execution

**clang -O2 -g server_sim_prefetch.c bundle_replay.c -o server_sim_prefetch**

### Baseline and Prefetcher Model Execution on Gem5

- **gem5.fast ~/gem5/configs/deprecated/example/se.py \--cmd=/home/bala/Hierarchical-Software-hardware-Prefetching/checkpoint_2_initial/server_sim \--cpu-type=DerivO3CPU --caches --l2cache \-I 10000000**

- **gem5.fast ~/gem5/configs/deprecated/example/se.py \--cmd=/home/bala/Hierarchical-Software-hardware-Prefetching/checkpoint_2_initial/server_sim_prefetch \--cpu-type=DerivO3CPU --caches --l2cache \-I 10000000**

### Improvised Prefetching Strategy Execution

**clang -O2 -g server_sim_prefetch.c bundle_replay.c -o server_sim_prefetch**

### Baseline and Prefetcher Model Execution on Gem5

- **gem5.fast ~/gem5/configs/deprecated/example/se.py \--cmd=/home/bala/Hierarchical-Software-hardware-Prefetching/checkpoint_2_improved/server_sim \--cpu-type=DerivO3CPU --caches --l2cache \-I 10000000**

- **gem5.fast ~/gem5/configs/deprecated/example/se.py \--cmd=/home/bala/Hierarchical-Software-hardware-Prefetching/checkpoint_2_improved/server_sim_prefetch \--cpu-type=DerivO3CPU --caches --l2cache \-I 10000000**





























    
