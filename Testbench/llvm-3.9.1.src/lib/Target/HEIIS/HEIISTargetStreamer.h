//===-- HEIISTargetStreamer.h - HEIIS Target Streamer ----------*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_SPARC_SPARCTARGETSTREAMER_H
#define LLVM_LIB_TARGET_SPARC_SPARCTARGETSTREAMER_H

#include "llvm/MC/MCELFStreamer.h"
#include "llvm/MC/MCStreamer.h"

namespace llvm {
class HEIISTargetStreamer : public MCTargetStreamer {
  virtual void anchor();

public:
  HEIISTargetStreamer(MCStreamer &S);
  /// Emit ".register <reg>, #ignore".
  virtual void emitHEIISRegisterIgnore(unsigned reg) = 0;
  /// Emit ".register <reg>, #scratch".
  virtual void emitHEIISRegisterScratch(unsigned reg) = 0;
};

// This part is for ascii assembly output
class HEIISTargetAsmStreamer : public HEIISTargetStreamer {
  formatted_raw_ostream &OS;

public:
  HEIISTargetAsmStreamer(MCStreamer &S, formatted_raw_ostream &OS);
  void emitHEIISRegisterIgnore(unsigned reg) override;
  void emitHEIISRegisterScratch(unsigned reg) override;

};

// This part is for ELF object output
class HEIISTargetELFStreamer : public HEIISTargetStreamer {
public:
  HEIISTargetELFStreamer(MCStreamer &S);
  MCELFStreamer &getStreamer();
  void emitHEIISRegisterIgnore(unsigned reg) override {}
  void emitHEIISRegisterScratch(unsigned reg) override {}
};
} // end namespace llvm

#endif
