----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2017/04/03 13:09:21
-- Design Name: 
-- Module Name: fft - Behavioral
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

entity fft is
	generic (
		C_MAX_FFT_PRIME_WIDTH   : integer    := 64;
		C_MAX_FFT_LENGTH        : integer    := 7710
	);
	port (
		clk          : in std_logic;  
        mode         : in std_logic_vector(4-1 downto 0)     := (others => '0');
        param        : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        param_valid  : in std_logic;
        value        : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
		output       : out std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)    := (others => '0');
		output_valid : out std_logic
	);  
end fft;

architecture Behavioral of fft is

type REGISTER_TYPE is array(natural range <>) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    
type STATE_TYPE is (IDLE, LOAD_FFT_LENGTH, LOAD_PRIME, LOAD_PRIME_R, LOAD_PRIME_S, LOAD_FFT_TABLE, RUN);
    
function reg_index(d : integer) return integer is
    variable res : natural;
begin
    res := (2**d) - 1;
return res;
end function reg_index;

constant NUM_STAGES : integer := integer(ceil(log2(real(C_MAX_FFT_LENGTH)))); 

constant MODE_RESET       : std_logic_vector(4-1 downto 0) := b"0000";
constant MODE_LOAD_PARAMS : std_logic_vector(4-1 downto 0) := b"0001";
constant MODE_RUN         : std_logic_vector(4-1 downto 0) := b"0010";

signal state                : STATE_TYPE;
    
signal counter : unsigned := (others => '0');
signal length  : unsigned := (others => '0');
signal prime   : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
signal prime_r : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
signal prime_s : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');

signal w_table : REGISTER_TYPE(0 to C_MAX_FFT_LENGTH)  := (others => (others => '0'));

signal w_val   : REGISTER_TYPE(0 to NUM_STAGES)        := (others => (others => '0'));    
signal regs    : REGISTER_TYPE(0 to NUM_STAGES)        := (others => (others => '0'));

begin
    
    regs(0) <= value;
    output <= regs(NUM_STAGES);
    
    fft_stages : for i in 0 to NUM_STAGES - 1 generate
        stage_i : entity work.fft_stage
            generic map (
                C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH,
                C_STAGE_LENGTH => 2**(NUM_STAGES-1-i),
                C_STAGE_INDEX => i
            )
            port map (
                clk     => clk,
                w       => w_val(i),
                prime   => prime,
                prime_r => prime_r,
                prime_s => prime_s,
                input   => regs(i),
                output  => regs(i+1)
            );
    end generate fft_stages;
    
    state_proc : process (clk) is
        begin	
            if rising_edge(clk) then
                case state is
                    when IDLE =>
                        case mode is
                            when MODE_LOAD_PARAMS =>
                                state <= LOAD_FFT_LENGTH;
                            when MODE_RUN =>
                                state <= RUN;
                            end case;
                        
                    when LOAD_FFT_LENGTH =>
                         if (param_valid = '1') then
                             length <= unsigned(param);
                             state <= LOAD_PRIME;
                         end if;
                                                
                    when LOAD_PRIME =>
                        if (param_valid = '1') then
                            prime <= param;
                            state <= LOAD_PRIME_R;
                        end if;
                        
                    when LOAD_PRIME_R =>
                         if (param_valid = '1') then
                             prime_r <= param;
                             state <= LOAD_PRIME_S;
                         end if;
                         
                    when LOAD_PRIME_S =>
                        if (param_valid = '1') then
                            prime_s <= param;
                            state <= IDLE;
                        end if;
                                                                     
                    when RUN =>
                        if (mode = MODE_RESET) then
                            counter <= 0;
                            state <= IDLE;
                        end if;
                        
                        if (counter = length - 1) then
                            counter <= 0;
                        end if;
                        counter <= counter + 1;
                end case;
            end if;
        end process state_proc;
end Behavioral;
