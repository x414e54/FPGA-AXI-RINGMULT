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
		C_MAX_INPUT_WIDTH   : integer    := 128;
		C_CORE_DELAY        : integer    := 18
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

    signal value_delay : std_logic_vector(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');
        
    signal mul_0_in : std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0) := (others => '0');
    signal mul_0_out : std_logic_vector(2*C_MAX_MODULUS_WIDTH-1 downto 0) := (others => '0');
    signal mul_1_in : std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0) := (others => '0');
    signal mul_1_out : std_logic_vector(2*C_MAX_MODULUS_WIDTH-1 downto 0) := (others => '0');
    
    signal tmp : unsigned(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');
    signal tmp2 : unsigned(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');
    signal tmp3 : unsigned(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');
        
begin

    mul_0 : entity work.mult_gen_0
        port map (
            clk => clk,
            a   => mul_0_in,
            b   => modulus_r,
            p   => mul_0_out
        );
                 
    mul_1 : entity work.mult_gen_0
        port map (
            clk => clk,
            a   => mul_1_in,
            b   => modulus,
            p   => mul_1_out
        );
           
    a_delay : entity work.delay
        generic map (
            C_MAX_INPUT_WIDTH => C_MAX_INPUT_WIDTH,
            C_DELAY => 2*C_CORE_DELAY
        )
        port map (
            clk       => clk,
            i         => value,
            o         => value_delay
        );     
        
    mul_0_in <= std_logic_vector(resize(unsigned(value) srl (C_MODULUS_WIDTH - 1), C_MAX_MODULUS_WIDTH));
    mul_1_in <= std_logic_vector(resize(unsigned(mul_0_out) srl (C_MODULUS_WIDTH - 1), C_MAX_MODULUS_WIDTH));
    
    tmp <= unsigned(value_delay) - unsigned(mul_1_out);
    tmp2 <= tmp - unsigned(modulus);
    tmp3 <= tmp - (unsigned(modulus) sll 1);
    remainder <= std_logic_vector(resize(tmp3, C_MAX_MODULUS_WIDTH)) when (tmp >= (unsigned(modulus) sll 1)) else
                 std_logic_vector(resize(tmp2, C_MAX_MODULUS_WIDTH)) when (tmp >= unsigned(modulus)) else
                 std_logic_vector(resize(tmp, C_MAX_MODULUS_WIDTH));

end Behavioral;
