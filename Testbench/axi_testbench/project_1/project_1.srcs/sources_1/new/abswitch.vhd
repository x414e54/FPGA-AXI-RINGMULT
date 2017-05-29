----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2017/04/03 13:09:21
-- Design Name: 
-- Module Name: abswitch - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity abswitch is
	generic (
		C_MAX_INPUT_WIDTH   : integer    := 64
	);
	port (
		clk      : in std_logic;
		switch   : in std_logic                                           := '0';
    	in_a     : in std_logic_vector(C_MAX_INPUT_WIDTH-1 downto 0)     := (others => '0');
		in_b     : in std_logic_vector(C_MAX_INPUT_WIDTH-1 downto 0)     := (others => '0');
		out_ab   : out std_logic_vector(C_MAX_INPUT_WIDTH-1 downto 0)    := (others => '0')
	);  
end abswitch;

architecture Behavioral of abswitch is

begin
    
    out_ab <= in_b when switch = '1' else in_a;
    
end Behavioral;
