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
use work.fft_stage_pkg.all;

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
		clk           : in std_logic;
		prime         : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
		prime_r       : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');  
        prime_s       : in std_logic_vector(16-1 downto 0)                        := (others => '0');        
        w_table       : in stage_io(0 to C_MAX_FFT_LENGTH-1)                         := (others => (others => '0'));          
        wi_table      : in stage_io(0 to C_MAX_FFT_LENGTH-1)                         := (others => (others => '0'));  
        mul_table     : in stage_io(0 to C_MAX_BLUESTEIN_LENGTH-1)                   := (others => (others => '0'));          
        mul_fft_table : in stage_io(0 to C_MAX_FFT_LENGTH-1)                         := (others => (others => '0'));  
        value         : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
		output        : out std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)    := (others => '0')
	);  
end bluestein_fft;

architecture Behavioral of bluestein_fft is

signal table_idx : integer := 0;

signal mul_output : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
signal fft_output : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
signal mul_fft_output : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
signal ifft_output : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)    := (others => '0');

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
        b           => mul_table(table_idx),
        c           => mul_output  
    );

--- Forward FFT    
    forward_fft : entity work.fft
    generic map (
        C_MAX_FFT_LENGTH      => C_MAX_FFT_LENGTH,
        C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH
    )
    port map (
        clk     => clk,
        prime   => prime,
        prime_r => prime_r,
        prime_s => prime_s,
        w_table => w_table,
        value   => mul_output,
        output  => fft_output
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
        b           => mul_fft_table(table_idx),
        c           => mul_fft_output  
    );
    
--- Reverse FFT    
    inverse_fft : entity work.fft
    generic map (
        C_MAX_FFT_LENGTH      => C_MAX_FFT_LENGTH,
        C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH
    )
    port map (
        clk     => clk,
        prime   => prime,
        prime_r => prime_r,
        prime_s => prime_s,
        w_table => wi_table,
        value   => mul_fft_output,
        output  => ifft_output
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
        b           => mul_table(table_idx),
        c           => output  
    ); 
     --< C_M
end Behavioral;
