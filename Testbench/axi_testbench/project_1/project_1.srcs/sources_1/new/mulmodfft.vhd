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
		C_MAX_FFT_PRIME_WIDTH                : integer   := 256;
        C_MAX_FFT_LENGTH                     : integer   := 16384; 
        C_MAX_POLY_LENGTH                    : integer   := 7710;
		---
		C_PARAM_ADDR_MUL_TABLE               : integer := 0;
        C_PARAM_ADDR_FFT_TABLE               : integer := 9;
        C_PARAM_ADDR_IFFT_TABLE              : integer := 18;
        C_PARAM_ADDR_BS_MUL_TABLE            : integer := 27;
        C_PARAM_ADDR_BS_MUL_FFT_TABLE        : integer := 36;
        C_PARAM_ADDR_IBS_MUL_TABLE           : integer := 45;
        C_PARAM_ADDR_IBS_MUL_FFT_TABLE       : integer := 54
        ---
	);
	port (
		clk            : in std_logic                                               := '0';
		----
        param          : in std_logic_vector(C_PARAM_WIDTH-1 downto 0)             := (others => '0');
        param_addr     : in std_logic_vector(C_PARAM_ADDR_WIDTH-1 downto 0)        := (others => '0');
        param_valid    : in std_logic;
        ----
		value          : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');      
		value_valid    : in std_logic; 
        output         : out std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        output_valid   : out std_logic
	);  
end mulmodfft;

architecture Behavioral of mulmodfft is

    type REGISTER_TYPE is array(natural range <>) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
        
    signal mul_table_val : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
        
    signal mul_table_idx : integer := 0;
     
    signal length     : std_logic_vector(C_LENGTH_WIDTH-1 downto 0)   := (others => '0');
    signal fft_length : std_logic_vector(C_LENGTH_WIDTH-1 downto 0)   := (others => '0');

    signal mul_table  : REGISTER_TYPE(0 to C_MAX_POLY_LENGTH-1)  := (others => (others => '0'));

    signal prime      : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    signal prime_r    : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    signal prime_i    : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    signal prime_s    : std_logic_vector(C_LENGTH_WIDTH-1 downto 0)   := (others => '0');

    signal bs_output        : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal bs_output_valid  : std_logic  := '0';
    signal mul_output       : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal mul_output_valid : std_logic  := '0';
    
    alias param_addr_top : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is param_addr(C_PARAM_ADDR_WIDTH-1 downto C_PARAM_ADDR_WIDTH/2);
    alias param_addr_bottom : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is param_addr((C_PARAM_ADDR_WIDTH/2)-1 downto 0);
        
begin

    mul_table_val <= mul_table(mul_table_idx);

    bs : entity work.bluestein_fft
        generic map (
            C_PARAM_WIDTH              => C_PARAM_WIDTH,
            C_PARAM_ADDR_WIDTH         => C_PARAM_ADDR_WIDTH,
            C_PARAM_ADDR_MUL_TABLE     => C_PARAM_ADDR_BS_MUL_TABLE,
            C_PARAM_ADDR_MUL_FFT_TABLE => C_PARAM_ADDR_BS_MUL_FFT_TABLE, 
            C_PARAM_ADDR_FFT_TABLE     => C_PARAM_ADDR_FFT_TABLE,
            C_PARAM_ADDR_IFFT_TABLE    => C_PARAM_ADDR_IFFT_TABLE,
            C_LENGTH_WIDTH             => C_LENGTH_WIDTH,	
            C_MAX_FFT_PRIME_WIDTH      => C_MAX_FFT_PRIME_WIDTH,
            C_MAX_BLUESTEIN_LENGTH     => C_MAX_POLY_LENGTH, 
            C_MAX_FFT_LENGTH           => C_MAX_FFT_LENGTH 
        )
        port map (
            clk            => clk,
            param          => param,
            param_addr     => param_addr,
            param_valid    => param_valid,
            prime          => prime,
            prime_r        => prime_r,
            prime_i        => prime_i,
            prime_s        => prime_s,
            fft_length     => fft_length,
            length         => length,
            value          => value,
            value_valid    => value_valid,
            output         => bs_output,
            output_valid   => bs_output_valid
        );  
        
    mul : entity work.mulred
        generic map (
            C_LENGTH_WIDTH      => C_LENGTH_WIDTH,
            C_MAX_MODULUS_WIDTH => C_MAX_FFT_PRIME_WIDTH
        )
        port map (
            clk         => clk,
            modulus     => prime,
            modulus_r   => prime_r,
            modulus_s   => prime_s,
            a           => bs_output,
            b           => mul_table_val,
            c           => mul_output
        );

    ibs : entity work.bluestein_fft
        generic map (
            C_PARAM_WIDTH              => C_PARAM_WIDTH,
            C_PARAM_ADDR_WIDTH         => C_PARAM_ADDR_WIDTH,
            C_PARAM_ADDR_MUL_TABLE     => C_PARAM_ADDR_IBS_MUL_TABLE,
            C_PARAM_ADDR_MUL_FFT_TABLE => C_PARAM_ADDR_IBS_MUL_FFT_TABLE, 
            C_PARAM_ADDR_FFT_TABLE     => C_PARAM_ADDR_FFT_TABLE,
            C_PARAM_ADDR_IFFT_TABLE    => C_PARAM_ADDR_IFFT_TABLE,
            C_LENGTH_WIDTH             => C_LENGTH_WIDTH,	
            C_MAX_FFT_PRIME_WIDTH      => C_MAX_FFT_PRIME_WIDTH,
            C_MAX_BLUESTEIN_LENGTH     => C_MAX_POLY_LENGTH, 
            C_MAX_FFT_LENGTH           => C_MAX_FFT_LENGTH 
        ) 
        port map (
            clk            => clk,
            param          => param,
            param_addr     => param_addr,
            param_valid    => param_valid,
            prime          => prime,
            prime_r        => prime_r,
            prime_i        => prime_i,
            prime_s        => prime_s,
            fft_length     => fft_length,
            length         => length,
            value          => mul_output,
            value_valid    => mul_output_valid,
            output         => output,
            output_valid   => output_valid
        );  
            
    state_proc : process (clk) is
    begin	
        if rising_edge(clk) then
            --if (param_valid = '1' and to_integer(unsigned(param_addr_top)) = C_PARAM_ADDR_MUL_TABLE) then
            --    mul_table(to_integer(unsigned(param_addr_bottom))) <= param;
            --end if;     
            
            if (bs_output_valid = '1') then
                if (mul_table_idx - 1 = to_integer(unsigned(length))) then
                    mul_table_idx <= 0;
                else
                    mul_table_idx <= mul_table_idx + 1;
                end if;
            end if;
        end if;
    end process state_proc;
end Behavioral;
