--Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2017.1 (win64) Build 1846317 Fri Apr 14 18:55:03 MDT 2017
--Date        : Tue Jun 20 17:24:38 2017
--Host        : aritalab-XPS running 64-bit major release  (build 9200)
--Command     : generate_target design_1.bd
--Design      : design_1
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity design_1 is
  port (
    diff_clock_rtl_0_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    diff_clock_rtl_0_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    pcie_7x_mgt_rtl_rxn : in STD_LOGIC_VECTOR ( 3 downto 0 );
    pcie_7x_mgt_rtl_rxp : in STD_LOGIC_VECTOR ( 3 downto 0 );
    pcie_7x_mgt_rtl_txn : out STD_LOGIC_VECTOR ( 3 downto 0 );
    pcie_7x_mgt_rtl_txp : out STD_LOGIC_VECTOR ( 3 downto 0 );
    reset_rtl : in STD_LOGIC
  );
  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of design_1 : entity is "design_1,IP_Integrator,{x_ipVendor=xilinx.com,x_ipLibrary=BlockDiagram,x_ipName=design_1,x_ipVersion=1.00.a,x_ipLanguage=VHDL,numBlks=3,numReposBlks=3,numNonXlnxBlks=0,numHierBlks=0,maxHierDepth=0,numSysgenBlks=0,numHlsBlks=0,numHdlrefBlks=0,numPkgbdBlks=0,bdsource=USER,da_board_cnt=14,da_clkrst_cnt=5,da_xdma_cnt=2,synth_mode=OOC_per_IP}";
  attribute HW_HANDOFF : string;
  attribute HW_HANDOFF of design_1 : entity is "design_1.hwdef";
end design_1;

