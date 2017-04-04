//===- HEIISDisassembler.cpp - Disassembler for HEIIS -----------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file is part of the HEIIS Disassembler.
//
//===----------------------------------------------------------------------===//

#include "HEIIS.h"
#include "HEIISRegisterInfo.h"
#include "HEIISSubtarget.h"
#include "llvm/MC/MCDisassembler/MCDisassembler.h"
#include "llvm/MC/MCFixedLenDisassembler.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

#define DEBUG_TYPE "sparc-disassembler"

typedef MCDisassembler::DecodeStatus DecodeStatus;

namespace {

/// A disassembler class for HEIIS.
class HEIISDisassembler : public MCDisassembler {
public:
  HEIISDisassembler(const MCSubtargetInfo &STI, MCContext &Ctx)
      : MCDisassembler(STI, Ctx) {}
  virtual ~HEIISDisassembler() {}

  DecodeStatus getInstruction(MCInst &Instr, uint64_t &Size,
                              ArrayRef<uint8_t> Bytes, uint64_t Address,
                              raw_ostream &VStream,
                              raw_ostream &CStream) const override;
};
}

namespace llvm {
extern Target TheHEIISTarget, TheHEIISV9Target, TheHEIISelTarget;
}

static MCDisassembler *createHEIISDisassembler(const Target &T,
                                               const MCSubtargetInfo &STI,
                                               MCContext &Ctx) {
  return new HEIISDisassembler(STI, Ctx);
}


extern "C" void LLVMInitializeHEIISDisassembler() {
  // Register the disassembler.
  TargetRegistry::RegisterMCDisassembler(TheHEIISTarget,
                                         createHEIISDisassembler);
  TargetRegistry::RegisterMCDisassembler(TheHEIISV9Target,
                                         createHEIISDisassembler);
  TargetRegistry::RegisterMCDisassembler(TheHEIISelTarget,
                                         createHEIISDisassembler);
}

static const unsigned IntRegDecoderTable[] = {
  HE::G0,  HE::G1,  HE::G2,  HE::G3,
  HE::G4,  HE::G5,  HE::G6,  HE::G7,
  HE::O0,  HE::O1,  HE::O2,  HE::O3,
  HE::O4,  HE::O5,  HE::O6,  HE::O7,
  HE::L0,  HE::L1,  HE::L2,  HE::L3,
  HE::L4,  HE::L5,  HE::L6,  HE::L7,
  HE::I0,  HE::I1,  HE::I2,  HE::I3,
  HE::I4,  HE::I5,  HE::I6,  HE::I7 };

static const unsigned FPRegDecoderTable[] = {
  HE::F0,   HE::F1,   HE::F2,   HE::F3,
  HE::F4,   HE::F5,   HE::F6,   HE::F7,
  HE::F8,   HE::F9,   HE::F10,  HE::F11,
  HE::F12,  HE::F13,  HE::F14,  HE::F15,
  HE::F16,  HE::F17,  HE::F18,  HE::F19,
  HE::F20,  HE::F21,  HE::F22,  HE::F23,
  HE::F24,  HE::F25,  HE::F26,  HE::F27,
  HE::F28,  HE::F29,  HE::F30,  HE::F31 };

static const unsigned DFPRegDecoderTable[] = {
  HE::D0,   HE::D16,  HE::D1,   HE::D17,
  HE::D2,   HE::D18,  HE::D3,   HE::D19,
  HE::D4,   HE::D20,  HE::D5,   HE::D21,
  HE::D6,   HE::D22,  HE::D7,   HE::D23,
  HE::D8,   HE::D24,  HE::D9,   HE::D25,
  HE::D10,  HE::D26,  HE::D11,  HE::D27,
  HE::D12,  HE::D28,  HE::D13,  HE::D29,
  HE::D14,  HE::D30,  HE::D15,  HE::D31 };

