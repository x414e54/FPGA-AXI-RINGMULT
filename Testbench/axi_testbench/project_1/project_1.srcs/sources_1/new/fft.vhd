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
        C_PARAM_WIDTH           : integer   := 64;
        C_PARAM_ADDR_WIDTH      : integer   := 32;
        C_PARAM_ADDR_FFT_TABLE  : integer   := x"0000";
        C_LENGTH_WIDTH          : integer   := 16;	
		C_MAX_FFT_PRIME_WIDTH   : integer   := 64;
		C_MAX_FFT_LENGTH        : integer   := 16384
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
        length         : in std_logic_vector(C_LENGTH_WIDTH-1 downto 0)            := (others => '0'); 
        ----
        value          : in std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)     := (others => '0');
        value_valid    : in std_logic;
		output         : out std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)    := (others => '0');
		output_valid   : out std_logic
	);  
end fft;

architecture Behavioral of fft is

    type REGISTER_TYPE is array(natural range <>) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    
    function reg_index(d : integer) return integer is
        variable res : natural;
        begin
            res := (2**d) - 1;
        return res;
    end function reg_index;

    constant NUM_STAGES : integer := integer(ceil(log2(real(C_MAX_FFT_LENGTH)))); 

    signal counter : integer := 0;
    signal length  : integer := 0;

    signal w_table : REGISTER_TYPE(0 to (C_MAX_FFT_LENGTH + 3) - 1)  := (others => (others => '0'));

    signal w_val   : REGISTER_TYPE(0 to NUM_STAGES)        := (others => (others => '0'));    
    signal regs    : REGISTER_TYPE(0 to NUM_STAGES)        := (others => (others => '0'));

    alias param_addr_top : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is param_addr(C_PARAM_ADDR_WIDTH-1 downto C_PARAM_ADDR_WIDTH/2);
    alias param_addr_bottom : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is param_addr((C_PARAM_ADDR_WIDTH/2)-1 downto 0);

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
                if (param_valid = '1' and param_addr_top = C_PARAM_ADDR_FFT_TABLE) then
                    w_table(param_addr_bottom) <= param;
                end if;
                --if (value_valid = '1')
                --if (length = w_table_write_idx - 1) then
                  --              w_table_write_idx <= 0;
     --                       w_table_write_idx <= w_table_write_idx + 1;
--                        end if;  
                                  
  --                      if (counter = length - 1) then
    --                        counter <= 0;
      --                  end if;
        --                counter <= counter + 1;
            end if;
        end process state_proc;
end Behavioral;
