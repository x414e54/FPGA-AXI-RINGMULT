----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2017/04/03 13:09:21
-- Design Name: 
-- Module Name: delay2 - Behavioral
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

entity delay2 is
	generic (
		C_DELAY		      : integer    := 5
	);
	port (
		clk       : in  std_logic;
		i		  : in  std_logic       := '0';
		o		  : out std_logic       := '0'
	);  
end delay2;

architecture Behavioral of delay2 is

    signal a_regs : std_logic_vector(0 to C_DELAY-1)  := (others => '0');
       
begin

    o <= a_regs(0);

    state_proc : process (clk) is
    begin	
        if rising_edge(clk) then
            for j in 0 to C_DELAY-2 loop
				a_regs(j) <= a_regs(j+1);
			end loop;
            a_regs(C_DELAY-1) <= i;
        end if;
    end process state_proc;

end Behavioral;