architecture STRUCTURE of design_1 is
  component design_1_xdma_0_2 is
  port (
    sys_clk : in STD_LOGIC;
    sys_rst_n : in STD_LOGIC;
    user_lnk_up : out STD_LOGIC;
    pci_exp_txp : out STD_LOGIC_VECTOR ( 3 downto 0 );
    pci_exp_txn : out STD_LOGIC_VECTOR ( 3 downto 0 );
    pci_exp_rxp : in STD_LOGIC_VECTOR ( 3 downto 0 );
    pci_exp_rxn : in STD_LOGIC_VECTOR ( 3 downto 0 );
    axi_aclk : out STD_LOGIC;
    axi_aresetn : out STD_LOGIC;
    usr_irq_req : in STD_LOGIC_VECTOR ( 0 to 0 );
    usr_irq_ack : out STD_LOGIC_VECTOR ( 0 to 0 );
    msi_enable : out STD_LOGIC;
    msi_vector_width : out STD_LOGIC_VECTOR ( 2 downto 0 );
    s_axis_c2h_tdata_0 : in STD_LOGIC_VECTOR ( 63 downto 0 );
    s_axis_c2h_tlast_0 : in STD_LOGIC;
    s_axis_c2h_tvalid_0 : in STD_LOGIC;
    s_axis_c2h_tready_0 : out STD_LOGIC;
    s_axis_c2h_tkeep_0 : in STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axis_h2c_tdata_0 : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axis_h2c_tlast_0 : out STD_LOGIC;
    m_axis_h2c_tvalid_0 : out STD_LOGIC;
    m_axis_h2c_tready_0 : in STD_LOGIC;
    m_axis_h2c_tkeep_0 : out STD_LOGIC_VECTOR ( 7 downto 0 )
  );
  end component design_1_xdma_0_2;
  component design_1_axis_data_fifo_0_1 is
  port (
    s_axis_aresetn : in STD_LOGIC;
    s_axis_aclk : in STD_LOGIC;
    s_axis_tvalid : in STD_LOGIC;
    s_axis_tready : out STD_LOGIC;
    s_axis_tdata : in STD_LOGIC_VECTOR ( 63 downto 0 );
    s_axis_tkeep : in STD_LOGIC_VECTOR ( 7 downto 0 );
    s_axis_tlast : in STD_LOGIC;
    m_axis_tvalid : out STD_LOGIC;
    m_axis_tready : in STD_LOGIC;
    m_axis_tdata : out STD_LOGIC_VECTOR ( 63 downto 0 );
    m_axis_tkeep : out STD_LOGIC_VECTOR ( 7 downto 0 );
    m_axis_tlast : out STD_LOGIC;
    axis_data_count : out STD_LOGIC_VECTOR ( 31 downto 0 );
    axis_wr_data_count : out STD_LOGIC_VECTOR ( 31 downto 0 );
    axis_rd_data_count : out STD_LOGIC_VECTOR ( 31 downto 0 )
  );
  end component design_1_axis_data_fifo_0_1;
  component design_1_util_ds_buf_1 is
  port (
    IBUF_DS_P : in STD_LOGIC_VECTOR ( 0 to 0 );
    IBUF_DS_N : in STD_LOGIC_VECTOR ( 0 to 0 );
    IBUF_OUT : out STD_LOGIC_VECTOR ( 0 to 0 );
    IBUF_DS_ODIV2 : out STD_LOGIC_VECTOR ( 0 to 0 )
  );
  end component design_1_util_ds_buf_1;
  signal axis_data_fifo_0_M_AXIS_TDATA : STD_LOGIC_VECTOR ( 63 downto 0 );
  signal axis_data_fifo_0_M_AXIS_TKEEP : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal axis_data_fifo_0_M_AXIS_TLAST : STD_LOGIC;
  signal axis_data_fifo_0_M_AXIS_TREADY : STD_LOGIC;
  signal axis_data_fifo_0_M_AXIS_TVALID : STD_LOGIC;
  signal diff_clock_rtl_0_1_CLK_N : STD_LOGIC_VECTOR ( 0 to 0 );
  signal diff_clock_rtl_0_1_CLK_P : STD_LOGIC_VECTOR ( 0 to 0 );
  signal reset_rtl_1 : STD_LOGIC;
  signal util_ds_buf_IBUF_OUT : STD_LOGIC_VECTOR ( 0 to 0 );
  signal xdma_0_M_AXIS_H2C_0_TDATA : STD_LOGIC_VECTOR ( 63 downto 0 );
  signal xdma_0_M_AXIS_H2C_0_TKEEP : STD_LOGIC_VECTOR ( 7 downto 0 );
  signal xdma_0_M_AXIS_H2C_0_TLAST : STD_LOGIC;
  signal xdma_0_M_AXIS_H2C_0_TREADY : STD_LOGIC;
  signal xdma_0_M_AXIS_H2C_0_TVALID : STD_LOGIC;
  signal xdma_0_axi_aclk : STD_LOGIC;
  signal xdma_0_axi_aresetn : STD_LOGIC;
  signal xdma_0_pcie_mgt_rxn : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal xdma_0_pcie_mgt_rxp : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal xdma_0_pcie_mgt_txn : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal xdma_0_pcie_mgt_txp : STD_LOGIC_VECTOR ( 3 downto 0 );
  signal NLW_axis_data_fifo_0_axis_data_count_UNCONNECTED : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal NLW_axis_data_fifo_0_axis_rd_data_count_UNCONNECTED : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal NLW_axis_data_fifo_0_axis_wr_data_count_UNCONNECTED : STD_LOGIC_VECTOR ( 31 downto 0 );
  signal NLW_util_ds_buf_IBUF_DS_ODIV2_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
  signal NLW_xdma_0_msi_enable_UNCONNECTED : STD_LOGIC;
  signal NLW_xdma_0_user_lnk_up_UNCONNECTED : STD_LOGIC;
  signal NLW_xdma_0_msi_vector_width_UNCONNECTED : STD_LOGIC_VECTOR ( 2 downto 0 );
  signal NLW_xdma_0_usr_irq_ack_UNCONNECTED : STD_LOGIC_VECTOR ( 0 to 0 );
begin
  diff_clock_rtl_0_1_CLK_N(0) <= diff_clock_rtl_0_clk_n(0);
  diff_clock_rtl_0_1_CLK_P(0) <= diff_clock_rtl_0_clk_p(0);
  pcie_7x_mgt_rtl_txn(3 downto 0) <= xdma_0_pcie_mgt_txn(3 downto 0);
  pcie_7x_mgt_rtl_txp(3 downto 0) <= xdma_0_pcie_mgt_txp(3 downto 0);
  reset_rtl_1 <= reset_rtl;
  xdma_0_pcie_mgt_rxn(3 downto 0) <= pcie_7x_mgt_rtl_rxn(3 downto 0);
  xdma_0_pcie_mgt_rxp(3 downto 0) <= pcie_7x_mgt_rtl_rxp(3 downto 0);
