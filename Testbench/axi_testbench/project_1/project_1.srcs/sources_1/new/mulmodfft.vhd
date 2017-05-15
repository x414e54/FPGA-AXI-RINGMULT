----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2017/04/03 13:03:56
-- Design Name: 
-- Module Name: mulmodfft - Behavioral
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

entity mulmod is
	generic (
	    C_PARAM_WIDTH           : integer   := 64;
        C_PARAM_ADDR_WIDTH      : integer   := 32;
        C_PARAM_ADDR_TOP        : integer   := x"0000";
        C_LENGTH_WIDTH          : integer   := 16;	
		C_MAX_FFT_PRIME_WIDTH   : integer   := 64;
        C_MAX_FFT_LENGTH        : integer   := 16384; 
        C_MAX_POLY_LENGTH       : integer   := 7710; 
		C_MAX_CRT_PRIME_WIDTH   : integer   := 256; 
		C_MAX_FFT_PRIMES		: integer   := 9;
		C_MAX_FFT_PRIMES_FOLDS  : integer   := (256/64)-2--C_MAX_CRT_PRIME_WIDTH / C_MAX_FFT_PRIME_WIDTH - 2
	);
	port (
		clk            : in std_logic                                                := '0';
		----
        param          : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        param_addr     : in std_logic_vector(C_PARAM_ADDR_WIDTH-1 downto 0)        := (others => '0');
        param_valid    : in std_logic;
        ----
		value          : in std_logic_vector(C_MAX_CRT_PRIME_WIDTH-1 downto 0)      := (others => '0');       
        output         : in std_logic_vector(C_MAX_CRT_PRIME_WIDTH-1 downto 0)      := (others => '0')
	);  
end mulmod;

architecture Behavioral of mulmod is

type REGISTER_TYPE is array(natural range <>) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
type VALID_TYPE is array(natural range <>) of s
    
signal length  : integer := 0;
signal prime   : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
signal prime_r : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
signal prime_s : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');

signal mul_table_write_idx    : integer := 0;

signal mul_table : REGISTER_TYPE(0 to C_MAX_POLY_LENGTH)  := (others => (others => '0'));

signal remainders        : REGISTER_TYPE(0 to C_MAX_POLY_LENGTH)  := (others => (others => '0'));
signal remainders_valid  : VALID_TYPE(0 to C_MAX_POLY_LENGTH)  := (others => (others => '0'));
signal bs_outputs        : REGISTER_TYPE(0 to C_MAX_POLY_LENGTH)  := (others => (others => '0'));
signal bs_outputs_valid  : VALID_TYPE(0 to C_MAX_POLY_LENGTH)  := (others => (others => '0'));
signal mul_outputs       : REGISTER_TYPE(0 to C_MAX_POLY_LENGTH)  := (others => (others => '0'));
signal ibs_outputs       : REGISTER_TYPE(0 to C_MAX_POLY_LENGTH)  := (others => (others => '0'));
signal ibs_outputs_valid : VALID_TYPE(0 to C_MAX_POLY_LENGTH)  := (others => (others => '0'));

begin
		crt : entity work.crt
			generic map (
				C_MAX_MODULUS_WIDTH => C_MAX_FFT_PRIME_WIDTH,
				C_MAX_INPUT_WIDTH   => C_MAX_CRT_PRIME_WIDTH,
				C_MAX_MODULUS_FOLDS => C_MAX_FFT_PRIMES_FOLDS
			)
			port map (
				clk	        => clk,
                param       => param_addr,
                param_addr  => param_addr,
                param_valid => param_valid,
				value	    => value,
				remainder   => remainders(i)
			);
			
		bs_crt : entity work.bs_crt
            generic (
                C_MAX_FFT_PRIME_WIDTH   => C_MAX_FFT_PRIME_WIDTH,
                C_MAX_BLUESTEIN_LENGTH  => C_MAX_POLY_LENGTH, 
                C_MAX_FFT_LENGTH        => C_MAX_FFT_LENGTH, 
                C_MAX_FFT_PRIMES		=> C_MAX_FFT_PRIMES,
                C_PARAM_ADDR_TOP        => C_PARAM_ADDR_TOP + 10
            );
            port (
                clk            => clk,
                param          => param_addr,
                param_addr     => param_addr.
                param_valid    => param_valid,
                values         => remainders,
                values_valid   => remainders_valid,
                outputs        => bs_outputs,
                outputs_valid  => bs_outputs_valid
            );  
            	
        primes_mul : for i in 0 to C_MAX_FFT_PRIMES - 1 generate
            mulxieta : entity work.mulred
            generic map (
                C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
            )
            port map (
                clk         => clk,
                modulus     => prime,
                modulus_r   => prime_r,
                modulus_s   => prime_s,
                a           => bs_outputs(i),
                b           => mul_table(mul_table_idx),
                c           => mul_outputs(i)  
            );
        end generate bs_primes;
			
		ibs_crt : entity work.bs_crt
            generic (
                C_MAX_FFT_PRIME_WIDTH   => C_MAX_FFT_PRIME_WIDTH,
                C_MAX_BLUESTEIN_LENGTH  => C_MAX_BLUESTEIN_LENGTH, 
                C_MAX_FFT_LENGTH        => C_MAX_FFT_LENGTH, 
                C_MAX_FFT_PRIMES		=> C_MAX_FFT_PRIMES,
                C_PARAM_ADDR_TOP        => C_PARAM_ADDR_TOP + 20
            );
            port (
                clk            => clk,
                param          => param_addr,
                param_addr     => param_addr.
                param_valid    => param_valid,
                modulus        => prime,
                modulus_r      => prime_r,
                modulus_s      => prime_s,
                values         => mul_outputs,
                values_valid   => bs_outputs_valid_delay,
                outputs        => ibs_outputs,
                outputs_valid  => ibs_outputs_valid
            );  

--        icrt : entity work.icrt
 --           generic (
  --              C_MAX_MODULUS_WIDTH   => C_MAX_FFT_PRIME_WIDTH,
   --             C_MAX_CRT_PRIME_WIDTH => C_MAX_CRT_PRIME_WIDTH
    --        );
    --        port (
     --           clk            => clk,
      --          mode           => 	
       --         param          => 
        --        param_valid    => 
         --       values         => 
         --       values_valid   => 
         --       output         => output
         --       output_valid   => 
         ---   );  
                
state_proc : process (clk) is
    begin	
        if rising_edge(clk) then
  
        end if;
    end process state_proc;
end Behavioral;
