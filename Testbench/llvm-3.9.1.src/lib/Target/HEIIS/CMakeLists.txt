set(LLVM_TARGET_DEFINITIONS HEIIS.td)

tablegen(LLVM HEIISGenRegisterInfo.inc -gen-register-info)
tablegen(LLVM HEIISGenInstrInfo.inc -gen-instr-info)
tablegen(LLVM HEIISGenDisassemblerTables.inc -gen-disassembler)
tablegen(LLVM HEIISGenMCCodeEmitter.inc -gen-emitter)
tablegen(LLVM HEIISGenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM HEIISGenAsmMatcher.inc -gen-asm-matcher)
tablegen(LLVM HEIISGenDAGISel.inc -gen-dag-isel)
tablegen(LLVM HEIISGenSubtargetInfo.inc -gen-subtarget)
tablegen(LLVM HEIISGenCallingConv.inc -gen-callingconv)
add_public_tablegen_target(HEIISCommonTableGen)

add_llvm_target(HEIISCodeGen
  DelaySlotFiller.cpp
  LeonPasses.cpp
  HEIISAsmPrinter.cpp
  HEIISInstrInfo.cpp
  HEIISISelDAGToDAG.cpp
  HEIISISelLowering.cpp
  HEIISFrameLowering.cpp
  HEIISMachineFunctionInfo.cpp
  HEIISRegisterInfo.cpp
  HEIISSubtarget.cpp
  HEIISTargetMachine.cpp
  HEIISMCInstLower.cpp
  HEIISTargetObjectFile.cpp
  )

add_subdirectory(TargetInfo)
add_subdirectory(MCTargetDesc)
add_subdirectory(InstPrinter)
add_subdirectory(AsmParser)
add_subdirectory(Disassembler)
