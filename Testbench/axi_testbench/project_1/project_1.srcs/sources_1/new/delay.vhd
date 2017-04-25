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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity delay is
	generic (
		C_MAX_INPUT_WIDTH : integer    := 64;
		C_DELAY		      : integer    := 5
	);
	port (
		clk       : in  std_logic;
		i		  : in  std_logic_vector(C_MAX_INPUT_WIDTH-1 downto 0)       := (others => '0');
		o		  : out std_logic_vector(C_MAX_INPUT_WIDTH-1 downto 0)       := (others => '0')
	);  
end delay;

architecture Behavioral of delay is
signal a_reg : unsigned(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');
begin
    state_proc : process (clk) is
    begin	
        if rising_edge(clk) then
            for i in 0 to C_DELAY-2 loop
				a_reg(i) <= a_reg(i+1);
			end loop;
        end if;
    end process state_proc;

end Behavioral;
