//===-- HEIISTargetMachine.h - Define TargetMachine for HEIIS ---*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the HEIIS specific subclass of TargetMachine.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_SPARC_SPARCTARGETMACHINE_H
#define LLVM_LIB_TARGET_SPARC_SPARCTARGETMACHINE_H

#include "HEIISInstrInfo.h"
#include "HEIISSubtarget.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {

class HEIISTargetMachine : public LLVMTargetMachine {
  std::unique_ptr<TargetLoweringObjectFile> TLOF;
  HEIISSubtarget Subtarget;
  bool is64Bit;
  mutable StringMap<std::unique_ptr<HEIISSubtarget>> SubtargetMap;
public:
  HEIISTargetMachine(const Target &T, const Triple &TT, StringRef CPU,
                     StringRef FS, const TargetOptions &Options,
                     Optional<Reloc::Model> RM, CodeModel::Model CM,
                     CodeGenOpt::Level OL, bool is64bit);
  ~HEIISTargetMachine() override;

  const HEIISSubtarget *getSubtargetImpl() const { return &Subtarget; }
  const HEIISSubtarget *getSubtargetImpl(const Function &) const override;

  // Pass Pipeline Configuration
  TargetPassConfig *createPassConfig(PassManagerBase &PM) override;
  TargetLoweringObjectFile *getObjFileLowering() const override {
    return TLOF.get();
  }
};

/// HEIIS 32-bit target machine
///
class HEIISV8TargetMachine : public HEIISTargetMachine {
  virtual void anchor();
public:
  HEIISV8TargetMachine(const Target &T, const Triple &TT, StringRef CPU,
                       StringRef FS, const TargetOptions &Options,
                       Optional<Reloc::Model> RM, CodeModel::Model CM,
                       CodeGenOpt::Level OL);
};

/// HEIIS 64-bit target machine
///
class HEIISV9TargetMachine : public HEIISTargetMachine {
  virtual void anchor();
public:
  HEIISV9TargetMachine(const Target &T, const Triple &TT, StringRef CPU,
                       StringRef FS, const TargetOptions &Options,
                       Optional<Reloc::Model> RM, CodeModel::Model CM,
                       CodeGenOpt::Level OL);
};

class HEIISelTargetMachine : public HEIISTargetMachine {
  virtual void anchor();

public:
  HEIISelTargetMachine(const Target &T, const Triple &TT, StringRef CPU,
                       StringRef FS, const TargetOptions &Options,
                       Optional<Reloc::Model> RM, CodeModel::Model CM,
                       CodeGenOpt::Level OL);
};

} // end namespace llvm

#endif
