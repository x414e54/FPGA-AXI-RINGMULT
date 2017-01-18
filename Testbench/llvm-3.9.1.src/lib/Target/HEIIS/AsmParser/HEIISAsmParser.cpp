//===-- HEIISAsmParser.cpp - Parse HEIIS assembly to MCInst instructions --===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/HEIISMCExpr.h"
#include "MCTargetDesc/HEIISMCTargetDesc.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCObjectFileInfo.h"
#include "llvm/MC/MCParser/MCParsedAsmOperand.h"
#include "llvm/MC/MCParser/MCTargetAsmParser.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

// The generated AsmMatcher HEIISGenAsmMatcher uses "HEIIS" as the target
// namespace. But SPARC backend uses "SP" as its namespace.
namespace llvm {
  namespace HEIIS {
    using namespace SP;
  }
}

namespace {
class HEIISOperand;
class HEIISAsmParser : public MCTargetAsmParser {

  MCAsmParser &Parser;

  /// @name Auto-generated Match Functions
  /// {

#define GET_ASSEMBLER_HEADER
#include "HEIISGenAsmMatcher.inc"

  /// }

  // public interface of the MCTargetAsmParser.
  bool MatchAndEmitInstruction(SMLoc IDLoc, unsigned &Opcode,
                               OperandVector &Operands, MCStreamer &Out,
                               uint64_t &ErrorInfo,
                               bool MatchingInlineAsm) override;
  bool ParseRegister(unsigned &RegNo, SMLoc &StartLoc, SMLoc &EndLoc) override;
  bool ParseInstruction(ParseInstructionInfo &Info, StringRef Name,
                        SMLoc NameLoc, OperandVector &Operands) override;
  bool ParseDirective(AsmToken DirectiveID) override;

  unsigned validateTargetOperandClass(MCParsedAsmOperand &Op,
                                      unsigned Kind) override;

  // Custom parse functions for HEIIS specific operands.
  OperandMatchResultTy parseMEMOperand(OperandVector &Operands);

  OperandMatchResultTy parseOperand(OperandVector &Operands, StringRef Name);

  OperandMatchResultTy
  parseHEIISAsmOperand(std::unique_ptr<HEIISOperand> &Operand,
                       bool isCall = false);

  OperandMatchResultTy parseBranchModifiers(OperandVector &Operands);

  // Helper function for dealing with %lo / %hi in PIC mode.
  const HEIISMCExpr *adjustPICRelocation(HEIISMCExpr::VariantKind VK,
                                         const MCExpr *subExpr);

  // returns true if Tok is matched to a register and returns register in RegNo.
  bool matchRegisterName(const AsmToken &Tok, unsigned &RegNo,
                         unsigned &RegKind);

  bool matchHEIISAsmModifiers(const MCExpr *&EVal, SMLoc &EndLoc);
  bool parseDirectiveWord(unsigned Size, SMLoc L);

  bool is64Bit() const {
    return getSTI().getTargetTriple().getArch() == Triple::sparcv9;
  }

  void expandSET(MCInst &Inst, SMLoc IDLoc,
                 SmallVectorImpl<MCInst> &Instructions);

public:
  HEIISAsmParser(const MCSubtargetInfo &sti, MCAsmParser &parser,
                const MCInstrInfo &MII,
                const MCTargetOptions &Options)
      : MCTargetAsmParser(Options, sti), Parser(parser) {
    // Initialize the set of available features.
    setAvailableFeatures(ComputeAvailableFeatures(getSTI().getFeatureBits()));
  }

};

  static const MCPhysReg IntRegs[32] = {
    HEIIS::G0, HEIIS::G1, HEIIS::G2, HEIIS::G3,
    HEIIS::G4, HEIIS::G5, HEIIS::G6, HEIIS::G7,
    HEIIS::O0, HEIIS::O1, HEIIS::O2, HEIIS::O3,
    HEIIS::O4, HEIIS::O5, HEIIS::O6, HEIIS::O7,
    HEIIS::L0, HEIIS::L1, HEIIS::L2, HEIIS::L3,
    HEIIS::L4, HEIIS::L5, HEIIS::L6, HEIIS::L7,
    HEIIS::I0, HEIIS::I1, HEIIS::I2, HEIIS::I3,
    HEIIS::I4, HEIIS::I5, HEIIS::I6, HEIIS::I7 };

  static const MCPhysReg FloatRegs[32] = {
    HEIIS::F0,  HEIIS::F1,  HEIIS::F2,  HEIIS::F3,
    HEIIS::F4,  HEIIS::F5,  HEIIS::F6,  HEIIS::F7,
    HEIIS::F8,  HEIIS::F9,  HEIIS::F10, HEIIS::F11,
    HEIIS::F12, HEIIS::F13, HEIIS::F14, HEIIS::F15,
    HEIIS::F16, HEIIS::F17, HEIIS::F18, HEIIS::F19,
    HEIIS::F20, HEIIS::F21, HEIIS::F22, HEIIS::F23,
    HEIIS::F24, HEIIS::F25, HEIIS::F26, HEIIS::F27,
    HEIIS::F28, HEIIS::F29, HEIIS::F30, HEIIS::F31 };

  static const MCPhysReg DoubleRegs[32] = {
    HEIIS::D0,  HEIIS::D1,  HEIIS::D2,  HEIIS::D3,
    HEIIS::D4,  HEIIS::D5,  HEIIS::D6,  HEIIS::D7,
    HEIIS::D8,  HEIIS::D7,  HEIIS::D8,  HEIIS::D9,
    HEIIS::D12, HEIIS::D13, HEIIS::D14, HEIIS::D15,
    HEIIS::D16, HEIIS::D17, HEIIS::D18, HEIIS::D19,
    HEIIS::D20, HEIIS::D21, HEIIS::D22, HEIIS::D23,
    HEIIS::D24, HEIIS::D25, HEIIS::D26, HEIIS::D27,
    HEIIS::D28, HEIIS::D29, HEIIS::D30, HEIIS::D31 };

