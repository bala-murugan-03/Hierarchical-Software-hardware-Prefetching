# Hierarchical-Software-hardware-Prefetching


# Checkpoint 1 (Using LLVM):

## Installation of required dependencies:

sudo apt install llvm clang libclang-dev llvm-dev (Used to convert a C file which is similar to server workload to LLVM)
sudo apt install graphviz (Used to convert the dot file into png)
sudo apt install nlohmann-json3-dev (used in callgraph_bundle.cpp)

After the installation of above dependencies, change directory to checkpoint_1_llvm,

clang -S -emit-llvm server_sim.c -o server_sim.ll

The above line compiles the given C file into the required LLVM format which can be passed as an argument to callgraph_bundle.cpp

## Compilation of callgraph_bundle.cpp:

clang++ callgraph_bundle.cpp -o callgraph_bundle \
  `llvm-config --cxxflags --ldflags --system-libs --libs core irreader analysis` \
  -std=c++17
  

## Execution of callgraph_bundle with the generated server_sim.ll:

./callgraph_bundle server_sim.ll

After the successful execution we get the callgraph.txt and bundles.json (contains only the functions above some fixed threshold)
Then to see the callgraph.png from the generated dot file, the following command is executed, graphviz package is used for this, 

dot -Tpng callgraph.txt -o callgraph.png



