----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2017/04/03 13:09:21
-- Design Name: 
-- Module Name: reduce - Behavioral
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
use IEEE.MATH_REAL.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bluestein_fft is
	generic (
		C_MAX_FFT_PRIME_WIDTH   : integer    := 64;
    	C_MAX_BLUESTEIN_LENGTH  : integer    := 7710; 
		C_MAX_FFT_LENGTH        : integer    := 7710 
	);
	port (
		clk               : in std_logic;
		----
        param          : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        param_addr     : in std_logic_vector(16-1 downto 0)                        := (others => '0');
        param_valid    : in std_logic;
        ----
        prime          : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        prime_r        : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        prime_s        : in std_logic_vector(16-1 downto 0)                        := (others => '0'); 
        fft_length     : in std_logic_vector(16-1 downto 0)                        := (others => '0'); 
        length         : in std_logic_vector(16-1 downto 0)                        := (others => '0'); 
        ----
        value             : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        value_valid       : in std_logic;
		output            : out std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)    := (others => '0');
		output_valid      : out std_logic
	);  
end bluestein_fft;

architecture Behavioral of bluestein_fft is

type REGISTER_TYPE is array(natural range <>) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    
constant NUM_STAGES : integer := integer(ceil(log2(real(C_MAX_FFT_LENGTH)))); 

signal mul_table_in_idx        : integer := 0;
signal mul_table_out_idx       : integer := 0;
signal mul_fft_table_idx       : integer := 0;

signal mul_table : REGISTER_TYPE(0 to C_MAX_FFT_LENGTH)  := (others => (others => '0'));
signal mul_fft_table : REGISTER_TYPE(0 to C_MAX_FFT_LENGTH)  := (others => (others => '0'));
 
signal fft_output : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
signal fft_output_valid : std_logic     := '0';

signal ifft_output : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)    := (others => '0');
signal ifft_output_valid : std_logic     := '0';

signal mul_output : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
signal mul_fft_output : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');

begin
    
--- Mul yi table
    mulyi : entity work.mulred
    generic map (
        C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
    )
    port map (
        clk         => clk,
        modulus     => prime,
        modulus_r   => prime_r,
        modulus_s   => prime_s,
        a           => value,
        b           => mul_table(mul_table_in_idx),
        c           => mul_output  
    );

--- Forward FFT    
    forward_fft : entity work.fft
    generic map (
        C_MAX_FFT_LENGTH      => C_MAX_FFT_LENGTH,
        C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH,
        C_PARAM_ADDR_TOP      => C_PARAM_ADDR_TOP + 1,
    )
    port map (
        clk          => clk,
        ---
        param        => param,
        param_addr   => param,
        param_valid  => param_valid,
        ----
        prime        => prime,
        prime_r      => prime_r,
        prime_s      => prime_s, 
        length       => fft_length, 
        ----
        value        => mul_output,
        value_valid  => mul_output_valid,
        output       => fft_output,
        output_valid => fft_output_valid
    );  
        
--- Mul y table FFT
    muly : entity work.mulred
    generic map (
        C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
    )
    port map (
        clk         => clk,
        modulus     => prime,
        modulus_r   => prime_r,
        modulus_s   => prime_s,
        a           => fft_output,
        b           => mul_fft_table(mul_fft_table_idx),
        c           => mul_fft_output  
    );
    
--- Reverse FFT    
    inverse_fft : entity work.fft
    generic map (
        C_MAX_FFT_LENGTH      => C_MAX_FFT_LENGTH,
        C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH,
        C_PARAM_ADDR_TOP      => C_PARAM_ADDR_TOP + 2
    )
    port map (
        clk          => clk,
        ---
        param        => param,
        param_addr   => param,
        param_valid  => param_valid,
        ----
        prime        => prime,
        prime_r      => prime_r,
        prime_s      => prime_s, 
        length       => fft_length, 
        ----
        value        => mul_fft_output,
        value_valid  => mul_fft_output_valid,
        output       => ifft_output,
        output_valid => ifft_output_valid
    );   
            
--- Mul yi table
    mulyi2 : entity work.mulred
    generic map (
        C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
    )
    port map (
        clk         => clk,
        modulus     => prime,
        modulus_r   => prime_r,
        modulus_s   => prime_s,
        a           => ifft_output,
        b           => mul_table(mul_table_out_idx),
        c           => output  
    ); 
        
    state_proc : process (clk) is
        begin	
            if rising_edge(clk) then
                    if (param_valid = '1') then
                        if (param_valid = '1') then
                        fft_param_valid <= '1';
                    end if;                  
                    
                        if (length = mul_table_in_idx - 1) then
                            mul_table_in_idx <= 0;
                        end if;
                        mul_table_in_idx <= mul_table_in_idx + 1;
                        
                        if (fft_output_valid = '1') then
                            if (length = mul_fft_table_idx - 1) then
                                mul_fft_table_idx <= 0;
                            end if;
                            mul_fft_table_idx <= mul_fft_table_idxe_idx + 1;
                        end if;
                        
                        if (ifft_output_valid = '1') then
                            if (length = mul_table_out_idx - 1) then
                                mul_table_out_idxe_idx <= 0;
                            end if;
                            mul_table_out_idx <= mul_table_out_idx + 1;
                        end if;
            end if;
        end process state_proc;
end Behavioral;
