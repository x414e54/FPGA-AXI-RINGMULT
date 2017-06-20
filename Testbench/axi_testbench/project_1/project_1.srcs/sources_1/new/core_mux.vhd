----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/19/2017 02:01:53 PM
-- Design Name: 
-- Module Name: red_simd_core_mux - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity red_simd_core_mux is
	generic (
	   C_MAX_SIMD_WIDTH    : integer   := 4;
	   C_MAX_DATA_WIDTH    : integer   := 256;
       C_LENGTH_WIDTH      : integer   := 16
    );
    port (
        clk     : in std_logic;
        ---
        prime   : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
        prime_r : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
        prime_i : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
        prime_s : in std_logic_vector(C_LENGTH_WIDTH-1 downto 0);
        --- 
        mode    : in std_logic_vector(4-1 downto 0);
        a       : in std_logic_vector(C_MAX_SIMD_WIDTH*C_MAX_DATA_WIDTH-1 downto 0);
        a_valid : in std_logic;
        b       : in std_logic_vector(C_MAX_SIMD_WIDTH*C_MAX_DATA_WIDTH-1 downto 0);
        b_valid : in std_logic;
        c       : out std_logic_vector(C_MAX_SIMD_WIDTH*C_MAX_DATA_WIDTH-1 downto 0);
        c_valid : out std_logic
    );
end red_simd_core_mux;

architecture Behavioral of red_simd_core_mux is

    type REGISTER_TYPE is array(natural range <>) of std_logic_vector(C_MAX_SIMD_WIDTH*C_MAX_DATA_WIDTH-1 downto 0);
    type VALID_TYPE is array(natural range <>) of std_logic;
    
    constant NUM_MUX    : integer := 3;
    constant MUX_TO_ADD : integer := 0;
    constant MUX_TO_SUB : integer := 1;
    constant MUX_TO_MUL : integer := 2;
    
    signal mux_mode : std_logic_vector(4-1 downto 0);
    signal mux_mode_i : integer := 0;
 
    signal mux_out   : REGISTER_TYPE(NUM_MUX downto 0) := (others => (others => '0'));
    signal mux_valid : VALID_TYPE(NUM_MUX downto 0) := (others => '0');
    
    signal delay : integer := 0;  
    constant mulred_delay : integer := 3*18; -- TODO: This is only for USE_CORE = true and when using DSP48
    
begin

    c <= mux_out(mux_mode_i);
    c_valid <= mux_valid(mux_mode_i);
    
    add_core_inst : entity work.add_core
        generic map (
            C_MAX_DATA_WIDTH => C_MAX_DATA_WIDTH
        )
        port map (
            clk => clk,
            a   => a,
            b   => b,
            q   => prime,
            c   => mux_out(MUX_TO_ADD)
        );  

    sub_core_inst : entity work.sub_core
        generic map (
            C_MAX_DATA_WIDTH => C_MAX_DATA_WIDTH
        )
        port map (
            clk => clk,
            a   => a,
            b   => b,
            q   => prime,
            c   => mux_out(MUX_TO_SUB)
        );  
        
    mulcore_inst : entity work.mulred
        generic map (
            C_LENGTH_WIDTH      => C_LENGTH_WIDTH,
            C_MAX_MODULUS_WIDTH => C_MAX_DATA_WIDTH,
            C_USE_CORE          => true
        )
        port map (
            clk         => clk,
            modulus     => prime,
            modulus_r   => prime_r,
            modulus_s   => prime_s,
            a           => a,
            b           => b,
            c           => mux_out(MUX_TO_SUB)
        );
        
    state_proc : process (clk) is
        begin    
            if rising_edge(clk) then
                if (delay = 0) then
                    mux_mode_i <= integer(mux_mode);
                end if;
                if (a_valid = '1' and b_valid = '1' and mux_mode_i = MUX_TO_MUL) then
                    delay = mulred_delay;
                else if (delay = 1) then
                    delay <= 0;
                else
                    delay <= delay - 1;
                end if;
            end if;
        end process state_proc;
end Behavioral;
