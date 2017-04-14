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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fft_stage_pkg.all;

entity bs is
	generic (
		C_MAX_FFT_PRIME_WIDTH   : integer    := 64;
    	C_MAX_BLUESTEIN_LENGTH  : integer    := 7710; 
		C_MAX_FFT_LENGTH        : integer    := 7710; 
		C_MAX_FFT_PRIMES		: integer    := 9
	);
	port (
		clk          : in std_logic := '0';
		enabled      : in std_logic := '0';
        values       : in stage_io(0 to C_MAX_FFT_PRIMES-1)    := (others => (others => '0'));
        primes       : in stage_io(0 to C_MAX_FFT_PRIMES-1)    := (others => (others => '0'));
        primes_red   : in stage_io(0 to C_MAX_FFT_PRIMES-1)    := (others => (others => '0'));
        prime_len    : in std_logic_vector(16-1 downto 0)   := (others => '0');		
        w_table      : in stage_io(0 to C_MAX_FFT_LENGTH/2-1)  := (others => (others => '0'));
		outputs      : out stage_io(0 to C_MAX_FFT_PRIMES-1)   := (others => (others => '0'))
	);  
end bs;

architecture Behavioral of bs is
begin
	bs_primes : for i in 0 to C_MAX_FFT_PRIMES - 1 generate
		prime_i : entity work.bluestein_fft
			generic map (
				C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH,
				C_MAX_FFT_LENGTH      => C_MAX_FFT_LENGTH
			)
			port map (
				clk	       => clk,
				w_table    => w_table,
				prime      => primes(i),
                prime_r    => primes_red(i),
				value	   => values(i),
				output     => outputs(i)
			);
	end generate bs_primes;
end Behavioral;
