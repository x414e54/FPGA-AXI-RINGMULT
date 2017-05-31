library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_red is
    generic (
        C_LENGTH_WIDTH           : integer   := 16;
        C_MAX_FFT_PRIME_WIDTH    : integer   := 64;
        C_USE_CORE               : boolean   := true
    );
    --port ();
end tb_red;

architecture behavior of tb_red is
                        
    signal   stop               : std_logic := '0';
    constant clk_period         : time := 10ns;

    signal clk                  : std_logic := '0';

    -- red
    signal red_modulus        :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal red_modulus_r      :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal red_modulus_s      :  std_logic_vector(C_LENGTH_WIDTH-1 downto 0) := (others => '0');
    signal red_value          :  std_logic_vector(2*C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal red_remainder      :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
                    
    constant INPUT: std_logic_vector(2*C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"002988d35c17ccdda67050354bb1d768");
    constant OUTPUT: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"08A3091C329CDDAB");
                                    
    constant PRIME: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"10000000000007a1");
    constant PRIME_RED: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"0FFFFFFFFFFFF85f");
    constant PRIME_I: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"081a85435318023a");
    constant PRIME_LEN : integer := 61; 
            
begin

    core : if C_USE_CORE = true generate
        red_core_inst : entity work.red_core
            generic map (
                C_LENGTH_WIDTH         => C_LENGTH_WIDTH,
                C_MAX_MODULUS_WIDTH    => C_MAX_FFT_PRIME_WIDTH,
                C_MAX_INPUT_WIDTH      => 2*C_MAX_FFT_PRIME_WIDTH
            )
            port map (
                clk => clk,
                        
                -- Ports of red
                modulus     => red_modulus,
                modulus_r   => red_modulus_r,
                modulus_s   => red_modulus_s,
                value       => red_value, 
                remainder   => red_remainder
            );  
    end generate core;
    
    non_core : if C_USE_CORE = false generate
        red_inst : entity work.red
            generic map (
                C_LENGTH_WIDTH         => C_LENGTH_WIDTH,
                C_MAX_MODULUS_WIDTH    => C_MAX_FFT_PRIME_WIDTH,
                C_MAX_INPUT_WIDTH      => 2*C_MAX_FFT_PRIME_WIDTH
            )
            port map (
                clk => clk,
                        
                -- Ports of red
                modulus     => red_modulus,
                modulus_r   => red_modulus_r,
                modulus_s   => red_modulus_s,
                value       => red_value, 
                remainder   => red_remainder
            );  
    end generate non_core;
        
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
        if stop = '1' then
            wait;
        end if;
    end process;
        
    stimulus : process
    begin
        wait until rising_edge(clk);
        
        red_modulus   <= PRIME;
        red_modulus_r <= PRIME_RED;
        red_modulus_s <= std_logic_vector(to_unsigned(PRIME_LEN, C_LENGTH_WIDTH));
            
        red_value <= INPUT;           
        
        wait for clk_period * 37;     
        
        assert red_remainder = OUTPUT;

        stop <= '1';
        
        wait;
    end process;

end;