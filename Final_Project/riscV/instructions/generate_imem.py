#!/usr/bin/env python3
"""
RISC-V Assembler — Matrix Multiply Benchmark
Generates imem.dat for the RISC-V processor.

Program: Compares ALU-based 4x4 matmul vs Systolic Array matmul.
  - Part 1: Software matmul using shift-and-add multiply (cycle count → dmem[0xC0])
  - Part 2: Systolic Array matmul via MMIO (cycle count → dmem[0xC4])
  - Results: ALU result in dmem[0x80-0xBF], SA result readable at MMIO 0x1080-0x10BF

Matrices:
  A = [[1,2,3,4],[5,6,7,8],[1,0,1,0],[0,1,0,1]]
  B = [[1,0,1,0],[0,1,0,1],[1,0,1,0],[0,1,0,1]]
  Expected C = [[4,6,4,6],[12,14,12,14],[2,0,2,0],[0,2,0,2]]
"""

import os, sys

# ── Register aliases ──
x0=0; x1=1; x5=5; x6=6; x7=7; x8=8; x9=9
x10=10; x11=11; x12=12; x13=13; x14=14; x15=15; x16=16
x28=28; x29=29

# ── Encoding helpers ──
def enc_r(f7, rs2, rs1, f3, rd, op=0x33):
    return (f7<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op

def enc_i(imm, rs1, f3, rd, op):
    return ((imm&0xFFF)<<20)|(rs1<<15)|(f3<<12)|(rd<<7)|op

def enc_s(imm, rs2, rs1, f3=2, op=0x23):
    imm = imm & 0xFFF
    return (((imm>>5)&0x7F)<<25)|(rs2<<20)|(rs1<<15)|(f3<<12)|((imm&0x1F)<<7)|op

def enc_b(imm, rs2, rs1, funct3, op=0x63):
    imm = imm & 0x1FFF
    # imm[12|10:5|4:1|11]
    b12 = (imm >> 12) & 1
    b11 = (imm >> 11) & 1
    b10_5 = (imm >> 5) & 0x3F
    b4_1 = (imm >> 1) & 0xF
    return (b12<<31) | (b10_5<<25) | (rs2<<20) | (rs1<<15) | (funct3<<12) | (b4_1<<8) | (b11<<7) | op

def enc_j(imm, rd, op=0x6F):
    imm = imm & 0x1FFFFF
    # imm[20|10:1|11|19:12]
    j20 = (imm >> 20) & 1
    j19_12 = (imm >> 12) & 0xFF
    j11 = (imm >> 11) & 1
    j10_1 = (imm >> 1) & 0x3FF
    return (j20<<31) | (j10_1<<21) | (j11<<20) | (j19_12<<12) | (rd<<7) | op

def enc_u(imm, rd, op):
    return ((imm&0xFFFFF)<<12)|(rd<<7)|op

# ── Instruction constructors ──
def ADDI(rd,rs1,imm): return enc_i(imm,rs1,0,rd,0x13)
def ANDI(rd,rs1,imm): return enc_i(imm,rs1,7,rd,0x13)
def SLLI(rd,rs1,sh):  return enc_i(sh,rs1,1,rd,0x13)
def SRLI(rd,rs1,sh):  return enc_i(sh,rs1,5,rd,0x13)
def ADD(rd,rs1,rs2):   return enc_r(0,rs2,rs1,0,rd)
def LW(rd,rs1,imm):   return enc_i(imm,rs1,2,rd,0x03)
def SW(rs2,rs1,imm):   return enc_s(imm,rs2,rs1)
def BEQ(rs1,rs2,off):  return enc_b(off,rs2,rs1,0)
def BNE(rs1,rs2,off):  return enc_b(off,rs2,rs1,1)
def BLT(rs1,rs2,off):  return enc_b(off,rs2,rs1,4)
def JAL(rd,off):       return enc_j(off,rd)
def JALR(rd,rs1,imm):  return enc_i(imm,rs1,0,rd,0x67)
def LUI(rd,imm):       return enc_u(imm,rd,0x37)
def NOP():             return ADDI(0,0,0)

# ── Two-pass assembler ──
prog = []   # list of (type, data)
labels = {} # label -> instruction index

def label(name):
    prog.append(('L', name))

def emit(instr_fn, comment=""):
    """Emit a concrete instruction (no label refs)."""
    prog.append(('I', instr_fn, comment))

def emit_branch(br_fn, rs1, rs2, target_label, comment=""):
    """Emit branch with forward/backward label reference."""
    prog.append(('B', br_fn, rs1, rs2, target_label, comment))

def emit_jal(rd, target_label, comment=""):
    """Emit JAL with label reference."""
    prog.append(('J', rd, target_label, comment))

# ══════════════════════════════════════════════════════════
# BUILD THE PROGRAM
# ══════════════════════════════════════════════════════════

# ── Section 1: Initialize Matrix A at dmem[0x00-0x3F] ──
# A = [[1,2,3,4],[5,6,7,8],[1,0,1,0],[0,1,0,1]]
A_vals = [1,2,3,4, 5,6,7,8, 1,0,1,0, 0,1,0,1]
last_val = None
for i, v in enumerate(A_vals):
    if v == 0:
        emit(SW(x0, x0, i*4), f"A[{i//4}][{i%4}] = 0")
    else:
        if v != last_val:
            emit(ADDI(x5, x0, v), f"x5 = {v}")
            last_val = v
        emit(SW(x5, x0, i*4), f"A[{i//4}][{i%4}] = {v}")

# ── Section 2: Initialize Matrix B at dmem[0x40-0x7F] ──
# B = [[1,0,1,0],[0,1,0,1],[1,0,1,0],[0,1,0,1]]
B_vals = [1,0,1,0, 0,1,0,1, 1,0,1,0, 0,1,0,1]
last_val = None
for i, v in enumerate(B_vals):
    if v == 0:
        emit(SW(x0, x0, 0x40 + i*4), f"B[{i//4}][{i%4}] = 0")
    else:
        if v != last_val:
            emit(ADDI(x5, x0, v), f"x5 = {v}")
            last_val = v
        emit(SW(x5, x0, 0x40 + i*4), f"B[{i//4}][{i%4}] = {v}")

# ── Section 3: Software Matmul (ALU) ──
emit(ADDI(x15, x0, 0), "cycle_sw = 0")
emit(ADDI(x12, x0, 0), "i = 0")

label("loop_i")
emit(ADDI(x13, x0, 0), "j = 0")

label("loop_j")
emit(ADDI(x16, x0, 0), "sum = 0")
emit(ADDI(x14, x0, 0), "k = 0")

label("loop_k")
# Compute addr of A[i][k] = (i*4 + k) * 4
emit(SLLI(x5, x12, 2),  "x5 = i*4")
emit(ADD(x5, x5, x14),  "x5 = i*4 + k")
emit(SLLI(x5, x5, 2),   "x5 = (i*4+k)*4")
emit(LW(x8, x5, 0),     "x8 = A[i][k]")
# Compute addr of B[k][j] = 0x40 + (k*4 + j) * 4
emit(SLLI(x6, x14, 2),  "x6 = k*4")
emit(ADD(x6, x6, x13),  "x6 = k*4 + j")
emit(SLLI(x6, x6, 2),   "x6 = (k*4+j)*4")
emit(LW(x9, x6, 0x40),  "x9 = B[k][j]")
# Call multiply subroutine
emit_jal(x1, "multiply", "call multiply")
# Accumulate
emit(ADD(x16, x16, x8), "sum += product")
emit(ADDI(x15, x15, 1), "cycle_sw++")
# k loop
emit(ADDI(x14, x14, 1), "k++")
emit(ADDI(x5, x0, 4),   "x5 = 4")
emit_branch(BLT, x14, x5, "loop_k", "if k<4 goto loop_k")

# Store C_sw[i][j]
emit(SLLI(x5, x12, 2),    "x5 = i*4")
emit(ADD(x5, x5, x13),    "x5 = i*4 + j")
emit(SLLI(x5, x5, 2),     "x5 = (i*4+j)*4")
emit(SW(x16, x5, 0x80),   "C_sw[i][j] = sum")

# j loop
emit(ADDI(x13, x13, 1), "j++")
emit(ADDI(x5, x0, 4),   "x5 = 4")
emit_branch(BLT, x13, x5, "loop_j", "if j<4 goto loop_j")

# i loop
emit(ADDI(x12, x12, 1), "i++")
emit(ADDI(x5, x0, 4),   "x5 = 4")
emit_branch(BLT, x12, x5, "loop_i", "if i<4 goto loop_i")

# Store SW cycle count
emit(SW(x15, x0, 0xC0), "dmem[0xC0] = cycle_sw")

# ── Section 4: Systolic Array Matmul ──
emit(ADDI(x15, x0, 0), "cycle_sa = 0")
# The CPU's LUI instruction is broken (imm_SEL=0 in control_path.v), so we use ADDI + SLLI
emit(ADDI(x10, x0, 1),  "x10 = 1")
emit(SLLI(x10, x10, 12),"x10 = 0x1000 (SA base)")

# Load A into SA buffer (MMIO 0x1000-0x103F)
emit(ADDI(x12, x0, 0), "offset = 0")
label("sa_load_a")
emit(LW(x5, x12, 0),        "x5 = dmem_A[offset]")
emit(ADD(x6, x10, x12),     "x6 = 0x1000 + offset")
emit(SW(x5, x6, 0),         "SA_A[offset] = x5")
emit(ADDI(x15, x15, 1),     "cycle_sa++")
emit(ADDI(x12, x12, 4),     "offset += 4")
emit(ADDI(x5, x0, 64),      "x5 = 64")
emit_branch(BLT, x12, x5, "sa_load_a", "if offset<64 goto sa_load_a")

# Load B into SA buffer (MMIO 0x1040-0x107F)
emit(ADDI(x12, x0, 0), "offset = 0")
label("sa_load_b")
emit(ADDI(x6, x12, 0x40),   "x6 = 0x40 + offset (dmem B addr)")
emit(LW(x5, x6, 0),         "x5 = dmem_B[offset]")
emit(ADDI(x6, x12, 0x40),   "x6 = 0x40 + offset (SA B offset)")
emit(ADD(x6, x10, x6),      "x6 = 0x1040 + offset")
emit(SW(x5, x6, 0),         "SA_B[offset] = x5")
emit(ADDI(x15, x15, 1),     "cycle_sa++")
emit(ADDI(x12, x12, 4),     "offset += 4")
emit(ADDI(x5, x0, 64),      "x5 = 64")
emit_branch(BLT, x12, x5, "sa_load_b", "if offset<64 goto sa_load_b")

# Start SA computation
emit(ADDI(x5, x0, 1),  "x5 = 1")
emit(SW(x5, x10, 0xC0), "SA control = 1 (start)")
emit(ADDI(x15, x15, 1), "cycle_sa++")

# Poll for SA completion
label("sa_poll")
emit(LW(x5, x10, 0xC4),  "x5 = SA status")
emit(ADDI(x15, x15, 1),  "cycle_sa++")
emit_branch(BEQ, x5, x0, "sa_poll", "if !done goto sa_poll")

# Store SA cycle count
emit(SW(x15, x0, 0xC4), "dmem[0xC4] = cycle_sa")

# Halt
label("halt")
emit_branch(BEQ, x0, x0, "halt", "infinite loop")

# ── Multiply subroutine ──
# x8 = x8 * x9 (shift-and-add), clobbers x9, x28, x29
label("multiply")
emit(ADDI(x28, x0, 0),  "result = 0")
label("mul_loop")
emit(ANDI(x29, x9, 1),  "test bit 0 of b")
emit_branch(BEQ, x29, x0, "mul_skip", "if bit=0 skip add")
emit(ADD(x28, x28, x8), "result += a")
label("mul_skip")
emit(SLLI(x8, x8, 1),   "a <<= 1")
emit(SRLI(x9, x9, 1),   "b >>= 1")
emit_branch(BNE, x9, x0, "mul_loop", "while b != 0")
emit(ADDI(x8, x28, 0),  "x8 = result")
emit(JALR(x0, x1, 0),   "return")

# ══════════════════════════════════════════════════════════
# ASSEMBLE: Resolve labels and generate hex
# ══════════════════════════════════════════════════════════

# Pass 1: Assign addresses, collect labels
addr = 0
instr_list = []
for entry in prog:
    if entry[0] == 'L':
        labels[entry[1]] = addr
    else:
        instr_list.append((addr, entry))
        addr += 4

print(f"Program size: {len(instr_list)} instructions ({addr} bytes)")
print(f"Labels: {labels}")

# Pass 2: Resolve labels, encode
hex_words = []
for pc, entry in instr_list:
    if entry[0] == 'I':
        word = entry[1]
        comment = entry[2]
    elif entry[0] == 'B':
        _, br_fn, rs1, rs2, target, comment = entry
        offset = labels[target] - pc
        word = br_fn(rs1, rs2, offset)
    elif entry[0] == 'J':
        _, rd, target, comment = entry
        offset = labels[target] - pc
        word = JAL(rd, offset)
    else:
        raise ValueError(f"Unknown entry type: {entry[0]}")

    hex_words.append((pc, word, comment))

# Write imem.dat
script_dir = os.path.dirname(os.path.abspath(__file__))
out_path = os.path.join(script_dir, "imem.dat")

with open(out_path, 'w') as f:
    idx = 0
    for i in range(256):
        if idx < len(hex_words) and hex_words[idx][0] == i * 4:
            pc, word, comment = hex_words[idx]
            f.write(f"{word:08X}  // [{i:3d}] 0x{pc:03X}: {comment}\n")
            idx += 1
        else:
            f.write(f"00000000  // [{i:3d}] NOP\n")

print(f"Generated: {out_path}")
print(f"Total instructions: {len(hex_words)}, padded to 256 words")

# Print disassembly
print("\n── Disassembly ──")
for pc, word, comment in hex_words:
    print(f"  0x{pc:03X}: {word:08X}  {comment}")
