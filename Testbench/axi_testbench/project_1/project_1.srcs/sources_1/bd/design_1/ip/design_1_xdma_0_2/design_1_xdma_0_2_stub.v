// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.1 (win64) Build 1846317 Fri Apr 14 18:55:03 MDT 2017
// Date        : Tue Jun 20 17:13:44 2017
// Host        : aritalab-XPS running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/source/FPGA-tests/Testbench/axi_testbench/project_1/project_1.srcs/sources_1/bd/design_1/ip/design_1_xdma_0_2/design_1_xdma_0_2_stub.v
// Design      : design_1_xdma_0_2
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* X_CORE_INFO = "design_1_xdma_0_2_core_top,Vivado 2017.1" *)
module design_1_xdma_0_2(sys_clk, sys_rst_n, user_lnk_up, pci_exp_txp, 
  pci_exp_txn, pci_exp_rxp, pci_exp_rxn, axi_aclk, axi_aresetn, usr_irq_req, usr_irq_ack, 
  msi_enable, msi_vector_width, s_axis_c2h_tdata_0, s_axis_c2h_tlast_0, 
  s_axis_c2h_tvalid_0, s_axis_c2h_tready_0, s_axis_c2h_tkeep_0, m_axis_h2c_tdata_0, 
  m_axis_h2c_tlast_0, m_axis_h2c_tvalid_0, m_axis_h2c_tready_0, m_axis_h2c_tkeep_0)
/* synthesis syn_black_box black_box_pad_pin="sys_clk,sys_rst_n,user_lnk_up,pci_exp_txp[3:0],pci_exp_txn[3:0],pci_exp_rxp[3:0],pci_exp_rxn[3:0],axi_aclk,axi_aresetn,usr_irq_req[0:0],usr_irq_ack[0:0],msi_enable,msi_vector_width[2:0],s_axis_c2h_tdata_0[63:0],s_axis_c2h_tlast_0,s_axis_c2h_tvalid_0,s_axis_c2h_tready_0,s_axis_c2h_tkeep_0[7:0],m_axis_h2c_tdata_0[63:0],m_axis_h2c_tlast_0,m_axis_h2c_tvalid_0,m_axis_h2c_tready_0,m_axis_h2c_tkeep_0[7:0]" */;
  input sys_clk;
  input sys_rst_n;
  output user_lnk_up;
  output [3:0]pci_exp_txp;
  output [3:0]pci_exp_txn;
  input [3:0]pci_exp_rxp;
  input [3:0]pci_exp_rxn;
  output axi_aclk;
  output axi_aresetn;
  input [0:0]usr_irq_req;
  output [0:0]usr_irq_ack;
  output msi_enable;
  output [2:0]msi_vector_width;
  input [63:0]s_axis_c2h_tdata_0;
  input s_axis_c2h_tlast_0;
  input s_axis_c2h_tvalid_0;
  output s_axis_c2h_tready_0;
  input [7:0]s_axis_c2h_tkeep_0;
  output [63:0]m_axis_h2c_tdata_0;
  output m_axis_h2c_tlast_0;
  output m_axis_h2c_tvalid_0;
  input m_axis_h2c_tready_0;
  output [7:0]m_axis_h2c_tkeep_0;
endmodule
