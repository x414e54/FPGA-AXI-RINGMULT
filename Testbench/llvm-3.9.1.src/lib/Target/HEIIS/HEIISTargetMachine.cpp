//===-- HEIISTargetMachine.cpp - Define TargetMachine for HEIIS -----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
//
//===----------------------------------------------------------------------===//

#include "HEIISTargetMachine.h"
#include "HEIISTargetObjectFile.h"
#include "HEIIS.h"
#include "LeonPasses.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

extern "C" void LLVMInitializeHEIISTarget() {
  // Register the target.
  RegisterTargetMachine<HEIISV8TargetMachine> X(TheHEIISTarget);
  RegisterTargetMachine<HEIISV9TargetMachine> Y(TheHEIISV9Target);
  RegisterTargetMachine<HEIISelTargetMachine> Z(TheHEIISelTarget);
}

static std::string computeDataLayout(const Triple &T, bool is64Bit) {
  // HEIIS is typically big endian, but some are little.
  std::string Ret = T.getArch() == Triple::sparcel ? "e" : "E";
  Ret += "-m:e";

  // Some ABIs have 32bit pointers.
  if (!is64Bit)
    Ret += "-p:32:32";

  // Alignments for 64 bit integers.
  Ret += "-i64:64";

  // On HEIISV9 128 floats are aligned to 128 bits, on others only to 64.
  // On HEIISV9 registers can hold 64 or 32 bits, on others only 32.
  if (is64Bit)
    Ret += "-n32:64";
  else
    Ret += "-f128:64-n32";

  if (is64Bit)
    Ret += "-S128";
  else
    Ret += "-S64";

  return Ret;
}

static Reloc::Model getEffectiveRelocModel(Optional<Reloc::Model> RM) {
  if (!RM.hasValue())
    return Reloc::Static;
  return *RM;
}

/// Create an ILP32 architecture model
HEIISTargetMachine::HEIISTargetMachine(const Target &T, const Triple &TT,
                                       StringRef CPU, StringRef FS,
                                       const TargetOptions &Options,
                                       Optional<Reloc::Model> RM,
                                       CodeModel::Model CM,
                                       CodeGenOpt::Level OL, bool is64bit)
    : LLVMTargetMachine(T, computeDataLayout(TT, is64bit), TT, CPU, FS, Options,
                        getEffectiveRelocModel(RM), CM, OL),
      TLOF(make_unique<HEIISELFTargetObjectFile>()),
      Subtarget(TT, CPU, FS, *this, is64bit), is64Bit(is64bit) {
  initAsmInfo();
}

HEIISTargetMachine::~HEIISTargetMachine() {}

const HEIISSubtarget *
HEIISTargetMachine::getSubtargetImpl(const Function &F) const {
  Attribute CPUAttr = F.getFnAttribute("target-cpu");
  Attribute FSAttr = F.getFnAttribute("target-features");

  std::string CPU = !CPUAttr.hasAttribute(Attribute::None)
                        ? CPUAttr.getValueAsString().str()
                        : TargetCPU;
  std::string FS = !FSAttr.hasAttribute(Attribute::None)
                       ? FSAttr.getValueAsString().str()
                       : TargetFS;

  // FIXME: This is related to the code below to reset the target options,
  // we need to know whether or not the soft float flag is set on the
  // function, so we can enable it as a subtarget feature.
  bool softFloat =
      F.hasFnAttribute("use-soft-float") &&
      F.getFnAttribute("use-soft-float").getValueAsString() == "true";

  if (softFloat)
    FS += FS.empty() ? "+soft-float" : ",+soft-float";

  auto &I = SubtargetMap[CPU + FS];
  if (!I) {
    // This needs to be done before we create a new subtarget since any
    // creation will depend on the TM and the code generation flags on the
    // function that reside in TargetOptions.
    resetTargetOptions(F);
    I = llvm::make_unique<HEIISSubtarget>(TargetTriple, CPU, FS, *this,
                                          this->is64Bit);
  }
  return I.get();
}

namespace {
/// HEIIS Code Generator Pass Configuration Options.
class HEIISPassConfig : public TargetPassConfig {
public:
  HEIISPassConfig(HEIISTargetMachine *TM, PassManagerBase &PM)
      : TargetPassConfig(TM, PM) {}

