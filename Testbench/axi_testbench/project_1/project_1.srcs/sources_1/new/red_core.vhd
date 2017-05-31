----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2017/04/03 13:09:21
-- Design Name: 
-- Module Name: red_core - Behavioral
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

entity red_core is
	generic (
	    C_LENGTH_WIDTH      : integer    := 16;
		C_MAX_MODULUS_WIDTH : integer    := 64;
		C_MAX_INPUT_WIDTH   : integer    := 128
	);
	port (
		clk       : in std_logic;
		modulus   : in std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0)       := (others => '0');
		modulus_r : in std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0)       := (others => '0');
        modulus_s : in std_logic_vector(C_LENGTH_WIDTH-1 downto 0)            := (others => '0');
        value     : in std_logic_vector(C_MAX_INPUT_WIDTH-1 downto 0)         := (others => '0');
		remainder : out std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0)      := (others => '0')
	);  
end red_core;

architecture Behavioral of red_core is

    constant C_MODULUS_WIDTH : integer := C_MAX_MODULUS_WIDTH - 3; -- use modulus_s instead of hardcoding

    signal value_delay : unsigned(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');
        
    signal mul_0_in : unsigned(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');
    signal mul_0_out : unsigned(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');
    signal mul_1_in : unsigned(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');
    signal mul_1_out : unsigned(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');
    
    mul_0 : entity work.mult_gen_0
        generic map (
        )
        port map (
            clk => clk,
            a   => mul_0_in,
            b   => modulus_r,
            p   => mul_0_out
        );
                 
    mul_1 : entity work.mult_gen_0
        generic map (
        )
        port map (
            clk => clk,
            a   => b_reg,
            b   => modulus,
            p   => mul_1_out
        );
           
   a_delay : entity work.delay
       generic map (
           C_DELAY => 2*18
       )
       port map (
           clk       => clk,
           i         => value,
           o         => switch_2
       );            
begin

    mul_0_in <= resize(unsigned(value) srl (C_MODULUS_WIDTH - 1), C_MAX_INPUT_WIDTH-C_MODULUS_WIDTH);
    mul_1_in <= resize(mul_0_out srl (C_MODULUS_WIDTH - 1), C_MAX_INPUT_WIDTH-C_MODULUS_WIDTH);
    
    tmp <= value_delay - mul_1_out;
    remainder <= std_logic_vector(resize(tmp - resize(unsigned(modulus), C_MODULUS_WIDTH), C_MAX_MODULUS_WIDTH)) when (tmp >= unsigned(modulus)) else std_logic_vector(resize(tmp, C_MAX_MODULUS_WIDTH));

end Behavioral;