  static const MCPhysReg QuadFPRegs[32] = {
    HEIIS::Q0,  HEIIS::Q1,  HEIIS::Q2,  HEIIS::Q3,
    HEIIS::Q4,  HEIIS::Q5,  HEIIS::Q6,  HEIIS::Q7,
    HEIIS::Q8,  HEIIS::Q9,  HEIIS::Q10, HEIIS::Q11,
    HEIIS::Q12, HEIIS::Q13, HEIIS::Q14, HEIIS::Q15 };

  static const MCPhysReg ASRRegs[32] = {
    SP::Y,     SP::ASR1,  SP::ASR2,  SP::ASR3,
    SP::ASR4,  SP::ASR5,  SP::ASR6, SP::ASR7,
    SP::ASR8,  SP::ASR9,  SP::ASR10, SP::ASR11,
    SP::ASR12, SP::ASR13, SP::ASR14, SP::ASR15,
    SP::ASR16, SP::ASR17, SP::ASR18, SP::ASR19,
    SP::ASR20, SP::ASR21, SP::ASR22, SP::ASR23,
    SP::ASR24, SP::ASR25, SP::ASR26, SP::ASR27,
    SP::ASR28, SP::ASR29, SP::ASR30, SP::ASR31};

  static const MCPhysReg IntPairRegs[] = {
    HEIIS::G0_G1, HEIIS::G2_G3, HEIIS::G4_G5, HEIIS::G6_G7,
    HEIIS::O0_O1, HEIIS::O2_O3, HEIIS::O4_O5, HEIIS::O6_O7,
    HEIIS::L0_L1, HEIIS::L2_L3, HEIIS::L4_L5, HEIIS::L6_L7,
    HEIIS::I0_I1, HEIIS::I2_I3, HEIIS::I4_I5, HEIIS::I6_I7};

  static const MCPhysReg CoprocRegs[32] = {
    HEIIS::C0,  HEIIS::C1,  HEIIS::C2,  HEIIS::C3,
    HEIIS::C4,  HEIIS::C5,  HEIIS::C6,  HEIIS::C7,
    HEIIS::C8,  HEIIS::C9,  HEIIS::C10, HEIIS::C11,
    HEIIS::C12, HEIIS::C13, HEIIS::C14, HEIIS::C15,
    HEIIS::C16, HEIIS::C17, HEIIS::C18, HEIIS::C19,
    HEIIS::C20, HEIIS::C21, HEIIS::C22, HEIIS::C23,
    HEIIS::C24, HEIIS::C25, HEIIS::C26, HEIIS::C27,
    HEIIS::C28, HEIIS::C29, HEIIS::C30, HEIIS::C31 };

  static const MCPhysReg CoprocPairRegs[] = {
    HEIIS::C0_C1,   HEIIS::C2_C3,   HEIIS::C4_C5,   HEIIS::C6_C7,
    HEIIS::C8_C9,   HEIIS::C10_C11, HEIIS::C12_C13, HEIIS::C14_C15,
    HEIIS::C16_C17, HEIIS::C18_C19, HEIIS::C20_C21, HEIIS::C22_C23,
    HEIIS::C24_C25, HEIIS::C26_C27, HEIIS::C28_C29, HEIIS::C30_C31};
  
/// HEIISOperand - Instances of this class represent a parsed HEIIS machine
/// instruction.
class HEIISOperand : public MCParsedAsmOperand {
public:
  enum RegisterKind {
    rk_None,
    rk_IntReg,
    rk_IntPairReg,
    rk_FloatReg,
    rk_DoubleReg,
    rk_QuadReg,
    rk_CoprocReg,
    rk_CoprocPairReg,
    rk_Special,
  };

private:
  enum KindTy {
    k_Token,
    k_Register,
    k_Immediate,
    k_MemoryReg,
    k_MemoryImm
  } Kind;

  SMLoc StartLoc, EndLoc;

  struct Token {
    const char *Data;
    unsigned Length;
  };

  struct RegOp {
    unsigned RegNum;
    RegisterKind Kind;
  };

  struct ImmOp {
    const MCExpr *Val;
  };

  struct MemOp {
    unsigned Base;
    unsigned OffsetReg;
    const MCExpr *Off;
  };

  union {
    struct Token Tok;
    struct RegOp Reg;
    struct ImmOp Imm;
    struct MemOp Mem;
  };
public:
  HEIISOperand(KindTy K) : MCParsedAsmOperand(), Kind(K) {}

  bool isToken() const override { return Kind == k_Token; }
  bool isReg() const override { return Kind == k_Register; }
  bool isImm() const override { return Kind == k_Immediate; }
  bool isMem() const override { return isMEMrr() || isMEMri(); }
  bool isMEMrr() const { return Kind == k_MemoryReg; }
  bool isMEMri() const { return Kind == k_MemoryImm; }

  bool isIntReg() const {
    return (Kind == k_Register && Reg.Kind == rk_IntReg);
  }

  bool isFloatReg() const {
    return (Kind == k_Register && Reg.Kind == rk_FloatReg);
  }

  bool isFloatOrDoubleReg() const {
    return (Kind == k_Register && (Reg.Kind == rk_FloatReg
                                   || Reg.Kind == rk_DoubleReg));
  }

  bool isCoprocReg() const {
    return (Kind == k_Register && Reg.Kind == rk_CoprocReg);
  }

  StringRef getToken() const {
    assert(Kind == k_Token && "Invalid access!");
    return StringRef(Tok.Data, Tok.Length);
  }

  unsigned getReg() const override {
    assert((Kind == k_Register) && "Invalid access!");
    return Reg.RegNum;
  }

  const MCExpr *getImm() const {
    assert((Kind == k_Immediate) && "Invalid access!");
    return Imm.Val;
  }

  unsigned getMemBase() const {
    assert((Kind == k_MemoryReg || Kind == k_MemoryImm) && "Invalid access!");
    return Mem.Base;
  }

  unsigned getMemOffsetReg() const {
    assert((Kind == k_MemoryReg) && "Invalid access!");
    return Mem.OffsetReg;
  }

