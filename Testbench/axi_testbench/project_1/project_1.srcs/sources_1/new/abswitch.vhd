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

entity abswitch is
	generic (
		C_MAX_INPUT_WIDTH   : integer    := 64;
        C_DELAY		        : integer    := 5
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

signal delay_a_reg : std_logic_vector(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');

begin

    delay_a : entity work.delay
        generic map (
    		C_MAX_INPUT_WIDTH => C_MAX_INPUT_WIDTH,
    		C_DELAY		      => C_DELAY
        )
        port map (
            clk       => clk,
            i         => in_a,
            o         => delay_a_reg
        );
        
    state_proc : process (clk) is
    begin	
        if rising_edge(clk) then
		    if (switch = '0') then
				out_ab <= delay_a_reg;
			else 
				out_ab <= in_b;
			end if;
        end if;
    end process state_proc;

end Behavioral;