  HEIISTargetMachine &getHEIISTargetMachine() const {
    return getTM<HEIISTargetMachine>();
  }

  void addIRPasses() override;
  bool addInstSelector() override;
  void addPreEmitPass() override;
};
} // namespace

TargetPassConfig *HEIISTargetMachine::createPassConfig(PassManagerBase &PM) {
  return new HEIISPassConfig(this, PM);
}

void HEIISPassConfig::addIRPasses() {
  addPass(createAtomicExpandPass(&getHEIISTargetMachine()));

  TargetPassConfig::addIRPasses();
}

bool HEIISPassConfig::addInstSelector() {
  addPass(createHEIISISelDag(getHEIISTargetMachine()));
  return false;
}

void HEIISPassConfig::addPreEmitPass() {
  addPass(createHEIISDelaySlotFillerPass(getHEIISTargetMachine()));
  if (this->getHEIISTargetMachine().getSubtargetImpl()->ignoreZeroFlag()) {
    addPass(new IgnoreZeroFlag(getHEIISTargetMachine()));
  }
  if (this->getHEIISTargetMachine().getSubtargetImpl()->performSDIVReplace()) {
    addPass(new ReplaceSDIV(getHEIISTargetMachine()));
  }
  if (this->getHEIISTargetMachine().getSubtargetImpl()->fixCallImmediates()) {
    addPass(new FixCALL(getHEIISTargetMachine()));
  }
  if (this->getHEIISTargetMachine().getSubtargetImpl()->fixFSMULD()) {
    addPass(new FixFSMULD(getHEIISTargetMachine()));
  }
  if (this->getHEIISTargetMachine().getSubtargetImpl()->replaceFMULS()) {
    addPass(new ReplaceFMULS(getHEIISTargetMachine()));
  }
  if (this->getHEIISTargetMachine().getSubtargetImpl()->preventRoundChange()) {
    addPass(new PreventRoundChange(getHEIISTargetMachine()));
  }
  if (this->getHEIISTargetMachine().getSubtargetImpl()->fixAllFDIVSQRT()) {
    addPass(new FixAllFDIVSQRT(getHEIISTargetMachine()));
  }
  if (this->getHEIISTargetMachine().getSubtargetImpl()->insertNOPsLoadStore()) {
    addPass(new InsertNOPsLoadStore(getHEIISTargetMachine()));
  }
  if (this->getHEIISTargetMachine().getSubtargetImpl()->insertNOPLoad()) {
    addPass(new InsertNOPLoad(getHEIISTargetMachine()));
  }
  if (this->getHEIISTargetMachine().getSubtargetImpl()->flushCacheLineSWAP()) {
    addPass(new FlushCacheLineSWAP(getHEIISTargetMachine()));
  }
  if (this->getHEIISTargetMachine()
          .getSubtargetImpl()
          ->insertNOPDoublePrecision()) {
    addPass(new InsertNOPDoublePrecision(getHEIISTargetMachine()));
  }
}

void HEIISV8TargetMachine::anchor() {}

HEIISV8TargetMachine::HEIISV8TargetMachine(const Target &T, const Triple &TT,
                                           StringRef CPU, StringRef FS,
                                           const TargetOptions &Options,
                                           Optional<Reloc::Model> RM,
                                           CodeModel::Model CM,
                                           CodeGenOpt::Level OL)
    : HEIISTargetMachine(T, TT, CPU, FS, Options, RM, CM, OL, false) {}

void HEIISV9TargetMachine::anchor() {}

HEIISV9TargetMachine::HEIISV9TargetMachine(const Target &T, const Triple &TT,
                                           StringRef CPU, StringRef FS,
                                           const TargetOptions &Options,
                                           Optional<Reloc::Model> RM,
                                           CodeModel::Model CM,
                                           CodeGenOpt::Level OL)
    : HEIISTargetMachine(T, TT, CPU, FS, Options, RM, CM, OL, true) {}

void HEIISelTargetMachine::anchor() {}

HEIISelTargetMachine::HEIISelTargetMachine(const Target &T, const Triple &TT,
                                           StringRef CPU, StringRef FS,
                                           const TargetOptions &Options,
                                           Optional<Reloc::Model> RM,
                                           CodeModel::Model CM,
                                           CodeGenOpt::Level OL)
    : HEIISTargetMachine(T, TT, CPU, FS, Options, RM, CM, OL, false) {}
