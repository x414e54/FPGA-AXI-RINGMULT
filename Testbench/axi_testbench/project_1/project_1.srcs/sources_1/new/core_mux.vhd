----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/19/2017 02:01:53 PM
-- Design Name: 
-- Module Name: core_mux - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity core_mux is
	Generic (C_MAX_DATA_WIDTH    : integer    := 32);
    Port ( clk : in STD_LOGIC;
           a : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
           b : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
           q : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
           c : out std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
           mode : in std_logic_vector(4-1 downto 0));
end core_mux;

architecture Behavioral of core_mux is

begin

    add_core_inst : entity work.add_core
        generic map (
            C_MAX_DATA_WIDTH => C_MAX_DATA_WIDTH
        )
        port map (
            clk => clk,
            a => a,
            b => b,
            q => q,
            c => c
        );  

    sub_core_inst : entity work.sub_core
        generic map (
            C_MAX_DATA_WIDTH => C_MAX_DATA_WIDTH
        )
        port map (
            clk => clk,
            a => a,
            b => b,
            q => q,
            c => c
        );  

end Behavioral;
