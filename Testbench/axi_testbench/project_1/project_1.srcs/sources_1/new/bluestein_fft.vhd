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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bluestein_fft is
	generic (
		C_MAX_FFT_PRIME_WIDTH   : integer    := 64;
		C_MAX_FFT_LENGTH        : integer    := 7710
	);
	port (
		clk        : in std_logic;
		prime      : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
		prime_r    : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');       
        value      : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
		output     : out std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)    := (others => '0')
	);  
end bluestein_fft;

architecture Behavioral of bluestein_fft is
function reg_index(d : integer) return integer is
    variable res : natural;
begin
    res := (2**d) - 1;
return res;
end function reg_index;

constant NUM_STAGES : integer := 6; 
signal regs : stage_io(0 to reg_index(NUM_STAGES+1))  := (others => (others => '0'));
signal w_table : stage_io(0 to reg_index(NUM_STAGES+1))  := (others => (others => '0'));

begin
    
    regs(0) <= value;
    
    fft_stages : for i in 0 to NUM_STAGES - 1 generate
        stage_i : entity work.fft_stage
            generic map (
                C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH,
                C_STAGE_LENGTH => 2**i,
                C_STAGE_INDEX => i
            )
            port map (
                clk     => clk,
                w_table => w_table(reg_index(i) to (reg_index(i)*2)), -- needs to be mux
                prime   => prime,
                prime_r => prime_r,
                inputs  => regs(reg_index(i) to (reg_index(i)*2)),
                outputs => regs(reg_index(i+1) to (reg_index(i+1)*2))
            );
    end generate fft_stages;
    
end Behavioral;
