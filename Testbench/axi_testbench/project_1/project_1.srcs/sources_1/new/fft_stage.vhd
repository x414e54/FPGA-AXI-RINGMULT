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
        C_STAGE_INDEX           : integer    := 1;
        C_USE_CORE              : boolean    := true
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

    signal bf_0_x : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    signal bf_0_y : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    signal substage_0_out : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    signal substage_0_out_delay : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    
    signal mul_i : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    
    signal substage_1_in : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    signal bf_1_x : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    signal bf_1_y : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    signal substage_1_out : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');

    signal switch_1 : std_logic := '0';
    signal switch_2 : std_logic := '0';
    signal switch_3 : std_logic := '0';
    signal switch_3_tmp : std_logic := '0';
        
    signal input_reg  : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
        
    signal dif_0_shift_in  : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    signal dif_0_shift_out : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    signal dif_1_shift_in  : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    signal dif_1_shift_out : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => '0');
    
    constant mulred_delay : integer := 3*18; -- TODO: This is only for USE_CORE = true and when using DSP48
    
begin

    input_reg <= input;
    switch_1 <= switches(1);
     
    switch_2_delay : entity work.delay2
        generic map (
            C_DELAY => mulred_delay
        )
        port map (
            clk       => clk,
            i         => switches(0),
            o         => switch_2
        );
     
    switch_3_tmp <= ((not switches(1)) and switches(0));
    
    switch_3_delay : entity work.delay2
        generic map (
            C_DELAY => mulred_delay
        )
        port map (
            clk       => clk,
            i         => switch_3_tmp,
            o         => switch_3
        );
--- 0
                    
    dif_0_shift : entity work.delay
        generic map (
    		C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH,
    		C_DELAY		      => C_STAGE_LENGTH/2
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
            x       => bf_0_x,
            y       => bf_0_y,
            prime   => prime
        );   
                
    abswitch_0_0 : entity work.abswitch
        generic map (
            C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
        )
        port map (
            clk    => clk,
            switch => switch_1,
            in_a   => input_reg,
            in_b   => bf_0_y,
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
            in_b   => bf_0_x,
            out_ab => substage_0_out
        );
    
--- twiddle i
    i_mul : entity work.mulred
        generic map (
            C_LENGTH_WIDTH      => C_LENGTH_WIDTH,
            C_MAX_MODULUS_WIDTH => C_MAX_FFT_PRIME_WIDTH,
            C_USE_CORE          => C_USE_CORE
        )
        port map (
            clk         => clk,
            modulus     => prime,
            modulus_r   => prime_r,
            modulus_s   => prime_s,
            a           => substage_0_out,
            b           => prime_i,
            c           => mul_i
        );
      
    no_i_mul_delay : entity work.delay
        generic map (
            C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH,
            C_DELAY           => mulred_delay
        )
        port map (
            clk       => clk,
            i         => substage_0_out,
            o         => substage_0_out_delay
        );  
            
    abswitch_0_2 : entity work.abswitch
        generic map (
            C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
        )
        port map (
            clk    => clk,
            switch => switch_3,
            in_a   => substage_0_out_delay,
            in_b   => mul_i,
            out_ab => substage_1_in
        );
--- 1    
    dif_1_shift : entity work.delay
        generic map (
		    C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH,
		    C_DELAY		      => C_STAGE_LENGTH/4
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
            a       => substage_1_in,
            b       => dif_1_shift_out,
            x       => bf_1_x,
            y       => bf_1_y,
            prime   => prime
        );   
    
    abswitch_1_0 : entity work.abswitch
        generic map (
            C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
        )
        port map (
            clk    => clk,
            switch => switch_2,
            in_a   => substage_1_in,
            in_b   => bf_1_y,
            out_ab => dif_1_shift_in
        );
    
    abswitch_1_1 : entity work.abswitch
    generic map (
        C_MAX_INPUT_WIDTH => C_MAX_FFT_PRIME_WIDTH
    )
    port map (
        clk    => clk,
        switch => switch_2,
        in_a   => dif_1_shift_out,
        in_b   => bf_1_x,
        out_ab => substage_1_out
    );

--- twiddle
    twiddle_mul : entity work.mulred
    generic map (
        C_LENGTH_WIDTH      => C_LENGTH_WIDTH,
        C_MAX_MODULUS_WIDTH => C_MAX_FFT_PRIME_WIDTH,
        C_USE_CORE          => C_USE_CORE
    )
    port map (
        clk         => clk,
        modulus     => prime,
        modulus_r   => prime_r,
        modulus_s   => prime_s,
        a           => substage_1_out,
        b           => w,
        c           => output  
    );
end Behavioral;
