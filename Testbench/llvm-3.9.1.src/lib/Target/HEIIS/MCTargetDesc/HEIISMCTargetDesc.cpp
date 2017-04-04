//===-- HEIISMCTargetDesc.cpp - HEIIS Target Descriptions -----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides HEIIS specific target descriptions.
//
//===----------------------------------------------------------------------===//

#include "HEIISMCTargetDesc.h"
#include "InstPrinter/HEIISInstPrinter.h"
#include "HEIISMCAsmInfo.h"
#include "HEIISTargetStreamer.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

#define GET_INSTRINFO_MC_DESC
#include "HEIISGenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "HEIISGenSubtargetInfo.inc"

#define GET_REGINFO_MC_DESC
#include "HEIISGenRegisterInfo.inc"

static MCAsmInfo *createHEIISMCAsmInfo(const MCRegisterInfo &MRI,
                                       const Triple &TT) {
  MCAsmInfo *MAI = new HEIISELFMCAsmInfo(TT);
  unsigned Reg = MRI.getDwarfRegNum(HE::O6, true);
  MCCFIInstruction Inst = MCCFIInstruction::createDefCfa(nullptr, Reg, 0);
  MAI->addInitialFrameState(Inst);
  return MAI;
}

static MCAsmInfo *createHEIISV9MCAsmInfo(const MCRegisterInfo &MRI,
                                         const Triple &TT) {
  MCAsmInfo *MAI = new HEIISELFMCAsmInfo(TT);
  unsigned Reg = MRI.getDwarfRegNum(HE::O6, true);
  MCCFIInstruction Inst = MCCFIInstruction::createDefCfa(nullptr, Reg, 2047);
  MAI->addInitialFrameState(Inst);
  return MAI;
}

static MCInstrInfo *createHEIISMCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitHEIISMCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createHEIISMCRegisterInfo(const Triple &TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitHEIISMCRegisterInfo(X, HE::O7);
  return X;
}

static MCSubtargetInfo *
createHEIISMCSubtargetInfo(const Triple &TT, StringRef CPU, StringRef FS) {
  if (CPU.empty())
    CPU = (TT.getArch() == Triple::sparcv9) ? "v9" : "v8";
  return createHEIISMCSubtargetInfoImpl(TT, CPU, FS);
}

// Code models. Some only make sense for 64-bit code.
//
// SunCC  Reloc   CodeModel  Constraints
// abs32  Static  Small      text+data+bss linked below 2^32 bytes
// abs44  Static  Medium     text+data+bss linked below 2^44 bytes
// abs64  Static  Large      text smaller than 2^31 bytes
// pic13  PIC_    Small      GOT < 2^13 bytes
// pic32  PIC_    Medium     GOT < 2^32 bytes
//
// All code models require that the text segment is smaller than 2GB.

static void adjustCodeGenOpts(const Triple &TT, Reloc::Model RM,
                              CodeModel::Model &CM) {
  // The default 32-bit code model is abs32/pic32 and the default 32-bit
  // code model for JIT is abs32.
  switch (CM) {
  default: break;
  case CodeModel::Default:
  case CodeModel::JITDefault: CM = CodeModel::Small; break;
  }
}

static void adjustCodeGenOptsV9(const Triple &TT, Reloc::Model RM,
                                CodeModel::Model &CM) {
  // The default 64-bit code model is abs44/pic32 and the default 64-bit
  // code model for JIT is abs64.
  switch (CM) {
  default:  break;
  case CodeModel::Default:
    CM = RM == Reloc::PIC_ ? CodeModel::Small : CodeModel::Medium;
    break;
  case CodeModel::JITDefault:
    CM = CodeModel::Large;
    break;
  }
}

static MCTargetStreamer *
createObjectTargetStreamer(MCStreamer &S, const MCSubtargetInfo &STI) {
  return new HEIISTargetELFStreamer(S);
}

static MCTargetStreamer *createTargetAsmStreamer(MCStreamer &S,
                                                 formatted_raw_ostream &OS,
                                                 MCInstPrinter *InstPrint,
                                                 bool isVerboseAsm) {
  return new HEIISTargetAsmStreamer(S, OS);
}

static MCInstPrinter *createHEIISMCInstPrinter(const Triple &T,
                                               unsigned SyntaxVariant,
                                               const MCAsmInfo &MAI,
                                               const MCInstrInfo &MII,
                                               const MCRegisterInfo &MRI) {
  return new HEIISInstPrinter(MAI, MII, MRI);
}

extern "C" void LLVMInitializeHEIISTargetMC() {
  // Register the MC asm info.
  RegisterMCAsmInfoFn X(TheHEIISTarget, createHEIISMCAsmInfo);
  RegisterMCAsmInfoFn Y(TheHEIISV9Target, createHEIISV9MCAsmInfo);
  RegisterMCAsmInfoFn Z(TheHEIISelTarget, createHEIISMCAsmInfo);

  for (Target *T : {&TheHEIISTarget, &TheHEIISV9Target, &TheHEIISelTarget}) {
    // Register the MC instruction info.
    TargetRegistry::RegisterMCInstrInfo(*T, createHEIISMCInstrInfo);

    // Register the MC register info.
    TargetRegistry::RegisterMCRegInfo(*T, createHEIISMCRegisterInfo);

    // Register the MC subtarget info.
    TargetRegistry::RegisterMCSubtargetInfo(*T, createHEIISMCSubtargetInfo);

    // Register the MC Code Emitter.
    TargetRegistry::RegisterMCCodeEmitter(*T, createHEIISMCCodeEmitter);

    // Register the asm backend.
    TargetRegistry::RegisterMCAsmBackend(*T, createHEIISAsmBackend);

    // Register the object target streamer.
    TargetRegistry::RegisterObjectTargetStreamer(*T,
                                                 createObjectTargetStreamer);

    // Register the asm streamer.
    TargetRegistry::RegisterAsmTargetStreamer(*T, createTargetAsmStreamer);

    // Register the MCInstPrinter
    TargetRegistry::RegisterMCInstPrinter(*T, createHEIISMCInstPrinter);
  }

  // Register the MC codegen info.
  TargetRegistry::registerMCAdjustCodeGenOpts(TheHEIISTarget,
                                              adjustCodeGenOpts);
  TargetRegistry::registerMCAdjustCodeGenOpts(TheHEIISV9Target,
                                              adjustCodeGenOptsV9);
  TargetRegistry::registerMCAdjustCodeGenOpts(TheHEIISelTarget,
                                              adjustCodeGenOpts);
}