  const MCExpr *getMemOff() const {
    assert((Kind == k_MemoryImm) && "Invalid access!");
    return Mem.Off;
  }

  /// getStartLoc - Get the location of the first token of this operand.
  SMLoc getStartLoc() const override {
    return StartLoc;
  }
  /// getEndLoc - Get the location of the last token of this operand.
  SMLoc getEndLoc() const override {
    return EndLoc;
  }

  void print(raw_ostream &OS) const override {
    switch (Kind) {
    case k_Token:     OS << "Token: " << getToken() << "\n"; break;
    case k_Register:  OS << "Reg: #" << getReg() << "\n"; break;
    case k_Immediate: OS << "Imm: " << getImm() << "\n"; break;
    case k_MemoryReg: OS << "Mem: " << getMemBase() << "+"
                         << getMemOffsetReg() << "\n"; break;
    case k_MemoryImm: assert(getMemOff() != nullptr);
      OS << "Mem: " << getMemBase()
         << "+" << *getMemOff()
         << "\n"; break;
    }
  }

  void addRegOperands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    Inst.addOperand(MCOperand::createReg(getReg()));
  }

  void addImmOperands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    const MCExpr *Expr = getImm();
    addExpr(Inst, Expr);
  }

  void addExpr(MCInst &Inst, const MCExpr *Expr) const{
    // Add as immediate when possible.  Null MCExpr = 0.
    if (!Expr)
      Inst.addOperand(MCOperand::createImm(0));
    else if (const MCConstantExpr *CE = dyn_cast<MCConstantExpr>(Expr))
      Inst.addOperand(MCOperand::createImm(CE->getValue()));
    else
      Inst.addOperand(MCOperand::createExpr(Expr));
  }

  void addMEMrrOperands(MCInst &Inst, unsigned N) const {
    assert(N == 2 && "Invalid number of operands!");

    Inst.addOperand(MCOperand::createReg(getMemBase()));

    assert(getMemOffsetReg() != 0 && "Invalid offset");
    Inst.addOperand(MCOperand::createReg(getMemOffsetReg()));
  }

  void addMEMriOperands(MCInst &Inst, unsigned N) const {
    assert(N == 2 && "Invalid number of operands!");

    Inst.addOperand(MCOperand::createReg(getMemBase()));

    const MCExpr *Expr = getMemOff();
    addExpr(Inst, Expr);
  }

  static std::unique_ptr<HEIISOperand> CreateToken(StringRef Str, SMLoc S) {
    auto Op = make_unique<HEIISOperand>(k_Token);
    Op->Tok.Data = Str.data();
    Op->Tok.Length = Str.size();
    Op->StartLoc = S;
    Op->EndLoc = S;
    return Op;
  }

  static std::unique_ptr<HEIISOperand> CreateReg(unsigned RegNum, unsigned Kind,
                                                 SMLoc S, SMLoc E) {
    auto Op = make_unique<HEIISOperand>(k_Register);
    Op->Reg.RegNum = RegNum;
    Op->Reg.Kind   = (HEIISOperand::RegisterKind)Kind;
    Op->StartLoc = S;
    Op->EndLoc = E;
    return Op;
  }

  static std::unique_ptr<HEIISOperand> CreateImm(const MCExpr *Val, SMLoc S,
                                                 SMLoc E) {
    auto Op = make_unique<HEIISOperand>(k_Immediate);
    Op->Imm.Val = Val;
    Op->StartLoc = S;
    Op->EndLoc = E;
    return Op;
  }

  static bool MorphToIntPairReg(HEIISOperand &Op) {
    unsigned Reg = Op.getReg();
    assert(Op.Reg.Kind == rk_IntReg);
    unsigned regIdx = 32;
    if (Reg >= HEIIS::G0 && Reg <= HEIIS::G7)
      regIdx = Reg - HEIIS::G0;
    else if (Reg >= HEIIS::O0 && Reg <= HEIIS::O7)
      regIdx = Reg - HEIIS::O0 + 8;
    else if (Reg >= HEIIS::L0 && Reg <= HEIIS::L7)
      regIdx = Reg - HEIIS::L0 + 16;
    else if (Reg >= HEIIS::I0 && Reg <= HEIIS::I7)
      regIdx = Reg - HEIIS::I0 + 24;
    if (regIdx % 2 || regIdx > 31)
      return false;
    Op.Reg.RegNum = IntPairRegs[regIdx / 2];
    Op.Reg.Kind = rk_IntPairReg;
    return true;
  }

  static bool MorphToDoubleReg(HEIISOperand &Op) {
    unsigned Reg = Op.getReg();
    assert(Op.Reg.Kind == rk_FloatReg);
    unsigned regIdx = Reg - HEIIS::F0;
    if (regIdx % 2 || regIdx > 31)
      return false;
    Op.Reg.RegNum = DoubleRegs[regIdx / 2];
    Op.Reg.Kind = rk_DoubleReg;
    return true;
  }

  static bool MorphToQuadReg(HEIISOperand &Op) {
    unsigned Reg = Op.getReg();
    unsigned regIdx = 0;
    switch (Op.Reg.Kind) {
    default: llvm_unreachable("Unexpected register kind!");
    case rk_FloatReg:
      regIdx = Reg - HEIIS::F0;
      if (regIdx % 4 || regIdx > 31)
        return false;
      Reg = QuadFPRegs[regIdx / 4];
      break;
    case rk_DoubleReg:
      regIdx =  Reg - HEIIS::D0;
      if (regIdx % 2 || regIdx > 31)
        return false;
      Reg = QuadFPRegs[regIdx / 2];
      break;
    }
    Op.Reg.RegNum = Reg;
    Op.Reg.Kind = rk_QuadReg;
    return true;
  }

  static bool MorphToCoprocPairReg(HEIISOperand &Op) {
    unsigned Reg = Op.getReg();
    assert(Op.Reg.Kind == rk_CoprocReg);
    unsigned regIdx = 32;
    if (Reg >= HEIIS::C0 && Reg <= HEIIS::C31)
      regIdx = Reg - HEIIS::C0;
    if (regIdx % 2 || regIdx > 31)
      return false;
    Op.Reg.RegNum = CoprocPairRegs[regIdx / 2];
    Op.Reg.Kind = rk_CoprocPairReg;
    return true;
  }
  
  static std::unique_ptr<HEIISOperand>
  MorphToMEMrr(unsigned Base, std::unique_ptr<HEIISOperand> Op) {
    unsigned offsetReg = Op->getReg();
    Op->Kind = k_MemoryReg;
    Op->Mem.Base = Base;
    Op->Mem.OffsetReg = offsetReg;
    Op->Mem.Off = nullptr;
    return Op;
  }

  static std::unique_ptr<HEIISOperand>
  CreateMEMr(unsigned Base, SMLoc S, SMLoc E) {
    auto Op = make_unique<HEIISOperand>(k_MemoryReg);
    Op->Mem.Base = Base;
    Op->Mem.OffsetReg = HEIIS::G0;  // always 0
    Op->Mem.Off = nullptr;
    Op->StartLoc = S;
    Op->EndLoc = E;
    return Op;
  }

  static std::unique_ptr<HEIISOperand>
  MorphToMEMri(unsigned Base, std::unique_ptr<HEIISOperand> Op) {
    const MCExpr *Imm  = Op->getImm();
    Op->Kind = k_MemoryImm;
    Op->Mem.Base = Base;
    Op->Mem.OffsetReg = 0;
    Op->Mem.Off = Imm;
    return Op;
  }
};

} // end namespace

