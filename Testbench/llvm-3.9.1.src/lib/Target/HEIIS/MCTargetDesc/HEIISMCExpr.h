//====- HEIISMCExpr.h - HEIIS specific MC expression classes --*- C++ -*-=====//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file describes HEIIS-specific MCExprs, used for modifiers like
// "%hi" or "%lo" etc.,
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_SPARC_MCTARGETDESC_SPARCMCEXPR_H
#define LLVM_LIB_TARGET_SPARC_MCTARGETDESC_SPARCMCEXPR_H

#include "HEIISFixupKinds.h"
#include "llvm/MC/MCExpr.h"

namespace llvm {

class StringRef;
class HEIISMCExpr : public MCTargetExpr {
public:
  enum VariantKind {
    VK_HEIIS_None,
    VK_HEIIS_LO,
    VK_HEIIS_HI,
    VK_HEIIS_H44,
    VK_HEIIS_M44,
    VK_HEIIS_L44,
    VK_HEIIS_HH,
    VK_HEIIS_HM,
    VK_HEIIS_PC22,
    VK_HEIIS_PC10,
    VK_HEIIS_GOT22,
    VK_HEIIS_GOT10,
    VK_HEIIS_WPLT30,
    VK_HEIIS_R_DISP32,
    VK_HEIIS_TLS_GD_HI22,
    VK_HEIIS_TLS_GD_LO10,
    VK_HEIIS_TLS_GD_ADD,
    VK_HEIIS_TLS_GD_CALL,
    VK_HEIIS_TLS_LDM_HI22,
    VK_HEIIS_TLS_LDM_LO10,
    VK_HEIIS_TLS_LDM_ADD,
    VK_HEIIS_TLS_LDM_CALL,
    VK_HEIIS_TLS_LDO_HIX22,
    VK_HEIIS_TLS_LDO_LOX10,
    VK_HEIIS_TLS_LDO_ADD,
    VK_HEIIS_TLS_IE_HI22,
    VK_HEIIS_TLS_IE_LO10,
    VK_HEIIS_TLS_IE_LD,
    VK_HEIIS_TLS_IE_LDX,
    VK_HEIIS_TLS_IE_ADD,
    VK_HEIIS_TLS_LE_HIX22,
    VK_HEIIS_TLS_LE_LOX10
  };

private:
  const VariantKind Kind;
  const MCExpr *Expr;

  explicit HEIISMCExpr(VariantKind Kind, const MCExpr *Expr)
      : Kind(Kind), Expr(Expr) {}

public:
  /// @name Construction
  /// @{

  static const HEIISMCExpr *create(VariantKind Kind, const MCExpr *Expr,
                                 MCContext &Ctx);
  /// @}
  /// @name Accessors
  /// @{

  /// getOpcode - Get the kind of this expression.
  VariantKind getKind() const { return Kind; }

  /// getSubExpr - Get the child of this expression.
  const MCExpr *getSubExpr() const { return Expr; }

  /// getFixupKind - Get the fixup kind of this expression.
  HEIIS::Fixups getFixupKind() const { return getFixupKind(Kind); }

  /// @}
  void printImpl(raw_ostream &OS, const MCAsmInfo *MAI) const override;
  bool evaluateAsRelocatableImpl(MCValue &Res,
                                 const MCAsmLayout *Layout,
                                 const MCFixup *Fixup) const override;
  void visitUsedExpr(MCStreamer &Streamer) const override;
  MCFragment *findAssociatedFragment() const override {
    return getSubExpr()->findAssociatedFragment();
  }

  void fixELFSymbolsInTLSFixups(MCAssembler &Asm) const override;

  static bool classof(const MCExpr *E) {
    return E->getKind() == MCExpr::Target;
  }

  static bool classof(const HEIISMCExpr *) { return true; }

  static VariantKind parseVariantKind(StringRef name);
  static bool printVariantKind(raw_ostream &OS, VariantKind Kind);
  static HEIIS::Fixups getFixupKind(VariantKind Kind);
};

} // end namespace llvm.

#endif
