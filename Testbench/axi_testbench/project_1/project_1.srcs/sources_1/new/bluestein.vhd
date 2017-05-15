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
use work.crt_pkg.all;

entity bs is
	generic (
		C_MAX_FFT_PRIME_WIDTH   : integer    := 64;
    	C_MAX_BLUESTEIN_LENGTH  : integer    := 7710; 
		C_MAX_FFT_LENGTH        : integer    := 7710; 
		C_MAX_FFT_PRIMES		: integer    := 9
	);
	port (
		clk            : in std_logic := '0';
		enabled        : in std_logic := '0';
   		mode           : in std_logic_vector(4-1 downto 0)                         := (others => '0');	
        param          : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        param_valid    : in std_logic := '0';
        values         : in crt_bus(0 to C_MAX_FFT_PRIMES-1)                          := (others => (others => '0'));
        values_valid   : in std_logic := '0';
		outputs        : out crt_bus(0 to C_MAX_FFT_PRIMES-1)                         := (others => (others => '0'))
		outputs_valid  : in std_logic := '0';
	);  
end bs;

architecture Behavioral of bs is

type VALID_TYPE is array(natural range <>) of std_logic;
    
signal primes_param_valid : VALID_TYPE(0 to C_MAX_FFT_PRIMES)  := (others => '0');
signal primes_output_valid : VALID_TYPE(0 to C_MAX_FFT_PRIMES)  := (others => '0');

begin

    outputs_valid <= primes_output_valid(0);
    
	bs_primes : for i in 0 to C_MAX_FFT_PRIMES - 1 generate
		prime_i : entity work.bluestein_fft
			generic map (
				C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH,
				C_MAX_FFT_LENGTH      => C_MAX_FFT_LENGTH
			)
			port map (
				clk	              => clk,
				param             => param,
				param_valid       => primes_param_valid(i)
				value	          => values(i),
				value_valid       => values_valid,
				output            => outputs(i)
				output_valid      => primes_output_valid(i)
			);
	end generate bs_primes;
end Behavioral;
