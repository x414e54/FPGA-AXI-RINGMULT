----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2017/04/03 13:09:21
-- Design Name: 
-- Module Name: butterfly_dif_22 - Behavioral
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

entity butterfly_dif_22 is
	generic (
	    C_LENGTH_WIDTH        : integer    := 16;
		C_MAX_FFT_PRIME_WIDTH : integer    := 64
	);
	port (
		clk     : in std_logic;
		a       : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
		b       : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
		x       : out std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)    := (others => '0');
		y       : out std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)    := (others => '0');
		prime   : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        prime_r : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        prime_s : in std_logic_vector(C_LENGTH_WIDTH-1 downto 0)            := (others => '0')
	);  
end butterfly_dif_22;

architecture Behavioral of butterfly_dif_22 is

    signal a_reg : unsigned(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal b_reg : unsigned(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    
    signal x_reg : unsigned(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    
begin
              	   
    state_proc : process (clk) is
    begin	
        if rising_edge(clk) then
            a_reg <= unsigned(a);
            b_reg <= unsigned(b);
            x_reg <= unsigned(a) + unsigned(b);
            
            if (x_reg >= unsigned(prime)) then 
                x <= std_logic_vector(resize(x_reg - unsigned(prime), C_MAX_FFT_PRIME_WIDTH));
            end if;
            
            if (a_reg >= b_reg) then
                y <= std_logic_vector(resize(a_reg - b_reg, C_MAX_FFT_PRIME_WIDTH));
            else
                y <= std_logic_vector(resize(unsigned(prime) - (b_reg - a_reg), C_MAX_FFT_PRIME_WIDTH)); 
            end if;  
        end if;
    end process state_proc;

end Behavioral;
