#!/usr/bin/env python3
import re

# Helper: Convert an integer to a two's complement binary string of a given bit-width.
def to_bin(value, bits):
    if value < 0:
        value = (1 << bits) + value
    return format(value, '0{}b'.format(bits))

# Encoding functions for different instruction formats:

# R-type: used by add, sub, and, or.
# Format: [funct7 (7)] [rs2 (5)] [rs1 (5)] [funct3 (3)] [rd (5)] [opcode (7)]
def encode_R_type(op, rd, rs1, rs2):
    # Dictionary: op -> (funct7, funct3)
    r_info = {
        'add': ("0000000", "000"),
        'sub': ("0100000", "000"),
        'and': ("0000000", "111"),
        'or':  ("0000000", "110")
    }
    if op not in r_info:
        raise ValueError("Unsupported R-type op: " + op)
    funct7, funct3 = r_info[op]
    opcode = "0110011"
    return funct7 + to_bin(rs2,5) + to_bin(rs1,5) + funct3 + to_bin(rd,5) + opcode

# I-type for load (ld)
# Format: [imm (12)] [rs1 (5)] [funct3 (3)] [rd (5)] [opcode (7)]
def encode_I_type_ld(rd, rs1, imm):
    opcode = "0000011"
    funct3 = "011"  # ld: funct3=011 (for load doubleword in RV64; here used for ld)
    return to_bin(imm, 12) + to_bin(rs1,5) + funct3 + to_bin(rd,5) + opcode

# S-type for store (sd)
# Format: [imm[11:5] (7)] [rs2 (5)] [rs1 (5)] [funct3 (3)] [imm[4:0] (5)] [opcode (7)]
def encode_S_type_sd(rs2, rs1, imm):
    opcode = "0100011"
    funct3 = "011"  # sd: funct3=011 (store doubleword)
    imm_bin = to_bin(imm, 12)
    imm_high = imm_bin[:7]  # bits 11:5
    imm_low  = imm_bin[7:]  # bits 4:0
    return imm_high + to_bin(rs2,5) + to_bin(rs1,5) + funct3 + imm_low + opcode

# B-type for branch (beq)
# Format: [imm[12] (1)] [imm[10:5] (6)] [rs2 (5)] [rs1 (5)] [funct3 (3)] [imm[4:1] (4)] [imm[11] (1)] [opcode (7)]
def encode_B_type_beq(rs1, rs2, imm):
    opcode = "1100011"
    funct3 = "000"  # beq
    # In RISC-V, the branch immediate is encoded after shifting right by 1.
    # (i.e. the assembly immediate is given as a number of instructions to branch, so we multiply by 2)
    imm = imm * 2
    # For B-type, we need a 13-bit immediate (bit 0 is not encoded)
    imm_bin = to_bin(imm, 13)
    # According to the spec, if we number the bits [12:0] (msb to lsb):
    # - bit12: imm_bin[0]
    # - bits10:5: imm_bin[2:8]  (6 bits)
    # - bits4:1: imm_bin[8:12]  (4 bits)
    # - bit11: imm_bin[1]
    part1 = imm_bin[0]         # imm[12]
    part2 = imm_bin[2:8]       # imm[10:5]
    part3 = to_bin(rs2,5)
    part4 = to_bin(rs1,5)
    part5 = funct3
    part6 = imm_bin[8:12]      # imm[4:1]
    part7 = imm_bin[1]         # imm[11]
    return part1 + part2 + part3 + part4 + part5 + part6 + part7 + opcode

# Parse a single line of assembly and return (op, args)
def parse_line(line):
    # Remove comments and extra whitespace.
    line = line.split('#')[0].strip()
    if not line:
        return None
    # Replace commas with spaces and split.
    tokens = line.replace(',', ' ').split()
    op = tokens[0]
    # Based on op, parse operands.
    if op in ['add', 'sub', 'and', 'or']:
        # R-type: op rd, rs1, rs2
        if len(tokens) != 4:
            raise ValueError("Invalid R-type format: " + line)
        rd = int(tokens[1].lstrip('x'))
        rs1 = int(tokens[2].lstrip('x'))
        rs2 = int(tokens[3].lstrip('x'))
        return (op, rd, rs1, rs2)
    elif op == 'ld':
        # I-type: ld rd, imm(rs1)
        if len(tokens) != 3:
            raise ValueError("Invalid ld format: " + line)
        rd = int(tokens[1].lstrip('x'))
        # Match immediate and register inside parentheses.
        m = re.match(r'(-?\d+)\((x\d+)\)', tokens[2])
        if not m:
            raise ValueError("Invalid ld addressing: " + tokens[2])
        imm = int(m.group(1))
        rs1 = int(m.group(2).lstrip('x'))
        return (op, rd, rs1, imm)
    elif op == 'sd':
        # S-type: sd rs2, imm(rs1)
        if len(tokens) != 3:
            raise ValueError("Invalid sd format: " + line)
        rs2 = int(tokens[1].lstrip('x'))
        m = re.match(r'(-?\d+)\((x\d+)\)', tokens[2])
        if not m:
            raise ValueError("Invalid sd addressing: " + tokens[2])
        imm = int(m.group(1))
        rs1 = int(m.group(2).lstrip('x'))
        return (op, rs2, rs1, imm)
    elif op == 'beq':
        # B-type: beq rs1, rs2, imm
        if len(tokens) != 4:
            raise ValueError("Invalid beq format: " + line)
        rs1 = int(tokens[1].lstrip('x'))
        rs2 = int(tokens[2].lstrip('x'))
        imm = int(tokens[3])
        return (op, rs1, rs2, imm)
    else:
        raise ValueError("Unsupported operation: " + op)

def main():
    binary_instructions = []
    # Read the assembly instructions from assem.s
    with open("assem.s", "r") as fin:
        lines = fin.readlines()
    for line in lines:
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        parsed = parse_line(line)
        if parsed is None:
            continue
        op = parsed[0]
        # Encode based on op type.
        if op in ['add', 'sub', 'and', 'or']:
            _, rd, rs1, rs2 = parsed
            bin_inst = encode_R_type(op, rd, rs1, rs2)
        elif op == 'ld':
            _, rd, rs1, imm = parsed
            bin_inst = encode_I_type_ld(rd, rs1, imm)
        elif op == 'sd':
            _, rs2, rs1, imm = parsed
            bin_inst = encode_S_type_sd(rs2, rs1, imm)
        elif op == 'beq':
            _, rs1, rs2, imm = parsed
            bin_inst = encode_B_type_beq(rs1, rs2, imm)
        else:
            # Should not reach here because we already check op.
            continue
        binary_instructions.append(bin_inst)

    # Fill to 64 instructions if needed.
    total_insts = 64
    fill_inst = "0" * 32
    while len(binary_instructions) < total_insts:
        binary_instructions.append(fill_inst)

    # Write to instruction.txt (one 32-bit binary per line).
    with open("instruction.txt", "w") as fout:
        for inst in binary_instructions:
            fout.write(inst + "\n")

if __name__ == '__main__':
    main()
