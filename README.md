# TwiceXT — Custom 8-bit RISC Processor

A custom **8-bit load-store RISC processor** designed and implemented in SystemVerilog for CSE 141L. The processor uses a **9-bit instruction format**, a custom instruction set, PC-relative branching, and a modular datapath consisting of a register file, ALU, control decoder, program counter, instruction memory, and data memory.

## Introduction

TwiceXT was designed around a simple load-store philosophy: only `LD` and `STR` instructions access memory, while arithmetic and logic operations operate on registers or immediates. Because the 9-bit instruction format limits the number of bits available for register operands, the ISA uses **strict register conventions** and `MOV` instructions to route values between registers. 

This architecture supports: 
* 8 × 8-bit registers
* Read-only zero register (`R0`)
* Internal 1-bit flag register for carry, shift-out, and comparison results
* 9-bit instructions
* 8-bit data
* PC-relative conditional and unconditional branches
* Direct memory addressing
* Modular SystemVerilog implementation

## Custom ISA

Instructions are divided into three formats:

| Type   | Format                                   | Instructions                                       |
| ------ | ---------------------------------------- | -------------------------------------------------- |
| R-type | `opcode[3] + reg[2] + reg[2] + funct[2]` | `ADD`, `SUB`, `NOT`, `CMP`, `MOVL`, `MOVR`, `ADDC` |
| I-type | `opcode[3] + reg[2] + immediate[4]`      | `LD`, `STR`, `ADDI`, `SH`                          |
| J-type | `opcode[3] + offset[6]`                  | `J`, `BEQ`                                         |

### Register conventions

The ISA intentionally restricts register operands to simplify instruction encoding:

* `R0` is hardwired to `0` and is read-only.
* `R1–R7` are general-purpose registers.
* The first register operand is the destination and must generally be `R4–R7`.
* The second register operand is a source and must generally be `R0–R3`.
* `MOVL` and `MOVR` transfer values between the two register groups.
* The internal flag register stores the result of `CMP`, carry-out/underflow from arithmetic, or the last bit shifted out.

This tradeoff allowed us to support a relatively broad set of ALU operations while fitting the entire ISA into only **9 bits per instruction**.

## Architectural Overview

<img width="860" height="541" alt="Screenshot 2026-08-31 at 12 58 09 AM" src="https://github.com/user-attachments/assets/2bd59364-426e-4410-aaca-e468eca24c08" />

### ALU

The ALU accepts two 8-bit operands and a carry/flag input and supports:

* Addition and subtraction
* Addition with carry
* Immediate addition
* Bitwise NOT and AND
* Register moves
* Comparison
* Logical shifts

The ALU exposes both an 8-bit result and a 1-bit output used to update the processor's internal flag.

### Program Counter

The PC supports sequential execution as well as **signed PC-relative jumps and branches**. With a 6-bit signed offset, branches can reach up to 32 instructions backward or 31 instructions forward.

### Memory

The processor uses separate instruction and data memory.

* Instruction memory stores 9-bit machine instructions.
* Data memory is 8 bits wide with 256 addressable words.
* `LD` and `STR` use direct addressing with a 4-bit immediate address in the ISA.

## Verification

We developed both unit-level and integration-level tests.

The ALU testbench verifies operations including:

* `ADD`
* `SUB`
* `ADDC`
* `NOT`
* `CMP`
* `MOVL` / `MOVR`
* `AND`
* `ADDI`
* `SH`

We also created integration tests covering instruction fetch, register writes, ALU operations, PC updates, and conditional branching.

For example, our integration test exercised a sequence involving:

```asm
NOT  R5, R2
MOVR R5, R2
CMP  R5, R2
BEQ  done
SUB  R7, R3
CMP  R7, R0
BEQ  done
AND  R5, R3
```

The resulting waveforms and processor behavior matched the expected control flow and ALU results.

## Assembler

We also implemented a Python assembler (`assembler.py`) that converts TwiceXT assembly into 9-bit machine code.

Example:

```asm
start:
    CMP  R5, R4
    BEQ  end
    ADDI R4, -1
    J    start

end:
    STR  R4, [16]
```

The assembler handles register operands, immediates, labels, and PC-relative branch offsets.

## Programming the Processor

One of our programs implemented conversion between a **16-bit two's-complement integer representation and a custom 16-bit floating-point representation**.

The implementation involved:

1. Loading the 16-bit integer from memory
2. Extracting the sign bit
3. Computing the two's complement for negative values
4. Normalizing the value through repeated shifts
5. Calculating the exponent
6. Extracting the mantissa
7. Packing the sign, exponent, and mantissa
8. Writing the resulting representation back to memory

We also designed pseudocode for floating-point conversion and floating-point addition, including exponent alignment, mantissa arithmetic, normalization, and result packing.

## Design Tradeoffs

The central design constraint was the **9-bit instruction size**. Larger architectures could encode more registers, larger immediates, and richer addressing modes, but our limited instruction width forced us to make deliberate tradeoffs.

Rather than increasing instruction width, we:

* Restricted register operands to two groups
* Used `MOVL`/`MOVR` to move data between register groups
* Limited memory operations to direct addressing
* Used PC-relative branches
* Maintained a dedicated internal flag
* Relied on register computation to minimize memory accesses

This made the ISA more restrictive for programmers, but allowed us to fit a useful collection of arithmetic, logical, memory, and control-flow operations into a compact 9-bit instruction format.

## Technologies

* **SystemVerilog**
* **Python**
* Digital logic / CPU architecture
* RTL design
* Hardware simulation and verification
* Custom ISA / assembler
* RISC load-store architecture
