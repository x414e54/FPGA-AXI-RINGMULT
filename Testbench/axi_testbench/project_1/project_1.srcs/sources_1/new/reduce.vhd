----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2017/04/03 13:09:21
-- Design Name: 
-- Module Name: reduce - Behavioral
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

entity reduce is
	generic (
		C_MAX_MODULUS_WIDTH : integer    := 64;
		C_MAX_INPUT_WIDTH   : integer    := 64;
	)
	port (
		clk     : in std_logic;
		reset   : in std_logic;
		enabled : in std_logic;
		modulus : in unsigned(C_MAX_MODULUS_WIDTH-1 downto 0)       := (others => '0');
		val     : in unsigned(C_MAX_INPUT_WIDTH-1 downto 0)         := (others => '0');
		rem     : out unsigned(C_MAX_MODULUS_WIDTH-1 downto 0)      := (others => '0');
	);  
end reduce;

architecture Behavioral of reduce is

begin

    state_proc : process (clk) is
    begin	
        if rising_edge(clk) then
		
        end if;
    end process state_proc;

end Behavioral;