static const unsigned QFPRegDecoderTable[] = {
  HE::Q0,  HE::Q8,   ~0U,  ~0U,
  HE::Q1,  HE::Q9,   ~0U,  ~0U,
  HE::Q2,  HE::Q10,  ~0U,  ~0U,
  HE::Q3,  HE::Q11,  ~0U,  ~0U,
  HE::Q4,  HE::Q12,  ~0U,  ~0U,
  HE::Q5,  HE::Q13,  ~0U,  ~0U,
  HE::Q6,  HE::Q14,  ~0U,  ~0U,
  HE::Q7,  HE::Q15,  ~0U,  ~0U } ;

static const unsigned FCCRegDecoderTable[] = {
  HE::FCC0, HE::FCC1, HE::FCC2, HE::FCC3 };

static const unsigned ASRRegDecoderTable[] = {
  HE::Y,     HE::ASR1,  HE::ASR2,  HE::ASR3,
  HE::ASR4,  HE::ASR5,  HE::ASR6,  HE::ASR7,
  HE::ASR8,  HE::ASR9,  HE::ASR10, HE::ASR11,
  HE::ASR12, HE::ASR13, HE::ASR14, HE::ASR15,
  HE::ASR16, HE::ASR17, HE::ASR18, HE::ASR19,
  HE::ASR20, HE::ASR21, HE::ASR22, HE::ASR23,
  HE::ASR24, HE::ASR25, HE::ASR26, HE::ASR27,
  HE::ASR28, HE::ASR29, HE::ASR30, HE::ASR31};

static const unsigned PRRegDecoderTable[] = {
  HE::TPC, HE::TNPC, HE::TSTATE, HE::TT, HE::TICK, HE::TBA, HE::PSTATE,
  HE::TL, HE::PIL, HE::CWP, HE::CANSAVE, HE::CANRESTORE, HE::CLEANWIN,
  HE::OTHERWIN, HE::WSTATE
};

static const uint16_t IntPairDecoderTable[] = {
  HE::G0_G1, HE::G2_G3, HE::G4_G5, HE::G6_G7,
  HE::O0_O1, HE::O2_O3, HE::O4_O5, HE::O6_O7,
  HE::L0_L1, HE::L2_L3, HE::L4_L5, HE::L6_L7,
  HE::I0_I1, HE::I2_I3, HE::I4_I5, HE::I6_I7,
};

static const unsigned CPRegDecoderTable[] = {
  HE::C0,  HE::C1,  HE::C2,  HE::C3,
  HE::C4,  HE::C5,  HE::C6,  HE::C7,
  HE::C8,  HE::C9,  HE::C10, HE::C11,
  HE::C12, HE::C13, HE::C14, HE::C15,
  HE::C16, HE::C17, HE::C18, HE::C19,
  HE::C20, HE::C21, HE::C22, HE::C23,
  HE::C24, HE::C25, HE::C26, HE::C27,
  HE::C28, HE::C29, HE::C30, HE::C31
};


static const uint16_t CPPairDecoderTable[] = {
  HE::C0_C1,   HE::C2_C3,   HE::C4_C5,   HE::C6_C7,
  HE::C8_C9,   HE::C10_C11, HE::C12_C13, HE::C14_C15,
  HE::C16_C17, HE::C18_C19, HE::C20_C21, HE::C22_C23,
  HE::C24_C25, HE::C26_C27, HE::C28_C29, HE::C30_C31
};

static DecodeStatus DecodeIntRegsRegisterClass(MCInst &Inst,
                                               unsigned RegNo,
                                               uint64_t Address,
                                               const void *Decoder) {
  if (RegNo > 31)
    return MCDisassembler::Fail;
  unsigned Reg = IntRegDecoderTable[RegNo];
  Inst.addOperand(MCOperand::createReg(Reg));
  return MCDisassembler::Success;
}

static DecodeStatus DecodeI64RegsRegisterClass(MCInst &Inst,
                                               unsigned RegNo,
                                               uint64_t Address,
                                               const void *Decoder) {
  if (RegNo > 31)
    return MCDisassembler::Fail;
  unsigned Reg = IntRegDecoderTable[RegNo];
  Inst.addOperand(MCOperand::createReg(Reg));
  return MCDisassembler::Success;
}


