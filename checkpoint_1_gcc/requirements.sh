#!/bin/bash

# -----------------------------------------------------------
# SCRIPT TO INSTALL DEPENDENCIES FOR bundle_analyzer.cpp
# Runs on Debian/Ubuntu systems (using apt)
# -----------------------------------------------------------

echo "1. Updating package lists..."
sudo apt update

echo "2. Installing core build tools (g++, make, etc.)..."
sudo apt install -y build-essential

echo "3. Installing libelf development files (for gelf.h, libelf.h)..."
# Provides headers and libraries for reading ELF binaries
sudo apt install -y libelf-dev

echo "4. Installing Capstone disassembler development files (for capstone.h)..."
# Provides headers and libraries for binary disassembly
sudo apt install -y libcapstone-dev

echo "5. Installing nlohmann/json development files..."
# Provides headers for the JSON library
sudo apt install -y nlohmann-json-dev

echo "-----------------------------------------------------------"
echo "✅ All required development libraries installed successfully."
echo "-----------------------------------------------------------"

