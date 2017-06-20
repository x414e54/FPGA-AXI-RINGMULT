// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.1 (win64) Build 1846317 Fri Apr 14 18:55:03 MDT 2017
// Date        : Mon May 29 16:37:47 2017
// Host        : aritalab-XPS running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/source/FPGA-tests/Testbench/axi_testbench/project_1/project_1.srcs/sources_1/ip/mult_gen_0/mult_gen_0_stub.v
// Design      : mult_gen_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "mult_gen_v12_0_12,Vivado 2017.1" *)
module mult_gen_0(CLK, A, B, P)
/* synthesis syn_black_box black_box_pad_pin="CLK,A[63:0],B[63:0],P[127:0]" */;
  input CLK;
  input [63:0]A;
  input [63:0]B;
  output [127:0]P;
endmodule
