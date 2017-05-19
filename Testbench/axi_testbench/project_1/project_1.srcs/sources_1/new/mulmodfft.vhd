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

entity mulmodfft is
	generic (
	    C_PARAM_WIDTH                        : integer   := 64;
        C_PARAM_ADDR_WIDTH                   : integer   := 32;
        ---
        C_LENGTH_WIDTH                       : integer   := 16;	
		C_MAX_FFT_PRIME_WIDTH                : integer   := 64;
        C_MAX_FFT_LENGTH                     : integer   := 16384; 
        C_MAX_POLY_LENGTH                    : integer   := 7710; 
		C_MAX_CRT_PRIME_WIDTH                : integer   := 256; 
		C_MAX_FFT_PRIMES		             : integer   := 9;
		C_MAX_FFT_PRIMES_FOLDS               : integer   := (256/64)-2;--C_MAX_CRT_PRIME_WIDTH / C_MAX_FFT_PRIME_WIDTH - 2
		---
		C_PARAM_ADDR_MUL_TABLE_START         : integer := 0;
        C_PARAM_ADDR_FFT_TABLE_START         : integer := 9; --C_PARAM_ADDR_MUL_TABLE_START + C_MAX_FFT_PRIMES;
        C_PARAM_ADDR_IFFT_TABLE_START        : integer := 18; --C_PARAM_ADDR_FFT_TABLE_START + C_MAX_FFT_PRIMES;
        C_PARAM_ADDR_BS_MUL_TABLE_START      : integer := 27; --C_PARAM_ADDR_IFFT_TABLE_START + C_MAX_FFT_PRIMES;
        C_PARAM_ADDR_BS_MUL_FFT_TABLE_START  : integer := 36; --C_PARAM_ADDR_BS_MUL_TABLE_START + C_MAX_FFT_PRIMES;
        C_PARAM_ADDR_IBS_MUL_TABLE_START     : integer := 45; --C_PARAM_ADDR_BS_MUL_FFT_TABLE_START + C_MAX_FFT_PRIMES;
        C_PARAM_ADDR_IBS_MUL_FFT_TABLE_START : integer := 54; --C_PARAM_ADDR_IBS_MUL_TABLE_START + C_MAX_FFT_PRIMES;
        C_PARAM_ADDR_FOLDS_START             : integer := 63 --C_PARAM_ADDR_IBS_MUL_FFT_TABLE_START + C_MAX_FFT_PRIMES
        ---
	);
	port (
		clk            : in std_logic                                                := '0';
		----
        param          : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        param_addr     : in std_logic_vector(C_PARAM_ADDR_WIDTH-1 downto 0)        := (others => '0');
        param_valid    : in std_logic;
        ----
		value          : in std_logic_vector(C_MAX_CRT_PRIME_WIDTH-1 downto 0)      := (others => '0');      
		value_valid    : in std_logic; 
        output         : in std_logic_vector(C_MAX_CRT_PRIME_WIDTH-1 downto 0)      := (others => '0');
        output_valid   : out std_logic
	);  
end mulmodfft;

architecture Behavioral of mulmodfft is

    type REGISTER_TYPE is array(natural range <>) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    type VALID_TYPE is array(natural range <>) of std_logic;
    
    signal mul_table_idx : integer := 0;
     
    signal length      : std_logic_vector(C_LENGTH_WIDTH-1 downto 0)   := (others => '0');
    signal fft_length  : std_logic_vector(C_LENGTH_WIDTH-1 downto 0)   := (others => '0');

    signal mul_table   : REGISTER_TYPE(0 to (C_MAX_POLY_LENGTH*C_MAX_FFT_PRIMES)-1)  := (others => (others => '0'));

    signal primes      : REGISTER_TYPE(0 to C_MAX_FFT_PRIMES-1)  := (others => (others => '0'));
    signal primes_r    : REGISTER_TYPE(0 to C_MAX_FFT_PRIMES-1)  := (others => (others => '0'));
    signal prime_s     : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');

    signal remainders        : REGISTER_TYPE(0 to C_MAX_FFT_PRIMES-1)  := (others => (others => '0'));
    signal remainders_valid  : VALID_TYPE(0 to C_MAX_FFT_PRIMES-1)  := (others => '0');
    signal bs_outputs        : REGISTER_TYPE(0 to C_MAX_FFT_PRIMES-1)  := (others => (others => '0'));
    signal bs_outputs_valid  : VALID_TYPE(0 to C_MAX_FFT_PRIMES-1)  := (others => '0');
    signal mul_outputs       : REGISTER_TYPE(0 to C_MAX_FFT_PRIMES-1)  := (others => (others => '0'));
    signal mul_outputs_valid : VALID_TYPE(0 to C_MAX_FFT_PRIMES-1)  := (others => '0');
    signal ibs_outputs       : REGISTER_TYPE(0 to C_MAX_FFT_PRIMES-1)  := (others => (others => '0'));
    signal ibs_outputs_valid : VALID_TYPE(0 to C_MAX_FFT_PRIMES-1)  := (others => '0');
    
    alias param_addr_top : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is param_addr(C_PARAM_ADDR_WIDTH-1 downto C_PARAM_ADDR_WIDTH/2);
    alias param_addr_bottom : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is param_addr((C_PARAM_ADDR_WIDTH/2)-1 downto 0);
        
