//===-- HEIISMCExpr.cpp - HEIIS specific MC expression classes --------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the implementation of the assembly expression modifiers
// accepted by the HEIIS architecture (e.g. "%hi", "%lo", ...).
//
//===----------------------------------------------------------------------===//

#include "HEIISMCExpr.h"
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCObjectStreamer.h"
#include "llvm/MC/MCSymbolELF.h"
#include "llvm/Object/ELF.h"


using namespace llvm;

#define DEBUG_TYPE "sparcmcexpr"

const HEIISMCExpr*
HEIISMCExpr::create(VariantKind Kind, const MCExpr *Expr,
                      MCContext &Ctx) {
    return new (Ctx) HEIISMCExpr(Kind, Expr);
}

void HEIISMCExpr::printImpl(raw_ostream &OS, const MCAsmInfo *MAI) const {

  bool closeParen = printVariantKind(OS, Kind);

  const MCExpr *Expr = getSubExpr();
  Expr->print(OS, MAI);

  if (closeParen)
    OS << ')';
}

bool HEIISMCExpr::printVariantKind(raw_ostream &OS, VariantKind Kind)
{
  bool closeParen = true;
  switch (Kind) {
  case VK_HEIIS_None:     closeParen = false; break;
  case VK_HEIIS_LO:       OS << "%lo(";  break;
  case VK_HEIIS_HI:       OS << "%hi(";  break;
  case VK_HEIIS_H44:      OS << "%h44("; break;
  case VK_HEIIS_M44:      OS << "%m44("; break;
  case VK_HEIIS_L44:      OS << "%l44("; break;
  case VK_HEIIS_HH:       OS << "%hh(";  break;
  case VK_HEIIS_HM:       OS << "%hm(";  break;
    // FIXME: use %pc22/%pc10, if system assembler supports them.
  case VK_HEIIS_PC22:     OS << "%hi("; break;
  case VK_HEIIS_PC10:     OS << "%lo("; break;
    // FIXME: use %got22/%got10, if system assembler supports them.
  case VK_HEIIS_GOT22:    OS << "%hi("; break;
  case VK_HEIIS_GOT10:    OS << "%lo("; break;
  case VK_HEIIS_WPLT30:   closeParen = false; break;
  case VK_HEIIS_R_DISP32: OS << "%r_disp32("; break;
  case VK_HEIIS_TLS_GD_HI22:   OS << "%tgd_hi22(";   break;
  case VK_HEIIS_TLS_GD_LO10:   OS << "%tgd_lo10(";   break;
  case VK_HEIIS_TLS_GD_ADD:    OS << "%tgd_add(";    break;
  case VK_HEIIS_TLS_GD_CALL:   OS << "%tgd_call(";   break;
  case VK_HEIIS_TLS_LDM_HI22:  OS << "%tldm_hi22(";  break;
  case VK_HEIIS_TLS_LDM_LO10:  OS << "%tldm_lo10(";  break;
  case VK_HEIIS_TLS_LDM_ADD:   OS << "%tldm_add(";   break;
  case VK_HEIIS_TLS_LDM_CALL:  OS << "%tldm_call(";  break;
  case VK_HEIIS_TLS_LDO_HIX22: OS << "%tldo_hix22("; break;
  case VK_HEIIS_TLS_LDO_LOX10: OS << "%tldo_lox10("; break;
  case VK_HEIIS_TLS_LDO_ADD:   OS << "%tldo_add(";   break;
  case VK_HEIIS_TLS_IE_HI22:   OS << "%tie_hi22(";   break;
  case VK_HEIIS_TLS_IE_LO10:   OS << "%tie_lo10(";   break;
  case VK_HEIIS_TLS_IE_LD:     OS << "%tie_ld(";     break;
  case VK_HEIIS_TLS_IE_LDX:    OS << "%tie_ldx(";    break;
  case VK_HEIIS_TLS_IE_ADD:    OS << "%tie_add(";    break;
  case VK_HEIIS_TLS_LE_HIX22:  OS << "%tle_hix22(";  break;
  case VK_HEIIS_TLS_LE_LOX10:  OS << "%tle_lox10(";  break;
  }
  return closeParen;
}

