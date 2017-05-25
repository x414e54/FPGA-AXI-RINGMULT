----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2017/04/03 13:09:21
-- Design Name: 
-- Module Name: delay - Behavioral
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
    
    type REGISTER_TYPE is array(natural range <>) of std_logic_vector(C_MAX_INPUT_WIDTH-1 downto 0);
        
    signal a_regs : REGISTER_TYPE(0 to C_DELAY-1)  := (others => (others => '0'));
       
begin

    delay_zero: if C_DELAY = 0 generate
        o <= i;
    end generate;
        
    delay_else: if C_DELAY > 1 generate
        o <= a_regs(0);
        
        state_proc : process (clk) is
        begin	
            if rising_edge(clk) then
                if C_DELAY > 1 then
                    for j in 0 to C_DELAY-2 loop
				        a_regs(j) <= a_regs(j+1);
			         end loop;
                end if;
                
                a_regs(C_DELAY-1) <= i;
            end if;
        end process state_proc;
    end generate;

end Behavioral;
