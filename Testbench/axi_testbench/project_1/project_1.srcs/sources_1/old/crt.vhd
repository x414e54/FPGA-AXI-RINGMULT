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
use work.rem_pkg.all;

package crt_pkg is
	type crt_bus   is array(natural range <>) of std_logic_vector(64-1 downto 0);
end package;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.crt_pkg.all;

entity crt is
	generic (
		C_MAX_FFT_PRIME_WIDTH   : integer    := 64;
		C_MAX_CRT_PRIME_WIDTH   : integer    := 256; 
		C_MAX_FFT_PRIMES		: integer    := 9;
		C_MAX_FFT_PRIMES_FOLDS  : integer    := (256/64)-2--C_MAX_CRT_PRIME_WIDTH / C_MAX_FFT_PRIME_WIDTH - 2
	);
	port (
		clk            : in std_logic := '0';
        param          : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        param_addr     : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        param_valid    : in std_logic;
        ----
		value          : in std_logic_vector(C_MAX_CRT_PRIME_WIDTH-1 downto 0)   := (others => '0');
		remainders     : out crt_bus(C_MAX_FFT_PRIMES-1 downto 0)  := (others => (others => '0'))
	);  
end crt;

architecture Behavioral of crt is
begin
	crt_primes : for i in 0 to C_MAX_FFT_PRIMES - 1 generate
		prime_i : entity work.rem_fold
			generic map (
				C_MAX_MODULUS_WIDTH => C_MAX_FFT_PRIME_WIDTH,
				C_MAX_INPUT_WIDTH   => C_MAX_CRT_PRIME_WIDTH,
				C_MAX_MODULUS_FOLDS => C_MAX_FFT_PRIMES_FOLDS
			)
			port map (
				clk	         => clk,
				param        => param,
            	param_addr   => param_addr,
				param_valid  => param_valid,
				value	     => value,
				remainder    => remainders(i)
			);
	end generate crt_primes;
end Behavioral;
