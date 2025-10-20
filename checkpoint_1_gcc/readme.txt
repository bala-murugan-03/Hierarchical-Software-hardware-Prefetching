# Function Bundle Analyzer

## Prerequisites

This tool requires the C++ compiler (`g++`) and development libraries for three external dependencies. This guide assumes a Debian/Ubuntu-based Linux environment.

| Dependency | Purpose |
| :--- | :--- |
| **g++/build-essential** | C++ Compiler and Core Build Tools |
| **libelf-dev** | Read and parse ELF file structure (`gelf.h`, `libelf.h`) |
| **libcapstone-dev** | Disassemble machine code and find `CALL` instructions |
| **nlohmann/json** | Header-only library for generating JSON output (`json.hpp`) |

***

## Setup and Installation

Follow these steps to install the required system libraries and set up the JSON header file.

### 1. Install System Dependencies

Run the following commands to install the necessary development packages:

```bash
# Update package lists and install core tools, libelf, and capstone
sudo apt update
sudo apt install -y build-essential libelf-dev libcapstone-dev

## Download nlohmann/json Header

```bash 
wget [https://raw.githubusercontent.com/nlohmann/json/develop/single_include/nlohmann/json.hpp](https://raw.githubusercontent.com/nlohmann/json/develop/single_include/nlohmann/json.hpp) \
    -O lib/nlohmann/json.hpp