void HEIISAsmParser::expandSET(MCInst &Inst, SMLoc IDLoc,
                               SmallVectorImpl<MCInst> &Instructions) {
  MCOperand MCRegOp = Inst.getOperand(0);
  MCOperand MCValOp = Inst.getOperand(1);
  assert(MCRegOp.isReg());
  assert(MCValOp.isImm() || MCValOp.isExpr());

  // the imm operand can be either an expression or an immediate.
  bool IsImm = Inst.getOperand(1).isImm();
  int64_t RawImmValue = IsImm ? MCValOp.getImm() : 0;

  // Allow either a signed or unsigned 32-bit immediate.
  if (RawImmValue < -2147483648LL || RawImmValue > 4294967295LL) {
    Error(IDLoc, "set: argument must be between -2147483648 and 4294967295");
    return;
  }

  // If the value was expressed as a large unsigned number, that's ok.
  // We want to see if it "looks like" a small signed number.
  int32_t ImmValue = RawImmValue;
  // For 'set' you can't use 'or' with a negative operand on V9 because
  // that would splat the sign bit across the upper half of the destination
  // register, whereas 'set' is defined to zero the high 32 bits.
  bool IsEffectivelyImm13 =
      IsImm && ((is64Bit() ? 0 : -4096) <= ImmValue && ImmValue < 4096);
  const MCExpr *ValExpr;
  if (IsImm)
    ValExpr = MCConstantExpr::create(ImmValue, getContext());
  else
    ValExpr = MCValOp.getExpr();

  MCOperand PrevReg = MCOperand::createReg(HEIIS::G0);

  // If not just a signed imm13 value, then either we use a 'sethi' with a
  // following 'or', or a 'sethi' by itself if there are no more 1 bits.
  // In either case, start with the 'sethi'.
  if (!IsEffectivelyImm13) {
    MCInst TmpInst;
    const MCExpr *Expr = adjustPICRelocation(HEIISMCExpr::VK_HEIIS_HI, ValExpr);
    TmpInst.setLoc(IDLoc);
    TmpInst.setOpcode(SP::SETHIi);
    TmpInst.addOperand(MCRegOp);
    TmpInst.addOperand(MCOperand::createExpr(Expr));
    Instructions.push_back(TmpInst);
    PrevReg = MCRegOp;
  }

  // The low bits require touching in 3 cases:
  // * A non-immediate value will always require both instructions.
  // * An effectively imm13 value needs only an 'or' instruction.
  // * Otherwise, an immediate that is not effectively imm13 requires the
  //   'or' only if bits remain after clearing the 22 bits that 'sethi' set.
  // If the low bits are known zeros, there's nothing to do.
  // In the second case, and only in that case, must we NOT clear
  // bits of the immediate value via the %lo() assembler function.
  // Note also, the 'or' instruction doesn't mind a large value in the case
  // where the operand to 'set' was 0xFFFFFzzz - it does exactly what you mean.
  if (!IsImm || IsEffectivelyImm13 || (ImmValue & 0x3ff)) {
    MCInst TmpInst;
    const MCExpr *Expr;
    if (IsEffectivelyImm13)
      Expr = ValExpr;
    else
      Expr = adjustPICRelocation(HEIISMCExpr::VK_HEIIS_LO, ValExpr);
    TmpInst.setLoc(IDLoc);
    TmpInst.setOpcode(SP::ORri);
    TmpInst.addOperand(MCRegOp);
    TmpInst.addOperand(PrevReg);
    TmpInst.addOperand(MCOperand::createExpr(Expr));
    Instructions.push_back(TmpInst);
  }
}

bool HEIISAsmParser::MatchAndEmitInstruction(SMLoc IDLoc, unsigned &Opcode,
                                             OperandVector &Operands,
                                             MCStreamer &Out,
                                             uint64_t &ErrorInfo,
                                             bool MatchingInlineAsm) {
  MCInst Inst;
  SmallVector<MCInst, 8> Instructions;
  unsigned MatchResult = MatchInstructionImpl(Operands, Inst, ErrorInfo,
                                              MatchingInlineAsm);
  switch (MatchResult) {
  case Match_Success: {
    switch (Inst.getOpcode()) {
    default:
      Inst.setLoc(IDLoc);
      Instructions.push_back(Inst);
      break;
    case SP::SET:
      expandSET(Inst, IDLoc, Instructions);
      break;
    }

    for (const MCInst &I : Instructions) {
      Out.EmitInstruction(I, getSTI());
    }
    return false;
  }

  case Match_MissingFeature:
    return Error(IDLoc,
                 "instruction requires a CPU feature not currently enabled");

  case Match_InvalidOperand: {
    SMLoc ErrorLoc = IDLoc;
    if (ErrorInfo != ~0ULL) {
      if (ErrorInfo >= Operands.size())
        return Error(IDLoc, "too few operands for instruction");

      ErrorLoc = ((HEIISOperand &)*Operands[ErrorInfo]).getStartLoc();
      if (ErrorLoc == SMLoc())
        ErrorLoc = IDLoc;
    }

    return Error(ErrorLoc, "invalid operand for instruction");
  }
  case Match_MnemonicFail:
    return Error(IDLoc, "invalid instruction mnemonic");
  }
  llvm_unreachable("Implement any new match types added!");
}

