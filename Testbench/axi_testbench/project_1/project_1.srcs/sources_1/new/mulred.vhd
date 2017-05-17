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

entity mulred is
	generic (
	    C_LENGTH_WIDTH      : integer    := 16;
		C_MAX_MODULUS_WIDTH : integer    := 64
	);
	port (
		clk       : in std_logic;
		modulus   : in std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0)       := (others => '0');
		modulus_r : in std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0)       := (others => '0');
        modulus_s : in std_logic_vector(C_LENGTH_WIDTH-1 downto 0)            := (others => '0');
        a         : in std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0)       := (others => '0');
        b         : in std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0)       := (others => '0');
		c         : out std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0)      := (others => '0')
	);  
end mulred;

architecture Behavioral of mulred is

    signal c_reg : std_logic_vector(2*C_MAX_MODULUS_WIDTH-1 downto 0) := (others => '0');

begin
    red_x : entity work.red
        generic map (
            C_LENGTH_WIDTH      => C_LENGTH_WIDTH,
            C_MAX_MODULUS_WIDTH => C_MAX_MODULUS_WIDTH,
            C_MAX_INPUT_WIDTH   => 2*C_MAX_MODULUS_WIDTH
        )
        port map (
            clk       => clk,
            modulus   => modulus,
            modulus_r => modulus_r,
            modulus_s => modulus_s,
            value     => c_reg,
            remainder => c
        );
    
    state_proc : process (clk) is
    begin	
        if rising_edge(clk) then
            c_reg <= std_logic_vector(unsigned(a) * unsigned(b)); 
        end if;
    end process state_proc;

end Behavioral;