static DecodeStatus DecodeFPRegsRegisterClass(MCInst &Inst,
                                              unsigned RegNo,
                                              uint64_t Address,
                                              const void *Decoder) {
  if (RegNo > 31)
    return MCDisassembler::Fail;
  unsigned Reg = FPRegDecoderTable[RegNo];
  Inst.addOperand(MCOperand::createReg(Reg));
  return MCDisassembler::Success;
}


static DecodeStatus DecodeDFPRegsRegisterClass(MCInst &Inst,
                                               unsigned RegNo,
                                               uint64_t Address,
                                               const void *Decoder) {
  if (RegNo > 31)
    return MCDisassembler::Fail;
  unsigned Reg = DFPRegDecoderTable[RegNo];
  Inst.addOperand(MCOperand::createReg(Reg));
  return MCDisassembler::Success;
}


static DecodeStatus DecodeQFPRegsRegisterClass(MCInst &Inst,
                                               unsigned RegNo,
                                               uint64_t Address,
                                               const void *Decoder) {
  if (RegNo > 31)
    return MCDisassembler::Fail;

  unsigned Reg = QFPRegDecoderTable[RegNo];
  if (Reg == ~0U)
    return MCDisassembler::Fail;
  Inst.addOperand(MCOperand::createReg(Reg));
  return MCDisassembler::Success;
}

static DecodeStatus DecodeCPRegsRegisterClass(MCInst &Inst,
                                               unsigned RegNo,
                                               uint64_t Address,
                                               const void *Decoder) {
  if (RegNo > 31)
    return MCDisassembler::Fail;
  unsigned Reg = CPRegDecoderTable[RegNo];
  Inst.addOperand(MCOperand::createReg(Reg));
  return MCDisassembler::Success;
}

static DecodeStatus DecodeFCCRegsRegisterClass(MCInst &Inst, unsigned RegNo,
                                               uint64_t Address,
                                               const void *Decoder) {
  if (RegNo > 3)
    return MCDisassembler::Fail;
  Inst.addOperand(MCOperand::createReg(FCCRegDecoderTable[RegNo]));
  return MCDisassembler::Success;
}

static DecodeStatus DecodeASRRegsRegisterClass(MCInst &Inst, unsigned RegNo,
                                               uint64_t Address,
                                               const void *Decoder) {
  if (RegNo > 31)
    return MCDisassembler::Fail;
  Inst.addOperand(MCOperand::createReg(ASRRegDecoderTable[RegNo]));
  return MCDisassembler::Success;
}

static DecodeStatus DecodePRRegsRegisterClass(MCInst &Inst, unsigned RegNo,
                                               uint64_t Address,
                                               const void *Decoder) {
  if (RegNo >= array_lengthof(PRRegDecoderTable))
    return MCDisassembler::Fail;
  Inst.addOperand(MCOperand::createReg(PRRegDecoderTable[RegNo]));
  return MCDisassembler::Success;
}

static DecodeStatus DecodeIntPairRegisterClass(MCInst &Inst, unsigned RegNo,
                                   uint64_t Address, const void *Decoder) {
  DecodeStatus S = MCDisassembler::Success;

  if (RegNo > 31)
    return MCDisassembler::Fail;

  if ((RegNo & 1))
    S = MCDisassembler::SoftFail;

  unsigned RegisterPair = IntPairDecoderTable[RegNo/2];
  Inst.addOperand(MCOperand::createReg(RegisterPair));
  return S;
}

static DecodeStatus DecodeCPPairRegisterClass(MCInst &Inst, unsigned RegNo,
                                   uint64_t Address, const void *Decoder) {
  if (RegNo > 31)
    return MCDisassembler::Fail;

  unsigned RegisterPair = CPPairDecoderTable[RegNo/2];
  Inst.addOperand(MCOperand::createReg(RegisterPair));
  return MCDisassembler::Success;
}

static DecodeStatus DecodeLoadInt(MCInst &Inst, unsigned insn, uint64_t Address,
                                  const void *Decoder);
static DecodeStatus DecodeLoadIntPair(MCInst &Inst, unsigned insn, uint64_t Address,
                                  const void *Decoder);
