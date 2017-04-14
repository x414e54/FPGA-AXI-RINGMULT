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

entity fft_stage is
	generic (
		C_MAX_FFT_PRIME_WIDTH   : integer    := 64;
		C_STAGE_LENGTH          : integer    := 7710;
        C_STAGE_INDEX           : integer    := 1
	);
	port (
		clk        : in std_logic;
		w_table    : in stage_io(0 to C_STAGE_LENGTH-1)                        := (others => (others => '0'));
		prime      : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
		prime_r    : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');       
        inputs     : in stage_io(0 to C_STAGE_LENGTH-1)                         := (others => (others => '0'));
		outputs    : out stage_io(0 to (2*C_STAGE_LENGTH-1))                    := (others => (others => '0'))
	);  
end fft_stage;

architecture Behavioral of fft_stage is
signal regs_a : stage_io(0 to C_STAGE_LENGTH-1)  := (others => (others => '0'));
signal regs_b : stage_io(0 to C_STAGE_LENGTH-1)  := (others => (others => '0'));
begin

    abswitch_delay : entity work.abswitch_delay
    generic map (
        C_INPUT_LENGTH => C_STAGE_LENGTH,
        C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
    )
    port map (
        clk     => clk,
        in_ab   => inputs,
        out_a   => regs_a,
        out_b   => regs_b
    );

    stage_dits : for i in 0 to C_STAGE_LENGTH-1 generate          
        butterfly_dit_2_i : entity work.butterfly_dit_2
            generic map (
       	       C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH
            )
            port map (
                clk     => clk,
                w       => w_table(i), -- needs to be mux
                a       => regs_a(i),
                b       => regs_b(i),
                x       => outputs(i),
                y       => outputs(i+(C_STAGE_LENGTH/2)),
                prime   => prime,
                prime_r => prime_r
            );
    end generate stage_dits;
    
end Behavioral;