HEIISMCExpr::VariantKind HEIISMCExpr::parseVariantKind(StringRef name)
{
  return StringSwitch<HEIISMCExpr::VariantKind>(name)
    .Case("lo",  VK_HEIIS_LO)
    .Case("hi",  VK_HEIIS_HI)
    .Case("h44", VK_HEIIS_H44)
    .Case("m44", VK_HEIIS_M44)
    .Case("l44", VK_HEIIS_L44)
    .Case("hh",  VK_HEIIS_HH)
    .Case("hm",  VK_HEIIS_HM)
    .Case("pc22",  VK_HEIIS_PC22)
    .Case("pc10",  VK_HEIIS_PC10)
    .Case("got22", VK_HEIIS_GOT22)
    .Case("got10", VK_HEIIS_GOT10)
    .Case("r_disp32",   VK_HEIIS_R_DISP32)
    .Case("tgd_hi22",   VK_HEIIS_TLS_GD_HI22)
    .Case("tgd_lo10",   VK_HEIIS_TLS_GD_LO10)
    .Case("tgd_add",    VK_HEIIS_TLS_GD_ADD)
    .Case("tgd_call",   VK_HEIIS_TLS_GD_CALL)
    .Case("tldm_hi22",  VK_HEIIS_TLS_LDM_HI22)
    .Case("tldm_lo10",  VK_HEIIS_TLS_LDM_LO10)
    .Case("tldm_add",   VK_HEIIS_TLS_LDM_ADD)
    .Case("tldm_call",  VK_HEIIS_TLS_LDM_CALL)
    .Case("tldo_hix22", VK_HEIIS_TLS_LDO_HIX22)
    .Case("tldo_lox10", VK_HEIIS_TLS_LDO_LOX10)
    .Case("tldo_add",   VK_HEIIS_TLS_LDO_ADD)
    .Case("tie_hi22",   VK_HEIIS_TLS_IE_HI22)
    .Case("tie_lo10",   VK_HEIIS_TLS_IE_LO10)
    .Case("tie_ld",     VK_HEIIS_TLS_IE_LD)
    .Case("tie_ldx",    VK_HEIIS_TLS_IE_LDX)
    .Case("tie_add",    VK_HEIIS_TLS_IE_ADD)
    .Case("tle_hix22",  VK_HEIIS_TLS_LE_HIX22)
    .Case("tle_lox10",  VK_HEIIS_TLS_LE_LOX10)
    .Default(VK_HEIIS_None);
}

HEIIS::Fixups HEIISMCExpr::getFixupKind(HEIISMCExpr::VariantKind Kind) {
  switch (Kind) {
  default: llvm_unreachable("Unhandled HEIISMCExpr::VariantKind");
  case VK_HEIIS_LO:       return HEIIS::fixup_sparc_lo10;
  case VK_HEIIS_HI:       return HEIIS::fixup_sparc_hi22;
  case VK_HEIIS_H44:      return HEIIS::fixup_sparc_h44;
  case VK_HEIIS_M44:      return HEIIS::fixup_sparc_m44;
  case VK_HEIIS_L44:      return HEIIS::fixup_sparc_l44;
  case VK_HEIIS_HH:       return HEIIS::fixup_sparc_hh;
  case VK_HEIIS_HM:       return HEIIS::fixup_sparc_hm;
  case VK_HEIIS_PC22:     return HEIIS::fixup_sparc_pc22;
  case VK_HEIIS_PC10:     return HEIIS::fixup_sparc_pc10;
  case VK_HEIIS_GOT22:    return HEIIS::fixup_sparc_got22;
  case VK_HEIIS_GOT10:    return HEIIS::fixup_sparc_got10;
  case VK_HEIIS_WPLT30:   return HEIIS::fixup_sparc_wplt30;
  case VK_HEIIS_TLS_GD_HI22:   return HEIIS::fixup_sparc_tls_gd_hi22;
  case VK_HEIIS_TLS_GD_LO10:   return HEIIS::fixup_sparc_tls_gd_lo10;
  case VK_HEIIS_TLS_GD_ADD:    return HEIIS::fixup_sparc_tls_gd_add;
  case VK_HEIIS_TLS_GD_CALL:   return HEIIS::fixup_sparc_tls_gd_call;
  case VK_HEIIS_TLS_LDM_HI22:  return HEIIS::fixup_sparc_tls_ldm_hi22;
  case VK_HEIIS_TLS_LDM_LO10:  return HEIIS::fixup_sparc_tls_ldm_lo10;
  case VK_HEIIS_TLS_LDM_ADD:   return HEIIS::fixup_sparc_tls_ldm_add;
  case VK_HEIIS_TLS_LDM_CALL:  return HEIIS::fixup_sparc_tls_ldm_call;
  case VK_HEIIS_TLS_LDO_HIX22: return HEIIS::fixup_sparc_tls_ldo_hix22;
  case VK_HEIIS_TLS_LDO_LOX10: return HEIIS::fixup_sparc_tls_ldo_lox10;
  case VK_HEIIS_TLS_LDO_ADD:   return HEIIS::fixup_sparc_tls_ldo_add;
  case VK_HEIIS_TLS_IE_HI22:   return HEIIS::fixup_sparc_tls_ie_hi22;
  case VK_HEIIS_TLS_IE_LO10:   return HEIIS::fixup_sparc_tls_ie_lo10;
  case VK_HEIIS_TLS_IE_LD:     return HEIIS::fixup_sparc_tls_ie_ld;
  case VK_HEIIS_TLS_IE_LDX:    return HEIIS::fixup_sparc_tls_ie_ldx;
  case VK_HEIIS_TLS_IE_ADD:    return HEIIS::fixup_sparc_tls_ie_add;
  case VK_HEIIS_TLS_LE_HIX22:  return HEIIS::fixup_sparc_tls_le_hix22;
  case VK_HEIIS_TLS_LE_LOX10:  return HEIIS::fixup_sparc_tls_le_lox10;
  }
}

