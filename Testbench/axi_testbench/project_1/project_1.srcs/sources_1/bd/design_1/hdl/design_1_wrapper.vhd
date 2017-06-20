--Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2017.1 (win64) Build 1846317 Fri Apr 14 18:55:03 MDT 2017
--Date        : Tue Jun 20 17:24:38 2017
--Host        : aritalab-XPS running 64-bit major release  (build 9200)
--Command     : generate_target design_1_wrapper.bd
--Design      : design_1_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity design_1_wrapper is
  port (
    diff_clock_rtl_0_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 );
    diff_clock_rtl_0_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    pcie_7x_mgt_rtl_rxn : in STD_LOGIC_VECTOR ( 3 downto 0 );
    pcie_7x_mgt_rtl_rxp : in STD_LOGIC_VECTOR ( 3 downto 0 );
    pcie_7x_mgt_rtl_txn : out STD_LOGIC_VECTOR ( 3 downto 0 );
    pcie_7x_mgt_rtl_txp : out STD_LOGIC_VECTOR ( 3 downto 0 );
    reset_rtl : in STD_LOGIC
  );
end design_1_wrapper;

architecture STRUCTURE of design_1_wrapper is
  component design_1 is
  port (
    pcie_7x_mgt_rtl_rxn : in STD_LOGIC_VECTOR ( 3 downto 0 );
    pcie_7x_mgt_rtl_rxp : in STD_LOGIC_VECTOR ( 3 downto 0 );
    pcie_7x_mgt_rtl_txn : out STD_LOGIC_VECTOR ( 3 downto 0 );
    pcie_7x_mgt_rtl_txp : out STD_LOGIC_VECTOR ( 3 downto 0 );
    reset_rtl : in STD_LOGIC;
    diff_clock_rtl_0_clk_p : in STD_LOGIC_VECTOR ( 0 to 0 );
    diff_clock_rtl_0_clk_n : in STD_LOGIC_VECTOR ( 0 to 0 )
  );
  end component design_1;
begin
design_1_i: component design_1
     port map (
      diff_clock_rtl_0_clk_n(0) => diff_clock_rtl_0_clk_n(0),
      diff_clock_rtl_0_clk_p(0) => diff_clock_rtl_0_clk_p(0),
      pcie_7x_mgt_rtl_rxn(3 downto 0) => pcie_7x_mgt_rtl_rxn(3 downto 0),
      pcie_7x_mgt_rtl_rxp(3 downto 0) => pcie_7x_mgt_rtl_rxp(3 downto 0),
      pcie_7x_mgt_rtl_txn(3 downto 0) => pcie_7x_mgt_rtl_txn(3 downto 0),
      pcie_7x_mgt_rtl_txp(3 downto 0) => pcie_7x_mgt_rtl_txp(3 downto 0),
      reset_rtl => reset_rtl
    );
end STRUCTURE;
