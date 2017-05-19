----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2017/04/03 13:09:21
-- Design Name: 
-- Module Name: bluestein_fft - Behavioral
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
	    C_PARAM_WIDTH              : integer   := 64;
        C_PARAM_ADDR_WIDTH         : integer   := 32;
        C_PARAM_ADDR_MUL_TABLE     : integer   := 0;
        C_PARAM_ADDR_MUL_FFT_TABLE : integer   := 1;
        C_PARAM_ADDR_FFT_TABLE     : integer   := 2;
        C_PARAM_ADDR_IFFT_TABLE    : integer   := 3;
        C_LENGTH_WIDTH             : integer   := 16;	
		C_MAX_FFT_PRIME_WIDTH      : integer   := 64;
    	C_MAX_BLUESTEIN_LENGTH     : integer   := 7710; 
		C_MAX_FFT_LENGTH           : integer   := 16384 
	);
	port (
		clk            : in std_logic;
		----
        param          : in std_logic_vector(C_PARAM_WIDTH-1 downto 0)             := (others => '0');
        param_addr     : in std_logic_vector(C_PARAM_ADDR_WIDTH-1 downto 0)        := (others => '0');
        param_valid    : in std_logic;
        ----
        prime          : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        prime_r        : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        prime_s        : in std_logic_vector(C_LENGTH_WIDTH-1 downto 0)            := (others => '0'); 
        fft_length     : in std_logic_vector(C_LENGTH_WIDTH-1 downto 0)            := (others => '0'); 
        length         : in std_logic_vector(C_LENGTH_WIDTH-1 downto 0)            := (others => '0'); 
        ----
        value          : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        value_valid    : in std_logic;
		output         : out std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)    := (others => '0');
		output_valid   : out std_logic
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
    signal mul_output_valid : std_logic     := '0';
    signal mul_fft_output : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal mul_fft_output_valid : std_logic     := '0';

    alias param_addr_top : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is param_addr(C_PARAM_ADDR_WIDTH-1 downto C_PARAM_ADDR_WIDTH/2);
    alias param_addr_bottom : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is param_addr((C_PARAM_ADDR_WIDTH/2)-1 downto 0);

begin
    
--- Mul yi table
    mulyi : entity work.mulred
    generic map (
        C_LENGTH_WIDTH      => C_LENGTH_WIDTH,
        C_MAX_MODULUS_WIDTH => C_MAX_FFT_PRIME_WIDTH
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
        C_PARAM_WIDTH          => C_PARAM_WIDTH,
        C_PARAM_ADDR_WIDTH     => C_PARAM_ADDR_WIDTH,
        C_PARAM_ADDR_FFT_TABLE => C_PARAM_ADDR_FFT_TABLE,
        C_LENGTH_WIDTH         => C_LENGTH_WIDTH,	
        C_MAX_FFT_PRIME_WIDTH  => C_MAX_FFT_PRIME_WIDTH,
        C_MAX_FFT_LENGTH       => C_MAX_FFT_LENGTH
    )
    port map (
        clk          => clk,
        ---
        param        => param,
        param_addr   => param_addr,
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
        C_LENGTH_WIDTH      => C_LENGTH_WIDTH,
        C_MAX_MODULUS_WIDTH => C_MAX_FFT_PRIME_WIDTH
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
        C_PARAM_WIDTH          => C_PARAM_WIDTH,
        C_PARAM_ADDR_WIDTH     => C_PARAM_ADDR_WIDTH,
        C_PARAM_ADDR_FFT_TABLE => C_PARAM_ADDR_IFFT_TABLE,
        C_LENGTH_WIDTH         => C_LENGTH_WIDTH,	
        C_MAX_FFT_PRIME_WIDTH  => C_MAX_FFT_PRIME_WIDTH,
        C_MAX_FFT_LENGTH       => C_MAX_FFT_LENGTH
    )
    port map (
        clk          => clk,
        ---
        param        => param,
        param_addr   => param_addr,
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
        C_LENGTH_WIDTH      => C_LENGTH_WIDTH,
        C_MAX_MODULUS_WIDTH => C_MAX_FFT_PRIME_WIDTH
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
                if (param_valid = '1' and to_integer(unsigned(param_addr_top)) = C_PARAM_ADDR_MUL_TABLE) then
                    mul_table(to_integer(unsigned(param_addr_bottom))) <= param;
                elsif (param_valid = '1' and to_integer(unsigned(param_addr_top)) = C_PARAM_ADDR_MUL_FFT_TABLE) then
                    mul_fft_table(to_integer(unsigned(param_addr_bottom))) <= param;
                end if;             
                
                if (value_valid = '1') then
                    if (mul_table_in_idx - 1 = length) then
                        mul_table_in_idx <= 0;
                    else
                        mul_table_in_idx <= mul_table_in_idx + 1;
                    end if;
                end if;
                        
                if (fft_output_valid = '1') then
                    if (mul_fft_table_idx - 1 = fft_length) then
                        mul_fft_table_idx <= 0;
                    else
                        mul_fft_table_idx <= mul_fft_table_idx + 1;
                    end if;
                end if;
                
                if (ifft_output_valid = '1') then
                    if (mul_table_out_id - 1 = length) then
                        mul_table_out_idxe_idx <= 0;
                    else
                        mul_table_out_idx <= mul_table_out_idx + 1;
                    end if;
                end if;
            end if;
        end process state_proc;
end Behavioral;
