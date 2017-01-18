//===-- HEIISTargetInfo.cpp - HEIIS Target Implementation -----------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "HEIIS.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

Target llvm::TheHEIISTarget;
Target llvm::TheHEIISV9Target;
Target llvm::TheHEIISelTarget;

extern "C" void LLVMInitializeHEIISTargetInfo() {
  RegisterTarget<Triple::sparc, /*HasJIT=*/true> X(TheHEIISTarget, "sparc",
                                                   "HEIIS");
  RegisterTarget<Triple::sparcv9, /*HasJIT=*/true> Y(TheHEIISV9Target,
                                                     "sparcv9", "HEIIS V9");
  RegisterTarget<Triple::sparcel, /*HasJIT=*/true> Z(TheHEIISelTarget,
                                                     "sparcel", "HEIIS LE");
}
