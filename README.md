# riscv-chacha20

A lightweight RISC-V processor with custom cryptographic extensions for the ChaCha20 stream cipher, implemented in VHDL and targeting the Xilinx Artix-7 FPGA.

Graduation project, Computer Engineering, King Saud University (CEN 492/493).

## Overview

This project extends a RISC-V processor with custom instructions that accelerate the core operations of ChaCha20 (Add, Rotate, XOR). The goal is to reduce execution cycles compared to a software-only implementation while keeping the hardware area low, which makes the design suitable for IoT and embedded systems.

## Repository Structure

| Folder / File | Description |
|---|---|
| `chacha20_block.vhd` | ChaCha20 block function |
| `chacha20_encrypt.vhd` | ChaCha20 encryption datapath |
| `keccak.c` | Software reference (Keccak) |
| `cha20-test.c` | Software test / baseline for ChaCha20 |
| `timing.xdc` | Timing constraints for the FPGA |

## Tools

- Xilinx Vivado
- XSim (simulation)
- Xilinx Artix-7 FPGA
- VHDL-2008

## How to Run

1. Open the project in Vivado.
2. Run the simulation in XSim using the testbench.
3. Run synthesis and implementation.
4. Program the Artix-7 board.



## License

Academic project. For educational use only.
