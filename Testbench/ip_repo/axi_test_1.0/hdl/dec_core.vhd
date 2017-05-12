----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/19/2017 02:00:20 PM
-- Design Name: 
-- Module Name: dec_core - Behavioral
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

entity dec_core is
	Generic (C_MAX_DATA_WIDTH    : integer    := 32);
    Port ( clk : in STD_LOGIC;
           a : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
           b : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
           c : out std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0));
end dec_core;

architecture Behavioral of dec_core is

begin


end Behavioral;