axis_data_fifo_0: component design_1_axis_data_fifo_0_1
     port map (
      axis_data_count(31 downto 0) => NLW_axis_data_fifo_0_axis_data_count_UNCONNECTED(31 downto 0),
      axis_rd_data_count(31 downto 0) => NLW_axis_data_fifo_0_axis_rd_data_count_UNCONNECTED(31 downto 0),
      axis_wr_data_count(31 downto 0) => NLW_axis_data_fifo_0_axis_wr_data_count_UNCONNECTED(31 downto 0),
      m_axis_tdata(63 downto 0) => axis_data_fifo_0_M_AXIS_TDATA(63 downto 0),
      m_axis_tkeep(7 downto 0) => axis_data_fifo_0_M_AXIS_TKEEP(7 downto 0),
      m_axis_tlast => axis_data_fifo_0_M_AXIS_TLAST,
      m_axis_tready => axis_data_fifo_0_M_AXIS_TREADY,
      m_axis_tvalid => axis_data_fifo_0_M_AXIS_TVALID,
      s_axis_aclk => xdma_0_axi_aclk,
      s_axis_aresetn => xdma_0_axi_aresetn,
      s_axis_tdata(63 downto 0) => xdma_0_M_AXIS_H2C_0_TDATA(63 downto 0),
      s_axis_tkeep(7 downto 0) => xdma_0_M_AXIS_H2C_0_TKEEP(7 downto 0),
      s_axis_tlast => xdma_0_M_AXIS_H2C_0_TLAST,
      s_axis_tready => xdma_0_M_AXIS_H2C_0_TREADY,
      s_axis_tvalid => xdma_0_M_AXIS_H2C_0_TVALID
    );
util_ds_buf: component design_1_util_ds_buf_1
     port map (
      IBUF_DS_N(0) => diff_clock_rtl_0_1_CLK_N(0),
      IBUF_DS_ODIV2(0) => NLW_util_ds_buf_IBUF_DS_ODIV2_UNCONNECTED(0),
      IBUF_DS_P(0) => diff_clock_rtl_0_1_CLK_P(0),
      IBUF_OUT(0) => util_ds_buf_IBUF_OUT(0)
    );
xdma_0: component design_1_xdma_0_2
     port map (
      axi_aclk => xdma_0_axi_aclk,
      axi_aresetn => xdma_0_axi_aresetn,
      m_axis_h2c_tdata_0(63 downto 0) => xdma_0_M_AXIS_H2C_0_TDATA(63 downto 0),
      m_axis_h2c_tkeep_0(7 downto 0) => xdma_0_M_AXIS_H2C_0_TKEEP(7 downto 0),
      m_axis_h2c_tlast_0 => xdma_0_M_AXIS_H2C_0_TLAST,
      m_axis_h2c_tready_0 => xdma_0_M_AXIS_H2C_0_TREADY,
      m_axis_h2c_tvalid_0 => xdma_0_M_AXIS_H2C_0_TVALID,
      msi_enable => NLW_xdma_0_msi_enable_UNCONNECTED,
      msi_vector_width(2 downto 0) => NLW_xdma_0_msi_vector_width_UNCONNECTED(2 downto 0),
      pci_exp_rxn(3 downto 0) => xdma_0_pcie_mgt_rxn(3 downto 0),
      pci_exp_rxp(3 downto 0) => xdma_0_pcie_mgt_rxp(3 downto 0),
      pci_exp_txn(3 downto 0) => xdma_0_pcie_mgt_txn(3 downto 0),
      pci_exp_txp(3 downto 0) => xdma_0_pcie_mgt_txp(3 downto 0),
      s_axis_c2h_tdata_0(63 downto 0) => axis_data_fifo_0_M_AXIS_TDATA(63 downto 0),
      s_axis_c2h_tkeep_0(7 downto 0) => axis_data_fifo_0_M_AXIS_TKEEP(7 downto 0),
      s_axis_c2h_tlast_0 => axis_data_fifo_0_M_AXIS_TLAST,
      s_axis_c2h_tready_0 => axis_data_fifo_0_M_AXIS_TREADY,
      s_axis_c2h_tvalid_0 => axis_data_fifo_0_M_AXIS_TVALID,
      sys_clk => util_ds_buf_IBUF_OUT(0),
      sys_rst_n => reset_rtl_1,
      user_lnk_up => NLW_xdma_0_user_lnk_up_UNCONNECTED,
      usr_irq_ack(0) => NLW_xdma_0_usr_irq_ack_UNCONNECTED(0),
      usr_irq_req(0) => '0'
    );
end STRUCTURE;
