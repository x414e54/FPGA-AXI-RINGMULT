----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2017/04/03 13:09:21
-- Design Name: 
-- Module Name: fft_stage - Behavioral
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

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fft_stage is
	generic (
	    C_LENGTH_WIDTH          : integer    := 16;
		C_MAX_FFT_PRIME_WIDTH   : integer    := 64;
		C_STAGE_LENGTH          : integer    := 7710;
        C_STAGE_INDEX           : integer    := 1
	);
	port (
		clk        : in std_logic;
		w          : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
		prime      : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
		prime_r    : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
        prime_s    : in std_logic_vector(C_LENGTH_WIDTH-1 downto 0)          := (others => '0');        
        input      : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
		output     : out std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0')
	);  
end fft_stage;

architecture Behavioral of fft_stage is

    type REGISTER_TYPE is array(natural range <>) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    
    signal regs : REGISTER_TYPE(0 to 8-1)  := (others => (others => '0'));

    signal dif_0_shift : REGISTER_TYPE(0 to (C_STAGE_LENGTH/2)-1)  := (others => (others => '0'));
    signal dif_1_shift : REGISTER_TYPE(0 to (C_STAGE_LENGTH/4)-1)  := (others => (others => '0'));

begin
  
--- 0    
    butterfly_dif_2_0 : entity work.butterfly_dif_22
        generic map (
            C_LENGTH_WIDTH        => C_LENGTH_WIDTH,
            C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH
        )
        port map (
            clk     => clk,
            a       => input,
            b       => dif_0_shift(0),
            x       => regs(1),
            y       => regs(0),
            prime   => prime,
            prime_r => prime_r,
            prime_s => prime_s
        );   
                
    abswitch_delay_0_0 : entity work.abswitch
        generic map (
            C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
        )
        port map (
            clk    => clk,
            in_a   => input,
            in_b   => regs(0),
            out_ab => dif_0_shift((C_STAGE_LENGTH/2)-1)
        );
                
    abswitch_delay_0_1 : entity work.abswitch
        generic map (
            C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
        )
        port map (
            clk    => clk,
            in_a   => dif_0_shift(0),
            in_b   => regs(1),
            out_ab => regs(2)
        );
    
--- 1
    butterfly_dif_2_1_0 : entity work.butterfly_dif_22
        generic map (
            C_LENGTH_WIDTH        => C_LENGTH_WIDTH,
            C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH
        )
        port map (
            clk     => clk,
            a       => regs(2),
            b       => dif_1_shift(0),
            x       => regs(4),
            y       => regs(3),
            prime   => prime,
            prime_r => prime_r,
            prime_s => prime_s
        );   
    
    abswitch_delay_0 : entity work.abswitch
    generic map (
        C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
    )
    port map (
        clk    => clk,
        in_a   => regs(4),
        in_b   => regs(3),
        out_ab => dif_1_shift((C_STAGE_LENGTH/4)-1)
    );
    
    abswitch_delay_1 : entity work.abswitch
    generic map (
        C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
    )
    port map (
        clk    => clk,
        in_a   => regs(4),
        in_b   => dif_1_shift(0),
        out_ab => regs(5)
    );

--- twiddle
    twiddle_mul : entity work.mulred
    generic map (
        C_LENGTH_WIDTH      => C_LENGTH_WIDTH,
        C_MAX_MODULUS_WIDTH => C_MAX_FFT_PRIME_WIDTH
    )
    port map (
        clk         => clk,
        modulus     => prime,
        modulus_r   => prime_r,
        modulus_s   => prime_s,
        a           => regs(5),
        b           => w,
        c           => output  
    );
    
    shift_proc : process (clk) is
    begin	
        if rising_edge(clk) then
            for i in 0 to (C_STAGE_LENGTH/2)-2 loop
                dif_0_shift(i) <= dif_0_shift(i+1);
            end loop;
            for i in 0 to (C_STAGE_LENGTH/4)-2 loop
                dif_1_shift(i) <= dif_1_shift(i+1);
            end loop; 
        end if;
    end process shift_proc;
end Behavioral;