static DecodeStatus DecodeLoadFP(MCInst &Inst, unsigned insn, uint64_t Address,
                                 const void *Decoder);
static DecodeStatus DecodeLoadDFP(MCInst &Inst, unsigned insn, uint64_t Address,
                                  const void *Decoder);
static DecodeStatus DecodeLoadQFP(MCInst &Inst, unsigned insn, uint64_t Address,
                                  const void *Decoder);
static DecodeStatus DecodeLoadCP(MCInst &Inst, unsigned insn, uint64_t Address,
                                  const void *Decoder);
static DecodeStatus DecodeLoadCPPair(MCInst &Inst, unsigned insn, uint64_t Address,
                                  const void *Decoder);
static DecodeStatus DecodeStoreInt(MCInst &Inst, unsigned insn,
                                   uint64_t Address, const void *Decoder);
static DecodeStatus DecodeStoreIntPair(MCInst &Inst, unsigned insn,
                                   uint64_t Address, const void *Decoder);
static DecodeStatus DecodeStoreFP(MCInst &Inst, unsigned insn,
                                  uint64_t Address, const void *Decoder);
static DecodeStatus DecodeStoreDFP(MCInst &Inst, unsigned insn,
                                   uint64_t Address, const void *Decoder);
static DecodeStatus DecodeStoreQFP(MCInst &Inst, unsigned insn,
                                   uint64_t Address, const void *Decoder);
static DecodeStatus DecodeStoreCP(MCInst &Inst, unsigned insn,
                                   uint64_t Address, const void *Decoder);
static DecodeStatus DecodeStoreCPPair(MCInst &Inst, unsigned insn,
                                   uint64_t Address, const void *Decoder);
static DecodeStatus DecodeCall(MCInst &Inst, unsigned insn,
                               uint64_t Address, const void *Decoder);
static DecodeStatus DecodeSIMM13(MCInst &Inst, unsigned insn,
                                 uint64_t Address, const void *Decoder);
static DecodeStatus DecodeJMPL(MCInst &Inst, unsigned insn, uint64_t Address,
                               const void *Decoder);
static DecodeStatus DecodeReturn(MCInst &MI, unsigned insn, uint64_t Address,
                                 const void *Decoder);
static DecodeStatus DecodeSWAP(MCInst &Inst, unsigned insn, uint64_t Address,
                               const void *Decoder);
static DecodeStatus DecodeTRAP(MCInst &Inst, unsigned insn, uint64_t Address,
                               const void *Decoder);

#include "HEIISGenDisassemblerTables.inc"

/// Read four bytes from the ArrayRef and return 32 bit word.
static DecodeStatus readInstruction32(ArrayRef<uint8_t> Bytes, uint64_t Address,
                                      uint64_t &Size, uint32_t &Insn,
                                      bool IsLittleEndian) {
  // We want to read exactly 4 Bytes of data.
  if (Bytes.size() < 4) {
    Size = 0;
    return MCDisassembler::Fail;
  }

  Insn = IsLittleEndian
             ? (Bytes[0] << 0) | (Bytes[1] << 8) | (Bytes[2] << 16) |
                   (Bytes[3] << 24)
             : (Bytes[3] << 0) | (Bytes[2] << 8) | (Bytes[1] << 16) |
                   (Bytes[0] << 24);

  return MCDisassembler::Success;
}

DecodeStatus HEIISDisassembler::getInstruction(MCInst &Instr, uint64_t &Size,
                                               ArrayRef<uint8_t> Bytes,
                                               uint64_t Address,
                                               raw_ostream &VStream,
                                               raw_ostream &CStream) const {
  uint32_t Insn;
  bool isLittleEndian = getContext().getAsmInfo()->isLittleEndian();
  DecodeStatus Result =
      readInstruction32(Bytes, Address, Size, Insn, isLittleEndian);
  if (Result == MCDisassembler::Fail)
    return MCDisassembler::Fail;

  // Calling the auto-generated decoder function.
  
  if (STI.getFeatureBits()[HEIIS::FeatureV9])
  {
    Result = decodeInstruction(DecoderTableHEIISV932, Instr, Insn, Address, this, STI);
  }
  else
  {
    Result = decodeInstruction(DecoderTableHEIISV832, Instr, Insn, Address, this, STI);      
  }
  if (Result != MCDisassembler::Fail)
    return Result;
  
  Result =
      decodeInstruction(DecoderTableHEIIS32, Instr, Insn, Address, this, STI);

  if (Result != MCDisassembler::Fail) {
    Size = 4;
    return Result;
  }

  return MCDisassembler::Fail;
}


