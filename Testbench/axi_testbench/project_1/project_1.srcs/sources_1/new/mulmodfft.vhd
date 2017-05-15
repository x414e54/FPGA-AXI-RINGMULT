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
		C_MAX_FFT_PRIME_WIDTH   : integer    := 64;
        C_MAX_FFT_LENGTH        : integer    := 7710; 
        C_MAX_POLY_LENGTH       : integer    := 7710; 
		C_MAX_CRT_PRIME_WIDTH   : integer    := 256; 
		C_MAX_FFT_PRIMES		: integer    := 9;
		C_MAX_FFT_PRIMES_FOLDS  : integer    := (256/64)-2--C_MAX_CRT_PRIME_WIDTH / C_MAX_FFT_PRIME_WIDTH - 2
	);
	port (
		clk            : in std_logic                                                := '0';
        param          : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)      := (others => '0');
        param_valid    : in std_logic;
		value          : in std_logic_vector(C_MAX_CRT_PRIME_WIDTH-1 downto 0)      := (others => '0');       
        output         : in std_logic_vector(C_MAX_CRT_PRIME_WIDTH-1 downto 0)      := (others => '0');
	);  
end mulmod;

architecture Behavioral of mulmod is

type REGISTER_TYPE is array(natural range <>) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
type VALID_TYPE is array(natural range <>) of s
    
signal length  : unsigned := (others => '0');
signal prime   : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
signal prime_r : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
signal prime_s : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');

signal mul_table_write_idx    : integer := 0;

signal mul_table : REGISTER_TYPE(0 to C_MAX_BLUESTEIN_LENGTH)  := (others => (others => '0'));

signal remainders       : REGISTER_TYPE(0 to C_MAX_BLUESTEIN_LENGTH)  := (others => (others => '0'));
signal remainders_valid : VALID_TYPE(0 to C_MAX_BLUESTEIN_LENGTH)  := (others => (others => '0'));
signal bs_outputs       : REGISTER_TYPE(0 to C_MAX_BLUESTEIN_LENGTH)  := (others => (others => '0'));
signal bs_outputs_valid : VALID_TYPE(0 to C_MAX_BLUESTEIN_LENGTH)  := (others => (others => '0'));

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
                param_addr  => param_addr.
                param_valid => param_valid,
				value	    => value,
				remainder   => remainders(i)
			);
			
		bs_crt : entity work.bs_crt
            generic (
                C_MAX_FFT_PRIME_WIDTH   => C_MAX_FFT_PRIME_WIDTH,
                C_MAX_BLUESTEIN_LENGTH  => C_MAX_POLY_LENGTH, 
                C_MAX_FFT_LENGTH        => C_MAX_FFT_LENGTH, 
                C_MAX_FFT_PRIMES		=> C_MAX_FFT_PRIMES
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
                c           => mul_output(i)  
            );
        end generate bs_primes;
			
		ibs_crt : entity work.bs_crt
            generic (
                C_MAX_FFT_PRIME_WIDTH   => C_MAX_FFT_PRIME_WIDTH,
                C_MAX_BLUESTEIN_LENGTH  => C_MAX_BLUESTEIN_LENGTH, 
                C_MAX_FFT_LENGTH        => C_MAX_FFT_LENGTH, 
                C_MAX_FFT_PRIMES		=> C_MAX_FFT_PRIMES
            );
            port (
                clk            => clk,
                param          => param_addr,
                param_addr     => param_addr.
                param_valid    => param_valid,
                values         : mul_output
                values_valid   : in std_logic := '0';
                outputs        => bs_outputs
                outputs_valid  : out std_logic := '0'
            );  

        icrt : entity work.icrt
            generic (
                C_MAX_MODULUS_WIDTH   => C_MAX_FFT_PRIME_WIDTH,
                C_MAX_CRT_PRIME_WIDTH => C_MAX_CRT_PRIME_WIDTH
            );
            port (
                clk            => clk,
                mode           => 	
                param          => 
                param_valid    => 
                values         => 
                values_valid   => 
                output         => output
                output_valid   => 
            );  
                
