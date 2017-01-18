//===-- HEIISTargetStreamer.cpp - HEIIS Target Streamer Methods -----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides HEIIS specific target streamer methods.
//
//===----------------------------------------------------------------------===//

#include "HEIISTargetStreamer.h"
#include "InstPrinter/HEIISInstPrinter.h"
#include "llvm/Support/FormattedStream.h"

using namespace llvm;

// pin vtable to this file
HEIISTargetStreamer::HEIISTargetStreamer(MCStreamer &S) : MCTargetStreamer(S) {}

void HEIISTargetStreamer::anchor() {}

HEIISTargetAsmStreamer::HEIISTargetAsmStreamer(MCStreamer &S,
                                               formatted_raw_ostream &OS)
    : HEIISTargetStreamer(S), OS(OS) {}

void HEIISTargetAsmStreamer::emitHEIISRegisterIgnore(unsigned reg) {
  OS << "\t.register "
     << "%" << StringRef(HEIISInstPrinter::getRegisterName(reg)).lower()
     << ", #ignore\n";
}

void HEIISTargetAsmStreamer::emitHEIISRegisterScratch(unsigned reg) {
  OS << "\t.register "
     << "%" << StringRef(HEIISInstPrinter::getRegisterName(reg)).lower()
     << ", #scratch\n";
}

HEIISTargetELFStreamer::HEIISTargetELFStreamer(MCStreamer &S)
    : HEIISTargetStreamer(S) {}

MCELFStreamer &HEIISTargetELFStreamer::getStreamer() {
  return static_cast<MCELFStreamer &>(Streamer);
}