bool
HEIISMCExpr::evaluateAsRelocatableImpl(MCValue &Res,
                                       const MCAsmLayout *Layout,
                                       const MCFixup *Fixup) const {
  return getSubExpr()->evaluateAsRelocatable(Res, Layout, Fixup);
}

static void fixELFSymbolsInTLSFixupsImpl(const MCExpr *Expr, MCAssembler &Asm) {
  switch (Expr->getKind()) {
  case MCExpr::Target:
    llvm_unreachable("Can't handle nested target expr!");
    break;

  case MCExpr::Constant:
    break;

  case MCExpr::Binary: {
    const MCBinaryExpr *BE = cast<MCBinaryExpr>(Expr);
    fixELFSymbolsInTLSFixupsImpl(BE->getLHS(), Asm);
    fixELFSymbolsInTLSFixupsImpl(BE->getRHS(), Asm);
    break;
  }

  case MCExpr::SymbolRef: {
    const MCSymbolRefExpr &SymRef = *cast<MCSymbolRefExpr>(Expr);
    cast<MCSymbolELF>(SymRef.getSymbol()).setType(ELF::STT_TLS);
    break;
  }

  case MCExpr::Unary:
    fixELFSymbolsInTLSFixupsImpl(cast<MCUnaryExpr>(Expr)->getSubExpr(), Asm);
    break;
  }

}

void HEIISMCExpr::fixELFSymbolsInTLSFixups(MCAssembler &Asm) const {
  switch(getKind()) {
  default: return;
  case VK_HEIIS_TLS_GD_HI22:
  case VK_HEIIS_TLS_GD_LO10:
  case VK_HEIIS_TLS_GD_ADD:
  case VK_HEIIS_TLS_GD_CALL:
  case VK_HEIIS_TLS_LDM_HI22:
  case VK_HEIIS_TLS_LDM_LO10:
  case VK_HEIIS_TLS_LDM_ADD:
  case VK_HEIIS_TLS_LDM_CALL:
  case VK_HEIIS_TLS_LDO_HIX22:
  case VK_HEIIS_TLS_LDO_LOX10:
  case VK_HEIIS_TLS_LDO_ADD:
  case VK_HEIIS_TLS_IE_HI22:
  case VK_HEIIS_TLS_IE_LO10:
  case VK_HEIIS_TLS_IE_LD:
  case VK_HEIIS_TLS_IE_LDX:
  case VK_HEIIS_TLS_IE_ADD:
  case VK_HEIIS_TLS_LE_HIX22:
  case VK_HEIIS_TLS_LE_LOX10: break;
  }
  fixELFSymbolsInTLSFixupsImpl(getSubExpr(), Asm);
}

void HEIISMCExpr::visitUsedExpr(MCStreamer &Streamer) const {
  Streamer.visitUsedExpr(*getSubExpr());
}
