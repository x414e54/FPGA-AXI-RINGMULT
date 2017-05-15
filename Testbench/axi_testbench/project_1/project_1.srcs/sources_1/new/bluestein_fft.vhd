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
		mode              : in std_logic_vector(4-1 downto 0)     := (others => '0');	
        param             : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        param_valid       : in std_logic;
        value             : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
		output            : out std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)    := (others => '0');
		output_valid       : out std_logic
	);  
end bluestein_fft;

architecture Behavioral of bluestein_fft is

type REGISTER_TYPE is array(natural range <>) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    
type STATE_TYPE is (IDLE, LOAD_BLUESTEIN_LENGTH, LOAD_PRIME, LOAD_PRIME_R, LOAD_PRIME_S, LOAD_FFT_TABLE, LOAD_IFFT_TABLE, LOAD_MUL_TABLE, LOAD_MUL_FFT_TABLE, RUN);
    
constant NUM_STAGES : integer := integer(ceil(log2(real(C_MAX_FFT_LENGTH)))); 

constant MODE_LOAD_PARAMS : std_logic_vector(4-1 downto 0) := b"0001";
constant MODE_RUN         : std_logic_vector(4-1 downto 0) := b"0010";

signal state                : STATE_TYPE;
    
signal length  : unsigned := (others => '0');
signal prime   : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
signal prime_r : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
signal prime_s : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');

signal mul_table_in_idx      : unsigned := (others => '0');
signal mul_table_out_idx     : unsigned := (others => '0');
signal mul_fft_table_idx     : unsigned := (others => '0');

signal mul_table : REGISTER_TYPE(0 to C_MAX_FFT_LENGTH)  := (others => (others => '0'));
signal mul_fft_table : REGISTER_TYPE(0 to C_MAX_FFT_LENGTH)  := (others => (others => '0'));
 
signal fft_mode : std_logic_vector(4-1 downto 0)     := (others => '0');
signal fft_param : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
signal fft_param_valid : std_logic     := '0';
signal fft_output : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
signal fft_output_valid : std_logic     := '0';

signal ifft_mode : std_logic_vector(4-1 downto 0)     := (others => '0');
signal ifft_param : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
signal ifft_param_valid : std_logic     := '0';
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
        C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH
    )
    port map (
        clk          => clk,
        mode         => fft_mode,	
        param        => fft_param,
        param_valid  => fft_param_valid,
        value        => mul_output,
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
        C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH
    )
    port map (
        clk     => clk,       
        mode         => ifft_mode,	
        param        => ifft_param,
        param_valid  => ifft_param_valid,
        value        => mul_fft_output,
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
        b           => mul_table_val(mul_table_out_idx),
        c           => output  
    ); 
        
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
                            state <= LOAD_FFT_LENGTH;
                        end if;     
                                          
                    when LOAD_FFT_LENGTH =>
                        if (param_valid = '1') then
                            fft_param_valid <= '1';
                            ifft_param_valid <= '1';
                            state <= LOAD_PRIME;
                        end if;
                                                
                    when LOAD_PRIME =>
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
                            state <= IDLE;
                        end if;
                                                                                        
                    when LOAD_FFT_TABLE =>
                        if (param_valid = '1') then
                            fft_param_valid <= '1';
                            state <= IDLE;
                        end if;
                        
                    when LOAD_IFFT_TABLE =>
                        if (param_valid = '1') then
                            ifft_param_valid <= '1';
                            state <= LOAD_MUL_TABLE;
                        end if;
                    
                    when LOAD_MUL_TABLE =>
                        if (param_valid = '1') then
                            prime_s <= param;
                            state <= LOAD_MUL_TABLE;
                        end if;
                    
                    when LOAD_MUL_FFT_TABLE =>
                        if (param_valid = '1') then
                            prime_s <= param;
                            state <= IDLE;
                        end if;    
                                                                                                              
                    when RUN =>
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
                end case;
            end if;
        end process state_proc;
end Behavioral;
