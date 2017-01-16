----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/11/2017 08:15:57 PM
-- Design Name: 
-- Module Name: testmult - Behavioral
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

entity testmult is
	generic (
        C_MAX_DATA_WIDTH    : integer    := 32;
        C_REGISTER_WIDTH    : integer    := 32
	);
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           start : in STD_LOGIC;
           mode : in STD_LOGIC_VECTOR (C_REGISTER_WIDTH-1 downto 0);
           valid_a : in STD_LOGIC;
           a : in STD_LOGIC_VECTOR (C_MAX_DATA_WIDTH-1 downto 0);
           valid_b : in STD_LOGIC;
           b : in STD_LOGIC_VECTOR (C_MAX_DATA_WIDTH-1 downto 0);
           valid : out STD_LOGIC;
           c : out STD_LOGIC_VECTOR (C_MAX_DATA_WIDTH-1 downto 0));
end testmult;

architecture Behavioral of testmult is

begin


end Behavioral;
