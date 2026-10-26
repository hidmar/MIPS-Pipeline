# Computer Architeccture

# 32-Bit MIPS Processor & 5-Stage Pipelined Architecture

This repository contains hardware description language (VHDL/Verilog) implementations and testbenches for a 32-bit MIPS processor, contrasting both a **Single-Cycle Datapath** and a fully integrated **5-Stage Pipelined Architecture**.

The project models the classic RISC load/store instruction set architecture and demonstrates the hardware mechanisms required to handle structural, data, and control hazards.

---

## Architecture Overview

### 1. Single-Cycle MIPS
In the single-cycle implementation, each instruction executes in a single long clock period. The clock cycle time is bounded by the critical path (typically the `LW` instruction traversing fetch, decode, ALU, data memory, and writeback).

### 2. 5-Stage Pipelined MIPS
The pipelined processor overlaps instruction execution to target an ideal throughput of $\text{CPI} \approx 1$. The datapath is decoupled into 5 synchronous pipeline stages separated by pipeline registers (`IF/ID`, `ID/EX`, `EX/MEM`, `MEM/WB`).

#### Pipeline Stages:
1. **IF (Instruction Fetch):** Fetches the 32-bit instruction from Instruction Memory via the Program Counter ($PC$) and computes $PC + 4$.
2. **ID (Instruction Decode & Register Fetch):** Decodes the opcode and function fields, asserts control signals, reads operands from the 32-entry Register File, and sign-extends the 16-bit immediate.
3. **EX (Execute / Address Calculation):** Executes arithmetic/logic instructions using the ALU or computes base + offset addresses for load/store operations.
4. **MEM (Memory Access):** Reads from or writes to synchronous Data Memory for `LW` and `SW` instructions.
5. **WB (Write Back):** Writes the final ALU result or loaded memory word back into the destination register specified by `rd` or `rt`.

---

## Hazard Handling & Pipeline Control

Pipelining introduces inter-instruction dependencies that are resolved directly in hardware:

* **Data Hazards (RAW - Read After Write):**
  * **Forwarding / Bypassing Unit:** Routes values directly from `EX/MEM` and `MEM/WB` register stages back into the ALU inputs, eliminating stalls for dependent ALU-to-ALU instructions.
  * **Load-Use Hazard Detection Unit:** Detects when an instruction immediately following a `LW` depends on that loaded value. Inserts a hardware stall (1-cycle bubble) and freezes the `PC` and `IF/ID` registers.
* **Control Hazards (Branches & Jumps):**
  * Early branch resolution in the `ID` or `EX` stage.
  * Flushes speculative instructions (`IF/ID` flush) on taken branches (`BEQ`, `BNE`) and jumps (`J`, `JAL`, `JR`).
* **Structural Hazards:** Eliminated via separate Harvard-architecture Instruction and Data memories (or separate L1 caches) and split-phase Register File access (write on clock falling edge / read on rising edge).

---

## Supported Instruction Set

The core supports a fundamental subset of the MIPS32 ISA:

| Type | Instructions | Description |
| :--- | :--- | :--- |
| **R-Type** | `ADD`, `SUB`, `AND`, `OR`, `SLT`, `NOR`, `XOR`, `SLL`, `SRL` | Register arithmetic, logic, and shifts |
| **I-Type (Arithmetic/Logic)** | `ADDI`, `ANDI`, `ORI`, `SLTI` | Immediate arithmetic and logic |
| **I-Type (Memory)** | `LW`, `SW` | Word-aligned base-offset loads and stores |
| **I-Type (Branch)** | `BEQ`, `BNE` | Conditional branches relative to PC |
| **J-Type** | `J`, `JAL`, `JR` | Direct, link, and register jumps |
