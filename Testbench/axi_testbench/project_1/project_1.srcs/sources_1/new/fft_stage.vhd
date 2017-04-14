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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package fft_stage_pkg is
	type stage_io is array(natural range <>) of std_logic_vector(64-1 downto 0);
end package;

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

entity fft_stage is
	generic (
		C_MAX_FFT_PRIME_WIDTH   : integer    := 64;
		C_STAGE_LENGTH          : integer    := 7710;
        C_STAGE_INDEX           : integer    := 1;
	);
	port (
		clk        : in std_logic;
		w_table    : in stage_io(C_STAGE_LENGTH/2 downto 0)                       := (others => (others => '0'));
		prime      : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
		prime_r    : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');       
        inputs     : in stage_io(C_STAGE_LENGTH downto 0)                         := (others => (others => '0'));
		outputs    : out stage_io(2 * C_STAGE_LENGTH downto 0)                    := (others => '0')
	);  
end fft_stage;

architecture Behavioral of fft_stage is
type fft_array is (2 * C_STAGE_LENGTH downto 0) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
signal regs : fft_array  := (others => (others => (others => '0')));
begin

    abswitch_delay : entity work.abswitch_delay
    generic map (
        C_INPUT_LENGTH => C_STAGE_LENGTH,
        C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
    )
    port map (
        clk     => clk,
        in_ab   => inputs,
        out_a   => regs(0),
        out_b   => regs()
    );

    stage_dits : for i in 0 to C_STAGE_LENGTH generate          
        butterfly_dit_2_i : entity work.butterfly_dit_2
            generic map (
       	       C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH
            )
            port map (
                clk     => clk,
                w       => w_table(C_STAGE_INDEX+j), -- needs to be mux
                a       => regs(j,i),
                b       => regs(j,i+1),
                x       => outputs(i),
                y       => outputs(i),
                prime   => prime,
                prime_r => prime_r
            );
    end generate stage_dits;
    
end Behavioral;