param_finished <= '0';
fft_param_valid <= '0';
ifft_param_valid <= '0';
ifft_param <= param;
fft_param <= param;

state_proc : process (clk) is
    begin	
        if rising_edge(clk) then
            case state is
                when IDLE =>
                    case mode is
                        when MODE_LOAD_PARAMS =>
                            state <= LOAD_BLUESTEIN_LENGTH;
                        when MODE_RUN =>
                            state <= RUN;
                        end case;
                         
                when LOAD_BLUESTEIN_LENGTH =>
                    if (param_valid = '1') then
                        length <= unsigned(param);
                        state <= IDLE;
                    end if;     
                                      
                when LOAD_FFT_LENGTH =>
                    fft_mode <= FFT_MODE_FFT_LENGTH;
                    ifft_mode <= FFT_MODE_FFT_LENGTH;
                    if (param_valid = '1') then
                        fft_param_valid <= '1';
                        ifft_param_valid <= '1';
                        state <= LOAD_PRIME;
                    end if;
                                            
                when LOAD_PRIME =>
                    bs_mode <= MODE_LOAD_PRIME;
                    ibs_mode <= MODE_LOAD_PRIME;
                    if (param_valid = '1') then
                        fft_param_valid <= '1';
                        ifft_param_valid <= '1';
                        prime <= param;
                        state <= LOAD_PRIME_R;
                    end if;
                    
                when LOAD_PRIME_R =>
                    if (param_valid = '1') then
                        fft_param_valid <= '1';
                        ifft_param_valid <= '1';
                        prime_r <= param;
                        state <= LOAD_PRIME_S;
                    end if;
                     
                when LOAD_PRIME_S =>
                    if (param_valid = '1') then
                        fft_param_valid <= '1';
                        ifft_param_valid <= '1';
                        prime_s <= param;
                        param_finished <= '1';
                        state <= IDLE;
                    end if;
                                                                                    
                when LOAD_FFT_TABLE =>
                    bs_mode <= BS_MODE_LOAD_FFT_TABLE;
                    ibs_mode <= BS_MODE_LOAD_FFT_TABLE;
                    if (fft_param_finished = '1') then
                        param_finished <= '1';
                        state <= IDLE;
                    end if;
                    if (param_valid = '1') then
                        fft_param_valid <= '1';
                    end if;
                    
                when LOAD_IFFT_TABLE =>
                    bs_mode <= BS_MODE_LOAD_IFFT_TABLE;
                    ibs_mode <= BS_MODE_LOAD_IFFT_TABLE;
                    if (ifft_param_finished = '1') then
                        param_finished <= '1';
                        state <= IDLE;
                    end if;
                    if (param_valid = '1') then
                        ifft_param_valid <= '1';
                    end if;
                
                when LOAD_MUL_TABLE =>
                    if (param_valid = '1') then
                        mul_table(mul_table_write_idx) <= param;
                        if (length = mul_table_in_idx - 1) then
                            mul_table_write_idx <= 0;
                            state <= IDLE;
                        end if;
                        mul_table_write_idx <= mul_table_write_idx + 1;
                    end if;
                
                when LOAD_MUL_FFT_TABLE =>
                    if (param_valid = '1') then
                        mul_fft_table(mul_fft_table_write_idx) <= param;
                        if (length = mul_fft_table_in_idx - 1) then
                            mul_fft_table_write_idx <= 0;
                            state <= IDLE;
                        end if;
                        mul_fft_table_write_idx <= mul_fft_table_write_idx + 1;
                    end if;    
                                                                                                          
                when RUN =>
                    ifft_mode <= FFT_MODE_RUN;
                    fft_mode <= FFT_MODE_RUN;
            end case;
        end if;
    end process state_proc;
end Behavioral;