typedef DecodeStatus (*DecodeFunc)(MCInst &MI, unsigned insn, uint64_t Address,
                                   const void *Decoder);

static DecodeStatus DecodeMem(MCInst &MI, unsigned insn, uint64_t Address,
                              const void *Decoder,
                              bool isLoad, DecodeFunc DecodeRD) {
  unsigned rd = fieldFromInstruction(insn, 25, 5);
  unsigned rs1 = fieldFromInstruction(insn, 14, 5);
  bool isImm = fieldFromInstruction(insn, 13, 1);
  bool hasAsi = fieldFromInstruction(insn, 23, 1); // (in op3 field)
  unsigned asi = fieldFromInstruction(insn, 5, 8);
  unsigned rs2 = 0;
  unsigned simm13 = 0;
  if (isImm)
    simm13 = SignExtend32<13>(fieldFromInstruction(insn, 0, 13));
  else
    rs2 = fieldFromInstruction(insn, 0, 5);

  DecodeStatus status;
  if (isLoad) {
    status = DecodeRD(MI, rd, Address, Decoder);
    if (status != MCDisassembler::Success)
      return status;
  }

  // Decode rs1.
  status = DecodeIntRegsRegisterClass(MI, rs1, Address, Decoder);
  if (status != MCDisassembler::Success)
    return status;

  // Decode imm|rs2.
  if (isImm)
    MI.addOperand(MCOperand::createImm(simm13));
  else {
    status = DecodeIntRegsRegisterClass(MI, rs2, Address, Decoder);
    if (status != MCDisassembler::Success)
      return status;
  }

  if (hasAsi)
    MI.addOperand(MCOperand::createImm(asi));

  if (!isLoad) {
    status = DecodeRD(MI, rd, Address, Decoder);
    if (status != MCDisassembler::Success)
      return status;
  }
  return MCDisassembler::Success;
}

static DecodeStatus DecodeLoadInt(MCInst &Inst, unsigned insn, uint64_t Address,
                                  const void *Decoder) {
  return DecodeMem(Inst, insn, Address, Decoder, true,
                   DecodeIntRegsRegisterClass);
}

static DecodeStatus DecodeLoadIntPair(MCInst &Inst, unsigned insn, uint64_t Address,
                                  const void *Decoder) {
  return DecodeMem(Inst, insn, Address, Decoder, true,
                   DecodeIntPairRegisterClass);
}

static DecodeStatus DecodeLoadFP(MCInst &Inst, unsigned insn, uint64_t Address,
                                 const void *Decoder) {
  return DecodeMem(Inst, insn, Address, Decoder, true,
                   DecodeFPRegsRegisterClass);
}

static DecodeStatus DecodeLoadDFP(MCInst &Inst, unsigned insn, uint64_t Address,
                                  const void *Decoder) {
  return DecodeMem(Inst, insn, Address, Decoder, true,
                   DecodeDFPRegsRegisterClass);
}

static DecodeStatus DecodeLoadQFP(MCInst &Inst, unsigned insn, uint64_t Address,
                                  const void *Decoder) {
  return DecodeMem(Inst, insn, Address, Decoder, true,
                   DecodeQFPRegsRegisterClass);
}

static DecodeStatus DecodeLoadCP(MCInst &Inst, unsigned insn, uint64_t Address,
                                  const void *Decoder) {
  return DecodeMem(Inst, insn, Address, Decoder, true,
                   DecodeCPRegsRegisterClass);
}

static DecodeStatus DecodeLoadCPPair(MCInst &Inst, unsigned insn, uint64_t Address,
                                  const void *Decoder) {
  return DecodeMem(Inst, insn, Address, Decoder, true,
                   DecodeCPPairRegisterClass);
}

