bash requirements.sh 

TO download all the required libraries.

wget https://raw.githubusercontent.com/nlohmann/json/develop/single_include/nlohmann/json.hpp

To donwload the nlohmans directory 

Compiling the server based C application

gcc -O0 -g server.c -o server

Compilation of the bundles program

g++ -O0 -g bundle_analyzer.cpp -o bundle_analyzer -lcapstone -lelf -I./lib