bool HEIISAsmParser::
ParseRegister(unsigned &RegNo, SMLoc &StartLoc, SMLoc &EndLoc)
{
  const AsmToken &Tok = Parser.getTok();
  StartLoc = Tok.getLoc();
  EndLoc = Tok.getEndLoc();
  RegNo = 0;
  if (getLexer().getKind() != AsmToken::Percent)
    return false;
  Parser.Lex();
  unsigned regKind = HEIISOperand::rk_None;
  if (matchRegisterName(Tok, RegNo, regKind)) {
    Parser.Lex();
    return false;
  }

  return Error(StartLoc, "invalid register name");
}

static void applyMnemonicAliases(StringRef &Mnemonic, uint64_t Features,
                                 unsigned VariantID);

bool HEIISAsmParser::ParseInstruction(ParseInstructionInfo &Info,
                                      StringRef Name, SMLoc NameLoc,
                                      OperandVector &Operands) {

  // First operand in MCInst is instruction mnemonic.
  Operands.push_back(HEIISOperand::CreateToken(Name, NameLoc));

  // apply mnemonic aliases, if any, so that we can parse operands correctly.
  applyMnemonicAliases(Name, getAvailableFeatures(), 0);

  if (getLexer().isNot(AsmToken::EndOfStatement)) {
    // Read the first operand.
    if (getLexer().is(AsmToken::Comma)) {
      if (parseBranchModifiers(Operands) != MatchOperand_Success) {
        SMLoc Loc = getLexer().getLoc();
        Parser.eatToEndOfStatement();
        return Error(Loc, "unexpected token");
      }
    }
    if (parseOperand(Operands, Name) != MatchOperand_Success) {
      SMLoc Loc = getLexer().getLoc();
      Parser.eatToEndOfStatement();
      return Error(Loc, "unexpected token");
    }

    while (getLexer().is(AsmToken::Comma) || getLexer().is(AsmToken::Plus)) {
      if (getLexer().is(AsmToken::Plus)) {
      // Plus tokens are significant in software_traps (p83, sparcv8.pdf). We must capture them.
        Operands.push_back(HEIISOperand::CreateToken("+", Parser.getTok().getLoc()));
      }
      Parser.Lex(); // Eat the comma or plus.
      // Parse and remember the operand.
      if (parseOperand(Operands, Name) != MatchOperand_Success) {
        SMLoc Loc = getLexer().getLoc();
        Parser.eatToEndOfStatement();
        return Error(Loc, "unexpected token");
      }
    }
  }
  if (getLexer().isNot(AsmToken::EndOfStatement)) {
    SMLoc Loc = getLexer().getLoc();
    Parser.eatToEndOfStatement();
    return Error(Loc, "unexpected token");
  }
  Parser.Lex(); // Consume the EndOfStatement.
  return false;
}

bool HEIISAsmParser::
ParseDirective(AsmToken DirectiveID)
{
  StringRef IDVal = DirectiveID.getString();

  if (IDVal == ".byte")
    return parseDirectiveWord(1, DirectiveID.getLoc());

  if (IDVal == ".half")
    return parseDirectiveWord(2, DirectiveID.getLoc());

  if (IDVal == ".word")
    return parseDirectiveWord(4, DirectiveID.getLoc());

  if (IDVal == ".nword")
    return parseDirectiveWord(is64Bit() ? 8 : 4, DirectiveID.getLoc());

  if (is64Bit() && IDVal == ".xword")
    return parseDirectiveWord(8, DirectiveID.getLoc());

  if (IDVal == ".register") {
    // For now, ignore .register directive.
    Parser.eatToEndOfStatement();
    return false;
  }
  if (IDVal == ".proc") {
    // For compatibility, ignore this directive.
    // (It's supposed to be an "optimization" in the Sun assembler)
    Parser.eatToEndOfStatement();
    return false;
  }

  // Let the MC layer to handle other directives.
  return true;
}

bool HEIISAsmParser:: parseDirectiveWord(unsigned Size, SMLoc L) {
  if (getLexer().isNot(AsmToken::EndOfStatement)) {
    for (;;) {
      const MCExpr *Value;
      if (getParser().parseExpression(Value))
        return true;

      getParser().getStreamer().EmitValue(Value, Size);

      if (getLexer().is(AsmToken::EndOfStatement))
        break;

      // FIXME: Improve diagnostic.
      if (getLexer().isNot(AsmToken::Comma))
        return Error(L, "unexpected token in directive");
      Parser.Lex();
    }
  }
  Parser.Lex();
  return false;
}

HEIISAsmParser::OperandMatchResultTy
HEIISAsmParser::parseMEMOperand(OperandVector &Operands) {

  SMLoc S, E;
  unsigned BaseReg = 0;

  if (ParseRegister(BaseReg, S, E)) {
    return MatchOperand_NoMatch;
  }

  switch (getLexer().getKind()) {
  default: return MatchOperand_NoMatch;

  case AsmToken::Comma:
  case AsmToken::RBrac:
  case AsmToken::EndOfStatement:
    Operands.push_back(HEIISOperand::CreateMEMr(BaseReg, S, E));
    return MatchOperand_Success;

  case AsmToken:: Plus:
    Parser.Lex(); // Eat the '+'
    break;
  case AsmToken::Minus:
    break;
  }

  std::unique_ptr<HEIISOperand> Offset;
  OperandMatchResultTy ResTy = parseHEIISAsmOperand(Offset);
  if (ResTy != MatchOperand_Success || !Offset)
    return MatchOperand_NoMatch;

  Operands.push_back(
      Offset->isImm() ? HEIISOperand::MorphToMEMri(BaseReg, std::move(Offset))
                      : HEIISOperand::MorphToMEMrr(BaseReg, std::move(Offset)));

  return MatchOperand_Success;
}

