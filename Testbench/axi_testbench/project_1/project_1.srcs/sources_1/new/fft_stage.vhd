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
--  NTT Implementation of "A New Approach to Pipeline FFT Processor" by Shousheng He and Mats Torkelson
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
		switches   : in std_logic_vector(2-1 downto 0)                       := (others => '0');
		prime      : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
		prime_r    : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
        prime_i    : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
        prime_s    : in std_logic_vector(C_LENGTH_WIDTH-1 downto 0)          := (others => '0');        
        input      : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
		output     : out std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0')
	);  
end fft_stage;

architecture Behavioral of fft_stage is

    type REGISTER_TYPE is array(natural range <>) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    
    signal regs : REGISTER_TYPE(0 to 8-1)  := (others => (others => '0'));

    signal switch_1 : std_logic := '0';
    signal switch_2 : std_logic := '0';
    signal switch_3 : std_logic := '0';
        
    signal input_reg  : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
        
    signal dif_0_shift_in  : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    signal dif_0_shift_out : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    signal dif_1_shift_in  : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    signal dif_1_shift_out : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');

    constant butterfly_delay : integer := 2;
    
begin

    input_reg <= input;
    switch_1 <= switches(1);
    switch_2 <= switches(0);
    switch_3 <= (not switch_1) and switch_2;
     
--- 0
                    
    dif_0_shift : entity work.delay
        generic map (
    		C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH,
    		C_DELAY		      => C_STAGE_LENGTH/2 - 1
        )
        port map (
            clk       => clk,
            i         => dif_0_shift_in,
            o         => dif_0_shift_out
        );
        
    butterfly_dif_2_0 : entity work.butterfly_dif_22
        generic map (
            C_LENGTH_WIDTH        => C_LENGTH_WIDTH,
            C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH
        )
        port map (
            clk     => clk,
            a       => input_reg,
            b       => dif_0_shift_out,
            x       => regs(1),
            y       => regs(0),
            prime   => prime,
            prime_r => prime_r,
            prime_s => prime_s
        );   
                
    abswitch_0_0 : entity work.abswitch
        generic map (
            C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
        )
        port map (
            clk    => clk,
            switch => switch_1,
            in_a   => input_reg,
            in_b   => regs(0),
            out_ab => dif_0_shift_in
        );
                
    abswitch_0_1 : entity work.abswitch
        generic map (
            C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
        )
        port map (
            clk    => clk,
            switch => switch_1,
            in_a   => dif_0_shift_out,
            in_b   => regs(1),
            out_ab => regs(2)
        );
    
 --- twiddle i
    i_mul : entity work.mulred
        generic map (
            C_LENGTH_WIDTH      => C_LENGTH_WIDTH,
            C_MAX_MODULUS_WIDTH => C_MAX_FFT_PRIME_WIDTH
        )
        port map (
            clk         => clk,
            modulus     => prime,
            modulus_r   => prime_r,
            modulus_s   => prime_s,
            a           => regs(2),
            b           => prime_i,
            c           => regs(3)  
        );
      
    abswitch_0_2 : entity work.abswitch
        generic map (
            C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
        )
        port map (
            clk    => clk,
            switch => switch_3,
            in_a   => regs(2),
            in_b   => regs(3),
            out_ab => regs(4)
        );
--- 1
    switch2_delay : entity work.delay2
    generic map (
        C_DELAY		      => 8
    )
    port map (
        clk       => clk,
        i         => switches(1),
        o         => switch_2
    );
    
    dif_1_shift : entity work.delay
        generic map (
		    C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH,
		    C_DELAY		      => C_STAGE_LENGTH/4 - 1
        )
        port map (
            clk       => clk,
            i         => dif_1_shift_in,
            o         => dif_1_shift_out
        );
    
    butterfly_dif_2_1_0 : entity work.butterfly_dif_22
        generic map (
            C_LENGTH_WIDTH        => C_LENGTH_WIDTH,
            C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH
        )
        port map (
            clk     => clk,
            a       => regs(4),
            b       => dif_1_shift_out,
            x       => regs(6),
            y       => regs(5),
            prime   => prime,
            prime_r => prime_r,
            prime_s => prime_s
        );   
    
    abswitch_0 : entity work.abswitch
    generic map (
        C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
    )
    port map (
        clk    => clk,
        switch => switch_2,
        in_a   => regs(6),
        in_b   => regs(5),
        out_ab => dif_1_shift_in
    );
    
    abswitch_1 : entity work.abswitch
    generic map (
        C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
    )
    port map (
        clk    => clk,
        switch => switch_2,
        in_a   => regs(6),
        in_b   => dif_1_shift_out,
        out_ab => regs(7)
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
        a           => regs(7),
        b           => w,
        c           => output  
    );
end Behavioral;
