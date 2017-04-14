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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package abswitch_delay_pkg is
	type abswitch_io is array(natural range <>) of std_logic_vector(64-1 downto 0);
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.abswitch_delay_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity abswitch_delay is
	generic (
        C_INPUT_LENGTH      : integer    := 2;
		C_MAX_INPUT_WIDTH   : integer    := 64
	);
	port (
		clk     : in std_logic;
		in_ab   : in abswitch_io(C_INPUT_LENGTH-1 downto 0)     := (others => (others => '0'));
		out_a   : out abswitch_io(C_INPUT_LENGTH-1 downto 0)    := (others => (others => '0'));
		out_b   : out abswitch_io(C_INPUT_LENGTH-1 downto 0)    := (others => (others => '0'))
	);  
end abswitch_delay;

architecture Behavioral of abswitch_delay is
signal a_tmp_regs : abswitch_io(C_INPUT_LENGTH-1 downto 0) := (others => '0');

signal switch : std_logic_vector := '0';

begin
       	   
    state_proc : process (clk) is
    begin	
        if rising_edge(clk) then
			out_a <= a_tmp_regs;

		    if (switch = '0') then
				switch <= '1';
				a_tmp_regs <= in_ab;
			else 
				switch <= '0';
				out_b <= in_ab;
			end if;
        end if;
    end process state_proc;

end Behavioral;