static DecodeStatus DecodeStoreInt(MCInst &Inst, unsigned insn,
                                   uint64_t Address, const void *Decoder) {
  return DecodeMem(Inst, insn, Address, Decoder, false,
                   DecodeIntRegsRegisterClass);
}

static DecodeStatus DecodeStoreIntPair(MCInst &Inst, unsigned insn,
                                   uint64_t Address, const void *Decoder) {
  return DecodeMem(Inst, insn, Address, Decoder, false,
                   DecodeIntPairRegisterClass);
}

static DecodeStatus DecodeStoreFP(MCInst &Inst, unsigned insn, uint64_t Address,
                                  const void *Decoder) {
  return DecodeMem(Inst, insn, Address, Decoder, false,
                   DecodeFPRegsRegisterClass);
}

static DecodeStatus DecodeStoreDFP(MCInst &Inst, unsigned insn,
                                   uint64_t Address, const void *Decoder) {
  return DecodeMem(Inst, insn, Address, Decoder, false,
                   DecodeDFPRegsRegisterClass);
}

static DecodeStatus DecodeStoreQFP(MCInst &Inst, unsigned insn,
                                   uint64_t Address, const void *Decoder) {
  return DecodeMem(Inst, insn, Address, Decoder, false,
                   DecodeQFPRegsRegisterClass);
}

static DecodeStatus DecodeStoreCP(MCInst &Inst, unsigned insn,
                                   uint64_t Address, const void *Decoder) {
  return DecodeMem(Inst, insn, Address, Decoder, false,
                   DecodeCPRegsRegisterClass);
}

static DecodeStatus DecodeStoreCPPair(MCInst &Inst, unsigned insn,
                                   uint64_t Address, const void *Decoder) {
  return DecodeMem(Inst, insn, Address, Decoder, false,
                   DecodeCPPairRegisterClass);
}

static bool tryAddingSymbolicOperand(int64_t Value,  bool isBranch,
                                     uint64_t Address, uint64_t Offset,
                                     uint64_t Width, MCInst &MI,
                                     const void *Decoder) {
  const MCDisassembler *Dis = static_cast<const MCDisassembler*>(Decoder);
  return Dis->tryAddingSymbolicOperand(MI, Value, Address, isBranch,
                                       Offset, Width);
}

static DecodeStatus DecodeCall(MCInst &MI, unsigned insn,
                               uint64_t Address, const void *Decoder) {
  unsigned tgt = fieldFromInstruction(insn, 0, 30);
  tgt <<= 2;
  if (!tryAddingSymbolicOperand(tgt+Address, false, Address,
                                0, 30, MI, Decoder))
    MI.addOperand(MCOperand::createImm(tgt));
  return MCDisassembler::Success;
}

static DecodeStatus DecodeSIMM13(MCInst &MI, unsigned insn,
                                 uint64_t Address, const void *Decoder) {
  unsigned tgt = SignExtend32<13>(fieldFromInstruction(insn, 0, 13));
  MI.addOperand(MCOperand::createImm(tgt));
  return MCDisassembler::Success;
}

static DecodeStatus DecodeJMPL(MCInst &MI, unsigned insn, uint64_t Address,
                               const void *Decoder) {

  unsigned rd = fieldFromInstruction(insn, 25, 5);
  unsigned rs1 = fieldFromInstruction(insn, 14, 5);
  unsigned isImm = fieldFromInstruction(insn, 13, 1);
  unsigned rs2 = 0;
  unsigned simm13 = 0;
  if (isImm)
    simm13 = SignExtend32<13>(fieldFromInstruction(insn, 0, 13));
  else
    rs2 = fieldFromInstruction(insn, 0, 5);

  // Decode RD.
  DecodeStatus status = DecodeIntRegsRegisterClass(MI, rd, Address, Decoder);
  if (status != MCDisassembler::Success)
    return status;

  // Decode RS1.
  status = DecodeIntRegsRegisterClass(MI, rs1, Address, Decoder);
  if (status != MCDisassembler::Success)
    return status;

  // Decode RS1 | SIMM13.
  if (isImm)
    MI.addOperand(MCOperand::createImm(simm13));
  else {
    status = DecodeIntRegsRegisterClass(MI, rs2, Address, Decoder);
    if (status != MCDisassembler::Success)
      return status;
  }
  return MCDisassembler::Success;
}