HEIISAsmParser::OperandMatchResultTy
HEIISAsmParser::parseOperand(OperandVector &Operands, StringRef Mnemonic) {

  OperandMatchResultTy ResTy = MatchOperandParserImpl(Operands, Mnemonic);

  // If there wasn't a custom match, try the generic matcher below. Otherwise,
  // there was a match, but an error occurred, in which case, just return that
  // the operand parsing failed.
  if (ResTy == MatchOperand_Success || ResTy == MatchOperand_ParseFail)
    return ResTy;

  if (getLexer().is(AsmToken::LBrac)) {
    // Memory operand
    Operands.push_back(HEIISOperand::CreateToken("[",
                                                 Parser.getTok().getLoc()));
    Parser.Lex(); // Eat the [

    if (Mnemonic == "cas" || Mnemonic == "casx" || Mnemonic == "casa") {
      SMLoc S = Parser.getTok().getLoc();
      if (getLexer().getKind() != AsmToken::Percent)
        return MatchOperand_NoMatch;
      Parser.Lex(); // eat %

      unsigned RegNo, RegKind;
      if (!matchRegisterName(Parser.getTok(), RegNo, RegKind))
        return MatchOperand_NoMatch;

      Parser.Lex(); // Eat the identifier token.
      SMLoc E = SMLoc::getFromPointer(Parser.getTok().getLoc().getPointer()-1);
      Operands.push_back(HEIISOperand::CreateReg(RegNo, RegKind, S, E));
      ResTy = MatchOperand_Success;
    } else {
      ResTy = parseMEMOperand(Operands);
    }

    if (ResTy != MatchOperand_Success)
      return ResTy;

    if (!getLexer().is(AsmToken::RBrac))
      return MatchOperand_ParseFail;

    Operands.push_back(HEIISOperand::CreateToken("]",
                                                 Parser.getTok().getLoc()));
    Parser.Lex(); // Eat the ]

    // Parse an optional address-space identifier after the address.
    if (getLexer().is(AsmToken::Integer)) {
      std::unique_ptr<HEIISOperand> Op;
      ResTy = parseHEIISAsmOperand(Op, false);
      if (ResTy != MatchOperand_Success || !Op)
        return MatchOperand_ParseFail;
      Operands.push_back(std::move(Op));
    }
    return MatchOperand_Success;
  }

  std::unique_ptr<HEIISOperand> Op;

  ResTy = parseHEIISAsmOperand(Op, (Mnemonic == "call"));
  if (ResTy != MatchOperand_Success || !Op)
    return MatchOperand_ParseFail;

  // Push the parsed operand into the list of operands
  Operands.push_back(std::move(Op));

  return MatchOperand_Success;
}

HEIISAsmParser::OperandMatchResultTy
HEIISAsmParser::parseHEIISAsmOperand(std::unique_ptr<HEIISOperand> &Op,
                                     bool isCall) {

  SMLoc S = Parser.getTok().getLoc();
  SMLoc E = SMLoc::getFromPointer(Parser.getTok().getLoc().getPointer() - 1);
  const MCExpr *EVal;

  Op = nullptr;
  switch (getLexer().getKind()) {
  default:  break;

  case AsmToken::Percent:
    Parser.Lex(); // Eat the '%'.
    unsigned RegNo;
    unsigned RegKind;
    if (matchRegisterName(Parser.getTok(), RegNo, RegKind)) {
      StringRef name = Parser.getTok().getString();
      Parser.Lex(); // Eat the identifier token.
      E = SMLoc::getFromPointer(Parser.getTok().getLoc().getPointer() - 1);
      switch (RegNo) {
      default:
        Op = HEIISOperand::CreateReg(RegNo, RegKind, S, E);
        break;
      case HEIIS::PSR:
        Op = HEIISOperand::CreateToken("%psr", S);
        break;
      case HEIIS::FSR:
        Op = HEIISOperand::CreateToken("%fsr", S);
        break;
      case HEIIS::FQ:
        Op = HEIISOperand::CreateToken("%fq", S);
        break;
      case HEIIS::CPSR:
        Op = HEIISOperand::CreateToken("%csr", S);
        break;
      case HEIIS::CPQ:
        Op = HEIISOperand::CreateToken("%cq", S);
        break;
      case HEIIS::WIM:
        Op = HEIISOperand::CreateToken("%wim", S);
        break;
      case HEIIS::TBR:
        Op = HEIISOperand::CreateToken("%tbr", S);
        break;
      case HEIIS::ICC:
        if (name == "xcc")
          Op = HEIISOperand::CreateToken("%xcc", S);
        else
          Op = HEIISOperand::CreateToken("%icc", S);
        break;
      }
      break;
    }
    if (matchHEIISAsmModifiers(EVal, E)) {
      E = SMLoc::getFromPointer(Parser.getTok().getLoc().getPointer() - 1);
      Op = HEIISOperand::CreateImm(EVal, S, E);
    }
    break;

  case AsmToken::Minus:
  case AsmToken::Integer:
  case AsmToken::LParen:
  case AsmToken::Dot:
    if (!getParser().parseExpression(EVal, E))
      Op = HEIISOperand::CreateImm(EVal, S, E);
    break;

  case AsmToken::Identifier: {
    StringRef Identifier;
    if (!getParser().parseIdentifier(Identifier)) {
      E = SMLoc::getFromPointer(Parser.getTok().getLoc().getPointer() - 1);
      MCSymbol *Sym = getContext().getOrCreateSymbol(Identifier);

      const MCExpr *Res = MCSymbolRefExpr::create(Sym, MCSymbolRefExpr::VK_None,
                                                  getContext());
      if (isCall && getContext().getObjectFileInfo()->isPositionIndependent())
        Res = HEIISMCExpr::create(HEIISMCExpr::VK_HEIIS_WPLT30, Res,
                                  getContext());
      Op = HEIISOperand::CreateImm(Res, S, E);
    }
    break;
  }
  }
  return (Op) ? MatchOperand_Success : MatchOperand_ParseFail;
}

