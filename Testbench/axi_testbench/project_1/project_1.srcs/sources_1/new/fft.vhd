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
use IEEE.MATH_REAL.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fft is
	generic (
        C_PARAM_WIDTH           : integer   := 64;
        C_PARAM_ADDR_WIDTH      : integer   := 32;
        C_PARAM_ADDR_FFT_TABLE  : integer   := 0;
        C_LENGTH_WIDTH          : integer   := 16;	
		C_MAX_FFT_PRIME_WIDTH   : integer   := 64;
		C_MAX_FFT_LENGTH        : integer   := 16384
	);
	port (
		clk            : in std_logic;  
		----
        param          : in std_logic_vector(C_PARAM_WIDTH-1 downto 0)             := (others => '0');
        param_addr     : in std_logic_vector(C_PARAM_ADDR_WIDTH-1 downto 0)        := (others => '0');
        param_valid    : in std_logic                                               := '0';
        ----
        prime          : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        prime_r        : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        prime_i        : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        prime_s        : in std_logic_vector(C_LENGTH_WIDTH-1 downto 0)            := (others => '0'); 
        length         : in std_logic_vector(C_LENGTH_WIDTH-1 downto 0)            := (others => '0'); 
        ----
        value          : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        value_valid    : in std_logic                                               := '0';
		output         : out std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)    := (others => '0');
		output_valid   : out std_logic                                              := '0'
	);  
end fft;
    
architecture Behavioral of fft is

    type REGISTER_TYPE is array(natural range <>) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    type ADDR_TYPE is array(natural range <>) of std_logic_vector(C_LENGTH_WIDTH-1 downto 0);

    constant NUM_STAGES : integer := integer(ceil(log2(real(C_MAX_FFT_LENGTH))))/2; 

    signal counter : unsigned(C_LENGTH_WIDTH-1 downto 0) := (others => '0');

    signal w_table : REGISTER_TYPE(0 to (C_MAX_FFT_LENGTH + 3) - 1)  := (others => (others => '0'));

    signal w_val   : REGISTER_TYPE(0 to NUM_STAGES-1)        := (others => (others => '0'));    
    signal regs    : REGISTER_TYPE(0 to NUM_STAGES)        := (others => (others => '0'));

    alias param_addr_top : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is param_addr(C_PARAM_ADDR_WIDTH-1 downto C_PARAM_ADDR_WIDTH/2);
    alias param_addr_bottom : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is param_addr((C_PARAM_ADDR_WIDTH/2)-1 downto 0);
    
begin
    
    regs(0) <= value;
    output <= regs(NUM_STAGES);
    
    fft_stages : for i in 0 to NUM_STAGES - 1 generate
                
                -- need to rotate idx NS-1 and -2 to be -2 and -1 etc
        w_val(i) <= w_table(to_integer((unsigned(counter((2*NUM_STAGES-1-(2*i)) downto (2*NUM_STAGES-2-(2*i)))))*(unsigned(counter((2*NUM_STAGES-3-(2*i)) downto 0)))));
        
        stage_i : entity work.fft_stage
            generic map (
                C_LENGTH_WIDTH => C_LENGTH_WIDTH,
                C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH,
                C_STAGE_LENGTH => 2**(2*(NUM_STAGES-i)),
                C_STAGE_INDEX => i
            )
            port map (
                clk      => clk,
                w        => w_val(i),
                switches => std_logic_vector(counter((2*NUM_STAGES-1-(2*i)) downto (2*NUM_STAGES-2-(2*i)))),
                prime    => prime,
                prime_r  => prime_r,
                prime_i  => prime_i,
                prime_s  => prime_s,
                input    => regs(i),
                output   => regs(i+1)
            );
    end generate fft_stages;
        
    state_proc : process (clk) is
        begin	
            if rising_edge(clk) then
                if (param_valid = '1' and to_integer(unsigned(param_addr_top)) = C_PARAM_ADDR_FFT_TABLE) then
                    w_table(to_integer(unsigned(param_addr_bottom))) <= param;
                end if;
                if (value_valid = '1') then
                    if (counter = unsigned(length) - 1) then
                        counter <= (others => '0');
                    else
                        counter <= counter + 1;
                    end if;
                end if;
            end if;
        end process state_proc;
end Behavioral;