static DecodeStatus DecodeReturn(MCInst &MI, unsigned insn, uint64_t Address,
                                 const void *Decoder) {

  unsigned rs1 = fieldFromInstruction(insn, 14, 5);
  unsigned isImm = fieldFromInstruction(insn, 13, 1);
  unsigned rs2 = 0;
  unsigned simm13 = 0;
  if (isImm)
    simm13 = SignExtend32<13>(fieldFromInstruction(insn, 0, 13));
  else
    rs2 = fieldFromInstruction(insn, 0, 5);

  // Decode RS1.
  DecodeStatus status = DecodeIntRegsRegisterClass(MI, rs1, Address, Decoder);
  if (status != MCDisassembler::Success)
    return status;

  // Decode RS2 | SIMM13.
  if (isImm)
    MI.addOperand(MCOperand::createImm(simm13));
  else {
    status = DecodeIntRegsRegisterClass(MI, rs2, Address, Decoder);
    if (status != MCDisassembler::Success)
      return status;
  }
  return MCDisassembler::Success;
}

static DecodeStatus DecodeSWAP(MCInst &MI, unsigned insn, uint64_t Address,
                               const void *Decoder) {

  unsigned rd = fieldFromInstruction(insn, 25, 5);
  unsigned rs1 = fieldFromInstruction(insn, 14, 5);
  unsigned isImm = fieldFromInstruction(insn, 13, 1);
  bool hasAsi = fieldFromInstruction(insn, 23, 1); // (in op3 field)
  unsigned asi = fieldFromInstruction(insn, 5, 8);
  unsigned rs2 = 0;
  unsigned simm13 = 0;
  if (isImm)
    simm13 = SignExtend32<13>(fieldFromInstruction(insn, 0, 13));
  else
    rs2 = fieldFromInstruction(insn, 0, 5);

  // Decode RD.
  DecodeStatus status = DecodeIntRegsRegisterClass(MI, rd, Address, Decoder);
  if (status != MCDisassembler::Success)
    return status;

  // Decode RS1.
  status = DecodeIntRegsRegisterClass(MI, rs1, Address, Decoder);
  if (status != MCDisassembler::Success)
    return status;

  // Decode RS1 | SIMM13.
  if (isImm)
    MI.addOperand(MCOperand::createImm(simm13));
  else {
    status = DecodeIntRegsRegisterClass(MI, rs2, Address, Decoder);
    if (status != MCDisassembler::Success)
      return status;
  }

  if (hasAsi)
    MI.addOperand(MCOperand::createImm(asi));

  return MCDisassembler::Success;
}

static DecodeStatus DecodeTRAP(MCInst &MI, unsigned insn, uint64_t Address,
                               const void *Decoder) {

  unsigned rs1 = fieldFromInstruction(insn, 14, 5);
  unsigned isImm = fieldFromInstruction(insn, 13, 1);
  unsigned cc =fieldFromInstruction(insn, 25, 4);
  unsigned rs2 = 0;
  unsigned imm7 = 0;
  if (isImm)
    imm7 = fieldFromInstruction(insn, 0, 7);
  else
    rs2 = fieldFromInstruction(insn, 0, 5);

  // Decode RS1.
  DecodeStatus status = DecodeIntRegsRegisterClass(MI, rs1, Address, Decoder);
  if (status != MCDisassembler::Success)
    return status;

  // Decode RS1 | IMM7.
  if (isImm)
    MI.addOperand(MCOperand::createImm(imm7));
  else {
    status = DecodeIntRegsRegisterClass(MI, rs2, Address, Decoder);
    if (status != MCDisassembler::Success)
      return status;
  }
  
  // Decode CC
  MI.addOperand(MCOperand::createImm(cc));

  return MCDisassembler::Success;
}
