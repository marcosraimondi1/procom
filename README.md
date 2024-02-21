# Real Time Video Processing

## About
This project presents a FPGA architecture for 2D convolution of frames received with Microblaze via ethernet. Frames are streamed with UDP. Communication between Microblaze and the program logic is handled using Axi Stream interface.

## Requirements
- Vivado 2023.1
- Vitis 2023.1

## Build
- clone this repository
- open vivado and source ``` vivado\build.tcl ```
- run synthesis, implementation and generate bitstream
- open hardware manager and program FPGA
- export hardware .xsa including bitstream
- open vitis
- create a platform project using the .xsa
- add lwip32 library in the bsp settings
- configure lwip32 library, in temac options select 100Mbps
- fix status error (delete u32 status) thrown when compiling project
- build project
- create project application
- copy ```src\C\main.c```, ```src\C\udp_echoserver.c``` and ```src\C\udp_echoserver.h```
- create the run configuration
- program fpga

After this steps, the fpga will be listening for frames at port 3001 with ip 172.16.0.236 . Port and ip are configured in the C files.

## Saving Changes
Follow this steps to create a valid .tcl script:
- save custom ips to  ```vivado\ip_repo\{ip_identifier}```
- open the block desing in vivado and run ``` write_bd_tcl design_1.tcl ```, save the generated file in ```vivado\src\bd```.
