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

entity butterfly_dif_22 is
	generic (
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
        prime_s : in std_logic_vector(16-1 downto 0)                        := (others => '0')
	);  
end butterfly_dif_22;

architecture Behavioral of butterfly_dif_22 is

    signal a_reg : unsigned(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal b_reg : unsigned(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal x_reg : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal y_reg : std_logic_vector((2*C_MAX_FFT_PRIME_WIDTH)-1 downto 0) := (others => '0');

begin
       
    red_x : entity work.red
        generic map (
       	    C_MAX_MODULUS_WIDTH => C_MAX_FFT_PRIME_WIDTH,
       		C_MAX_INPUT_WIDTH   => 2 * C_MAX_FFT_PRIME_WIDTH
        )
       	port map (
            clk       => clk,
            modulus   => prime,
            modulus_r => prime_r,
            modulus_s => prime_s,
            value     => x_reg,
            remainder => x
        );
        
    red_y : entity work.red
        generic map (
            C_MAX_MODULUS_WIDTH => C_MAX_FFT_PRIME_WIDTH,
            C_MAX_INPUT_WIDTH   => 2 * C_MAX_FFT_PRIME_WIDTH
         )
        port map (
            clk       => clk,
            modulus   => prime,
            modulus_r => prime_r,
            modulus_s => prime_s,
            value     => y_reg,
            remainder => y
        );
       	   
    state_proc : process (clk) is
    begin	
        if rising_edge(clk) then
            a_reg <= unsigned(a);
            b_reg <= unsigned(b);
            
            x_reg <= std_logic_vector(a_reg + b_reg);
            y_reg <= std_logic_vector(a_reg - b_reg);
        end if;
    end process state_proc;

end Behavioral;
