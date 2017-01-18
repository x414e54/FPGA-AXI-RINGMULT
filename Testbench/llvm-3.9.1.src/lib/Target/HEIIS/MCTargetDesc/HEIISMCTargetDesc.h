//===-- HEIISMCTargetDesc.h - HEIIS Target Descriptions ---------*- C++ -*-===//
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

#ifndef LLVM_LIB_TARGET_SPARC_MCTARGETDESC_SPARCMCTARGETDESC_H
#define LLVM_LIB_TARGET_SPARC_MCTARGETDESC_SPARCMCTARGETDESC_H

#include "llvm/Support/DataTypes.h"

namespace llvm {
class MCAsmBackend;
class MCCodeEmitter;
class MCContext;
class MCInstrInfo;
class MCObjectWriter;
class MCRegisterInfo;
class MCSubtargetInfo;
class Target;
class Triple;
class StringRef;
class raw_pwrite_stream;
class raw_ostream;

extern Target TheHEIISTarget;
extern Target TheHEIISV9Target;
extern Target TheHEIISelTarget;

MCCodeEmitter *createHEIISMCCodeEmitter(const MCInstrInfo &MCII,
                                        const MCRegisterInfo &MRI,
                                        MCContext &Ctx);
MCAsmBackend *createHEIISAsmBackend(const Target &T, const MCRegisterInfo &MRI,
                                    const Triple &TT, StringRef CPU);
MCObjectWriter *createHEIISELFObjectWriter(raw_pwrite_stream &OS, bool Is64Bit,
                                           bool IsLIttleEndian, uint8_t OSABI);
} // End llvm namespace

// Defines symbolic names for HEIIS registers.  This defines a mapping from
// register name to register number.
//
#define GET_REGINFO_ENUM
#include "HEIISGenRegisterInfo.inc"

// Defines symbolic names for the HEIIS instructions.
//
#define GET_INSTRINFO_ENUM
#include "HEIISGenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "HEIISGenSubtargetInfo.inc"

#endif
