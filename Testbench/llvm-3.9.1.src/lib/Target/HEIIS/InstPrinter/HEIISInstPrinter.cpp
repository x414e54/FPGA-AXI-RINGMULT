//===-- HEIISInstPrinter.cpp - Convert HEIIS MCInst to assembly syntax -----==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class prints an HEIIS MCInst to a .s file.
//
//===----------------------------------------------------------------------===//

#include "HEIISInstPrinter.h"
#include "HEIIS.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/raw_ostream.h"
using namespace llvm;

#define DEBUG_TYPE "asm-printer"

// The generated AsmMatcher HEIISGenAsmWriter uses "HEIIS" as the target
// namespace. But SPARC backend uses "SP" as its namespace.
namespace llvm {
namespace HEIIS {
  using namespace SP;
}
}

#define GET_INSTRUCTION_NAME
#define PRINT_ALIAS_INSTR
#include "HEIISGenAsmWriter.inc"

bool HEIISInstPrinter::isV9(const MCSubtargetInfo &STI) const {
  return (STI.getFeatureBits()[HEIIS::FeatureV9]) != 0;
}

void HEIISInstPrinter::printRegName(raw_ostream &OS, unsigned RegNo) const
{
  OS << '%' << StringRef(getRegisterName(RegNo)).lower();
}

void HEIISInstPrinter::printInst(const MCInst *MI, raw_ostream &O,
                                 StringRef Annot, const MCSubtargetInfo &STI) {
  if (!printAliasInstr(MI, STI, O) && !printHEIISAliasInstr(MI, STI, O))
    printInstruction(MI, STI, O);
  printAnnotation(O, Annot);
}

bool HEIISInstPrinter::printHEIISAliasInstr(const MCInst *MI,
                                            const MCSubtargetInfo &STI,
                                            raw_ostream &O) {
  switch (MI->getOpcode()) {
  default: return false;
  case HE::JMPLrr:
  case HE::JMPLri: {
    if (MI->getNumOperands() != 3)
      return false;
    if (!MI->getOperand(0).isReg())
      return false;
    switch (MI->getOperand(0).getReg()) {
    default: return false;
    case HE::G0: // jmp $addr | ret | retl
      if (MI->getOperand(2).isImm() &&
          MI->getOperand(2).getImm() == 8) {
        switch(MI->getOperand(1).getReg()) {
        default: break;
        case HE::I7: O << "\tret"; return true;
        case HE::O7: O << "\tretl"; return true;
        }
      }
      O << "\tjmp "; printMemOperand(MI, 1, STI, O);
      return true;
    case HE::O7: // call $addr
      O << "\tcall "; printMemOperand(MI, 1, STI, O);
      return true;
    }
  }
  case HE::V9FCMPS:  case HE::V9FCMPD:  case HE::V9FCMPQ:
  case HE::V9FCMPES: case HE::V9FCMPED: case HE::V9FCMPEQ: {
    if (isV9(STI)
        || (MI->getNumOperands() != 3)
        || (!MI->getOperand(0).isReg())
        || (MI->getOperand(0).getReg() != HE::FCC0))
      return false;
    // if V8, skip printing %fcc0.
    switch(MI->getOpcode()) {
    default:
    case HE::V9FCMPS:  O << "\tfcmps "; break;
    case HE::V9FCMPD:  O << "\tfcmpd "; break;
    case HE::V9FCMPQ:  O << "\tfcmpq "; break;
    case HE::V9FCMPES: O << "\tfcmpes "; break;
    case HE::V9FCMPED: O << "\tfcmped "; break;
    case HE::V9FCMPEQ: O << "\tfcmpeq "; break;
    }
    printOperand(MI, 1, STI, O);
    O << ", ";
    printOperand(MI, 2, STI, O);
    return true;
  }
  }
}

void HEIISInstPrinter::printOperand(const MCInst *MI, int opNum,
                                    const MCSubtargetInfo &STI,
                                    raw_ostream &O) {
  const MCOperand &MO = MI->getOperand (opNum);

  if (MO.isReg()) {
    printRegName(O, MO.getReg());
    return ;
  }

  if (MO.isImm()) {
    switch (MI->getOpcode()) {
      default:
        O << (int)MO.getImm(); 
        return;
        
      case HE::TICCri: // Fall through
      case HE::TICCrr: // Fall through
      case HE::TRAPri: // Fall through
      case HE::TRAPrr: // Fall through
      case HE::TXCCri: // Fall through
      case HE::TXCCrr: // Fall through
        // Only seven-bit values up to 127.
        O << ((int) MO.getImm() & 0x7f);  
        return;
    }
  }

  assert(MO.isExpr() && "Unknown operand kind in printOperand");
  MO.getExpr()->print(O, &MAI);
}

void HEIISInstPrinter::printMemOperand(const MCInst *MI, int opNum,
                                       const MCSubtargetInfo &STI,
                                       raw_ostream &O, const char *Modifier) {
  printOperand(MI, opNum, STI, O);

  // If this is an ADD operand, emit it like normal operands.
  if (Modifier && !strcmp(Modifier, "arith")) {
    O << ", ";
    printOperand(MI, opNum+1, STI, O);
    return;
  }
  const MCOperand &MO = MI->getOperand(opNum+1);

  if (MO.isReg() && MO.getReg() == HE::G0)
    return;   // don't print "+%g0"
  if (MO.isImm() && MO.getImm() == 0)
    return;   // don't print "+0"

  O << "+";

  printOperand(MI, opNum+1, STI, O);
}

void HEIISInstPrinter::printCCOperand(const MCInst *MI, int opNum,
                                      const MCSubtargetInfo &STI,
                                      raw_ostream &O) {
  int CC = (int)MI->getOperand(opNum).getImm();
  switch (MI->getOpcode()) {
  default: break;
  case HE::FBCOND:
  case HE::FBCONDA:
  case HE::BPFCC:
  case HE::BPFCCA:
  case HE::BPFCCNT:
  case HE::BPFCCANT:
  case HE::MOVFCCrr:  case HE::V9MOVFCCrr:
  case HE::MOVFCCri:  case HE::V9MOVFCCri:
  case HE::FMOVS_FCC: case HE::V9FMOVS_FCC:
  case HE::FMOVD_FCC: case HE::V9FMOVD_FCC:
  case HE::FMOVQ_FCC: case HE::V9FMOVQ_FCC:
    // Make sure CC is a fp conditional flag.
    CC = (CC < 16) ? (CC + 16) : CC;
    break;
  case HE::CBCOND:
  case HE::CBCONDA:
    // Make sure CC is a cp conditional flag.
    CC = (CC < 32) ? (CC + 32) : CC;
    break;
  }
  O << SPARCCondCodeToString((SPCC::CondCodes)CC);
}

bool HEIISInstPrinter::printGetPCX(const MCInst *MI, unsigned opNum,
                                   const MCSubtargetInfo &STI,
                                   raw_ostream &O) {
  llvm_unreachable("FIXME: Implement HEIISInstPrinter::printGetPCX.");
  return true;
}