begin
        crt : for i in 0 to C_MAX_FFT_PRIMES - 1 generate
            prime_i : entity work.rem_fold
                generic map (
                    C_PARAM_WIDTH       => C_PARAM_WIDTH,
                    C_PARAM_ADDR_WIDTH  => C_PARAM_ADDR_WIDTH,
                    C_PARAM_ADDR_FOLDS  => C_PARAM_ADDR_FOLDS_START + i,
                    C_LENGTH_WIDTH      => C_LENGTH_WIDTH,	
                    C_MAX_MODULUS_WIDTH => C_MAX_FFT_PRIME_WIDTH,
                    C_MAX_INPUT_WIDTH   => C_MAX_CRT_PRIME_WIDTH,
                    C_MAX_INPUT_LEN     => C_MAX_CRT_PRIME_WIDTH/C_MAX_FFT_PRIME_WIDTH,
                    C_MAX_MODULUS_FOLDS => C_MAX_FFT_PRIMES_FOLDS
                )
                port map (
                    clk	         => clk,
                    param        => param,
        	        param_addr   => param_addr,
                    param_valid  => param_valid,
                    modulus      => primes(i),
                    modulus_r    => primes_r(i),
                    modulus_s    => prime_s,
                    value	     => value,
                    remainder    => remainders(i)
                );
        end generate crt;

        bs : for i in 0 to C_MAX_FFT_PRIMES - 1 generate	
            bs_i : entity work.bluestein_fft
                generic map (
            	    C_PARAM_WIDTH              => C_PARAM_WIDTH,
                    C_PARAM_ADDR_WIDTH         => C_PARAM_ADDR_WIDTH,
                    C_PARAM_ADDR_MUL_TABLE     => C_PARAM_ADDR_BS_MUL_TABLE_START + i,
                    C_PARAM_ADDR_MUL_FFT_TABLE => C_PARAM_ADDR_BS_MUL_FFT_TABLE_START + i, 
                    C_PARAM_ADDR_FFT_TABLE     => C_PARAM_ADDR_FFT_TABLE_START + i,
                    C_PARAM_ADDR_IFFT_TABLE    => C_PARAM_ADDR_IFFT_TABLE_START + i,
                    C_LENGTH_WIDTH             => C_LENGTH_WIDTH,	
            		C_MAX_FFT_PRIME_WIDTH      => C_MAX_FFT_PRIME_WIDTH,
                	C_MAX_BLUESTEIN_LENGTH     => C_MAX_POLY_LENGTH, 
            		C_MAX_FFT_LENGTH           => C_MAX_FFT_LENGTH 
                )
                port map (
                    clk            => clk,
                    param          => param_addr,
                    param_addr     => param_addr,
                    param_valid    => param_valid,
                    prime          => primes(i),
                    prime_r        => primes_r(i),
                    prime_s        => prime_s,
                    fft_length     => fft_length,
                    length         => length,
                    value          => remainders(i),
                    value_valid    => remainders_valid(i),
                    output         => bs_outputs(i),
                    output_valid   => bs_outputs_valid(i)
                );  
        end generate bs;
            	
        mul : for i in 0 to C_MAX_FFT_PRIMES - 1 generate
            mul_i : entity work.mulred
                generic map (
                    C_LENGTH_WIDTH      => C_LENGTH_WIDTH,
                    C_MAX_MODULUS_WIDTH => C_MAX_FFT_PRIME_WIDTH
                )
                port map (
                    clk         => clk,
                    modulus     => primes(i),
                    modulus_r   => primes_r(i),
                    modulus_s   => prime_s,
                    a           => bs_outputs(i),
                    b           => mul_table(mul_table_idx),
                    c           => mul_outputs(i)  
                );
        end generate mul;
        
        ibs : for i in 0 to C_MAX_FFT_PRIMES - 1 generate	
            ibs_i : entity work.bluestein_fft
                generic map (
                    C_PARAM_WIDTH              => C_PARAM_WIDTH,
                    C_PARAM_ADDR_WIDTH         => C_PARAM_ADDR_WIDTH,
                    C_PARAM_ADDR_MUL_TABLE     => C_PARAM_ADDR_IBS_MUL_TABLE_START + i,
                    C_PARAM_ADDR_MUL_FFT_TABLE => C_PARAM_ADDR_IBS_MUL_FFT_TABLE_START + i, 
                    C_PARAM_ADDR_FFT_TABLE     => C_PARAM_ADDR_FFT_TABLE_START + i,
                    C_PARAM_ADDR_IFFT_TABLE    => C_PARAM_ADDR_IFFT_TABLE_START + i,
                    C_LENGTH_WIDTH             => C_LENGTH_WIDTH,	
                    C_MAX_FFT_PRIME_WIDTH      => C_MAX_FFT_PRIME_WIDTH,
                    C_MAX_BLUESTEIN_LENGTH     => C_MAX_POLY_LENGTH, 
                    C_MAX_FFT_LENGTH           => C_MAX_FFT_LENGTH 
                ) 
                port map (
                    clk            => clk,
                    param          => param_addr,
                    param_addr     => param_addr,
                    param_valid    => param_valid,
                    prime          => primes(i),
                    prime_r        => primes_r(i),
                    prime_s        => prime_s,
                    fft_length     => fft_length,
                    length         => length,
                    value          => mul_outputs(i),
                    value_valid    => mul_outputs_valid(i),
                    output         => ibs_outputs(i),
                    output_valid   => ibs_outputs_valid(i)
                );  
        end generate ibs;

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
            --if (param_valid = '1' and to_integer(unsigned(param_addr_top)) = C_PARAM_ADDR_MUL_TABLE) then
            --    mul_table(to_integer(unsigned(param_addr_bottom))) <= param;
            --end if;     
            
            if (bs_outputs_valid(0) = '1') then
                if (mul_table_idx - 1 = length) then
                    mul_table_idx <= 0;
                else
                    mul_table_idx <= mul_table_idx + 1;
                end if;
            end if;
        end if;
    end process state_proc;
end Behavioral;