HEIISAsmParser::OperandMatchResultTy
HEIISAsmParser::parseBranchModifiers(OperandVector &Operands) {

  // parse (,a|,pn|,pt)+

  while (getLexer().is(AsmToken::Comma)) {

    Parser.Lex(); // Eat the comma

    if (!getLexer().is(AsmToken::Identifier))
      return MatchOperand_ParseFail;
    StringRef modName = Parser.getTok().getString();
    if (modName == "a" || modName == "pn" || modName == "pt") {
      Operands.push_back(HEIISOperand::CreateToken(modName,
                                                   Parser.getTok().getLoc()));
      Parser.Lex(); // eat the identifier.
    }
  }
  return MatchOperand_Success;
}

bool HEIISAsmParser::matchRegisterName(const AsmToken &Tok,
                                       unsigned &RegNo,
                                       unsigned &RegKind)
{
  int64_t intVal = 0;
  RegNo = 0;
  RegKind = HEIISOperand::rk_None;
  if (Tok.is(AsmToken::Identifier)) {
    StringRef name = Tok.getString();

    // %fp
    if (name.equals("fp")) {
      RegNo = HEIIS::I6;
      RegKind = HEIISOperand::rk_IntReg;
      return true;
    }
    // %sp
    if (name.equals("sp")) {
      RegNo = HEIIS::O6;
      RegKind = HEIISOperand::rk_IntReg;
      return true;
    }

    if (name.equals("y")) {
      RegNo = HEIIS::Y;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }

    if (name.substr(0, 3).equals_lower("asr")
        && !name.substr(3).getAsInteger(10, intVal)
        && intVal > 0 && intVal < 32) {
      RegNo = ASRRegs[intVal];
      RegKind = HEIISOperand::rk_Special;
      return true;
    }

    // %fprs is an alias of %asr6.
    if (name.equals("fprs")) {
      RegNo = ASRRegs[6];
      RegKind = HEIISOperand::rk_Special;
      return true;
    }

    if (name.equals("icc")) {
      RegNo = HEIIS::ICC;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }

    if (name.equals("psr")) {
      RegNo = HEIIS::PSR;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }

    if (name.equals("fsr")) {
      RegNo = HEIIS::FSR;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }

    if (name.equals("fq")) {
      RegNo = HEIIS::FQ;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }

    if (name.equals("csr")) {
      RegNo = HEIIS::CPSR;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }

    if (name.equals("cq")) {
      RegNo = HEIIS::CPQ;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }
    
    if (name.equals("wim")) {
      RegNo = HEIIS::WIM;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }

    if (name.equals("tbr")) {
      RegNo = HEIIS::TBR;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }

    if (name.equals("xcc")) {
      // FIXME:: check 64bit.
      RegNo = HEIIS::ICC;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }

    // %fcc0 - %fcc3
    if (name.substr(0, 3).equals_lower("fcc")
        && !name.substr(3).getAsInteger(10, intVal)
        && intVal < 4) {
      // FIXME: check 64bit and  handle %fcc1 - %fcc3
      RegNo = HEIIS::FCC0 + intVal;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }

    // %g0 - %g7
    if (name.substr(0, 1).equals_lower("g")
        && !name.substr(1).getAsInteger(10, intVal)
        && intVal < 8) {
      RegNo = IntRegs[intVal];
      RegKind = HEIISOperand::rk_IntReg;
      return true;
    }
    // %o0 - %o7
    if (name.substr(0, 1).equals_lower("o")
        && !name.substr(1).getAsInteger(10, intVal)
        && intVal < 8) {
      RegNo = IntRegs[8 + intVal];
      RegKind = HEIISOperand::rk_IntReg;
      return true;
    }
    if (name.substr(0, 1).equals_lower("l")
        && !name.substr(1).getAsInteger(10, intVal)
        && intVal < 8) {
      RegNo = IntRegs[16 + intVal];
      RegKind = HEIISOperand::rk_IntReg;
      return true;
    }
    if (name.substr(0, 1).equals_lower("i")
        && !name.substr(1).getAsInteger(10, intVal)
        && intVal < 8) {
      RegNo = IntRegs[24 + intVal];
      RegKind = HEIISOperand::rk_IntReg;
      return true;
    }
    // %f0 - %f31
    if (name.substr(0, 1).equals_lower("f")
        && !name.substr(1, 2).getAsInteger(10, intVal) && intVal < 32) {
      RegNo = FloatRegs[intVal];
      RegKind = HEIISOperand::rk_FloatReg;
      return true;
    }
    // %f32 - %f62
    if (name.substr(0, 1).equals_lower("f")
        && !name.substr(1, 2).getAsInteger(10, intVal)
        && intVal >= 32 && intVal <= 62 && (intVal % 2 == 0)) {
      // FIXME: Check V9
      RegNo = DoubleRegs[intVal/2];
      RegKind = HEIISOperand::rk_DoubleReg;
      return true;
    }

    // %r0 - %r31
    if (name.substr(0, 1).equals_lower("r")
        && !name.substr(1, 2).getAsInteger(10, intVal) && intVal < 31) {
      RegNo = IntRegs[intVal];
      RegKind = HEIISOperand::rk_IntReg;
      return true;
    }

    // %c0 - %c31
    if (name.substr(0, 1).equals_lower("c")
        && !name.substr(1).getAsInteger(10, intVal)
        && intVal < 32) {
      RegNo = CoprocRegs[intVal];
      RegKind = HEIISOperand::rk_CoprocReg;
      return true;
    }
    
    if (name.equals("tpc")) {
      RegNo = HEIIS::TPC;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }
    if (name.equals("tnpc")) {
      RegNo = HEIIS::TNPC;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }
    if (name.equals("tstate")) {
      RegNo = HEIIS::TSTATE;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }
    if (name.equals("tt")) {
      RegNo = HEIIS::TT;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }
    if (name.equals("tick")) {
      RegNo = HEIIS::TICK;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }
    if (name.equals("tba")) {
      RegNo = HEIIS::TBA;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }
    if (name.equals("pstate")) {
      RegNo = HEIIS::PSTATE;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }
    if (name.equals("tl")) {
      RegNo = HEIIS::TL;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }
    if (name.equals("pil")) {
      RegNo = HEIIS::PIL;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }
    if (name.equals("cwp")) {
      RegNo = HEIIS::CWP;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }
    if (name.equals("cansave")) {
      RegNo = HEIIS::CANSAVE;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }
    if (name.equals("canrestore")) {
      RegNo = HEIIS::CANRESTORE;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }
    if (name.equals("cleanwin")) {
      RegNo = HEIIS::CLEANWIN;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }
    if (name.equals("otherwin")) {
      RegNo = HEIIS::OTHERWIN;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }
    if (name.equals("wstate")) {
      RegNo = HEIIS::WSTATE;
      RegKind = HEIISOperand::rk_Special;
      return true;
    }
  }
  return false;
}

