----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2017/04/03 13:03:56
-- Design Name: 
-- Module Name: crt - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

package crt_pkg is
	type crt_bus is array(natural range <>) of std_logic_vector;
end package;

entity crt is
	generic (
		C_MAX_FFT_PRIME_WIDTH   : integer    := 64;
		C_MAX_CRT_PRIME_WIDTH   : integer    := 256;
		C_MAX_FFT_PRIMES		: integer    := 9
	);
	port (
		clk        : in std_logic;
		reset      : in std_logic;
		enabled    : in std_logic;
		value      : in unsigned(C_MAX_CRT_PRIME_WIDTH-1 downto 0)   := (others => '0');
		remainders : out crt_bus(C_MAX_FFT_PRIMES-1 downto 0)(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => (others => '0'))
	);  
end crt;

architecture Behavioral of crt is
    type PRIMES_TYPE is array(C_MAX_FFT_PRIMES-1 downto 0) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);

	shared variable primes : PRIMES_TYPE := (others => (others => '0'));
begin
	crt_primes : for i in 0 to C_MAX_FFT_PRIMES generate
		prime_i : entity work.reduce
			generic map (
				C_MAX_MODULUS_WIDTH => C_MAX_FFT_PRIME_WIDTH,
				C_MAX_INPUT_WIDTH   => C_MAX_CRT_PRIME_WIDTH
			)
			port map (
				clk	      => clk,
				modulus   => primes(i),
				value	  => value,
				remainder => remainders(i)
			);
	end generate crt_primes;
end Behavioral;