// Determine if an expression contains a reference to the symbol
// "_GLOBAL_OFFSET_TABLE_".
static bool hasGOTReference(const MCExpr *Expr) {
  switch (Expr->getKind()) {
  case MCExpr::Target:
    if (const HEIISMCExpr *SE = dyn_cast<HEIISMCExpr>(Expr))
      return hasGOTReference(SE->getSubExpr());
    break;

  case MCExpr::Constant:
    break;

  case MCExpr::Binary: {
    const MCBinaryExpr *BE = cast<MCBinaryExpr>(Expr);
    return hasGOTReference(BE->getLHS()) || hasGOTReference(BE->getRHS());
  }

  case MCExpr::SymbolRef: {
    const MCSymbolRefExpr &SymRef = *cast<MCSymbolRefExpr>(Expr);
    return (SymRef.getSymbol().getName() == "_GLOBAL_OFFSET_TABLE_");
  }

  case MCExpr::Unary:
    return hasGOTReference(cast<MCUnaryExpr>(Expr)->getSubExpr());
  }
  return false;
}

const HEIISMCExpr *
HEIISAsmParser::adjustPICRelocation(HEIISMCExpr::VariantKind VK,
                                    const MCExpr *subExpr)
{
  // When in PIC mode, "%lo(...)" and "%hi(...)" behave differently.
  // If the expression refers contains _GLOBAL_OFFSETE_TABLE, it is
  // actually a %pc10 or %pc22 relocation. Otherwise, they are interpreted
  // as %got10 or %got22 relocation.

  if (getContext().getObjectFileInfo()->isPositionIndependent()) {
    switch(VK) {
    default: break;
    case HEIISMCExpr::VK_HEIIS_LO:
      VK = (hasGOTReference(subExpr) ? HEIISMCExpr::VK_HEIIS_PC10
                                     : HEIISMCExpr::VK_HEIIS_GOT10);
      break;
    case HEIISMCExpr::VK_HEIIS_HI:
      VK = (hasGOTReference(subExpr) ? HEIISMCExpr::VK_HEIIS_PC22
                                     : HEIISMCExpr::VK_HEIIS_GOT22);
      break;
    }
  }

  return HEIISMCExpr::create(VK, subExpr, getContext());
}

bool HEIISAsmParser::matchHEIISAsmModifiers(const MCExpr *&EVal,
                                            SMLoc &EndLoc)
{
  AsmToken Tok = Parser.getTok();
  if (!Tok.is(AsmToken::Identifier))
    return false;

  StringRef name = Tok.getString();

  HEIISMCExpr::VariantKind VK = HEIISMCExpr::parseVariantKind(name);

  if (VK == HEIISMCExpr::VK_HEIIS_None)
    return false;

  Parser.Lex(); // Eat the identifier.
  if (Parser.getTok().getKind() != AsmToken::LParen)
    return false;

  Parser.Lex(); // Eat the LParen token.
  const MCExpr *subExpr;
  if (Parser.parseParenExpression(subExpr, EndLoc))
    return false;

  EVal = adjustPICRelocation(VK, subExpr);
  return true;
}

extern "C" void LLVMInitializeHEIISAsmParser() {
  RegisterMCAsmParser<HEIISAsmParser> A(TheHEIISTarget);
  RegisterMCAsmParser<HEIISAsmParser> B(TheHEIISV9Target);
  RegisterMCAsmParser<HEIISAsmParser> C(TheHEIISelTarget);
}

#define GET_REGISTER_MATCHER
#define GET_MATCHER_IMPLEMENTATION
#include "HEIISGenAsmMatcher.inc"

unsigned HEIISAsmParser::validateTargetOperandClass(MCParsedAsmOperand &GOp,
                                                    unsigned Kind) {
  HEIISOperand &Op = (HEIISOperand &)GOp;
  if (Op.isFloatOrDoubleReg()) {
    switch (Kind) {
    default: break;
    case MCK_DFPRegs:
      if (!Op.isFloatReg() || HEIISOperand::MorphToDoubleReg(Op))
        return MCTargetAsmParser::Match_Success;
      break;
    case MCK_QFPRegs:
      if (HEIISOperand::MorphToQuadReg(Op))
        return MCTargetAsmParser::Match_Success;
      break;
    }
  }
  if (Op.isIntReg() && Kind == MCK_IntPair) {
    if (HEIISOperand::MorphToIntPairReg(Op))
      return MCTargetAsmParser::Match_Success;
  }
  if (Op.isCoprocReg() && Kind == MCK_CoprocPair) {
     if (HEIISOperand::MorphToCoprocPairReg(Op))
       return MCTargetAsmParser::Match_Success;
   }
  return Match_InvalidOperand;
}
