library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_butterfly is
    generic (
        C_LENGTH_WIDTH           : integer   := 16;
        C_MAX_FFT_PRIME_WIDTH    : integer   := 64
    );
    --port ();
end tb_butterfly;

architecture behavior of tb_butterfly is
                        
    signal   stop               : std_logic := '0';
    constant clk_period         : time := 10ns;

    signal clk                  : std_logic := '0';

    -- butterfly
    signal bf_a               :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal bf_b               :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal bf_x               :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal bf_y               :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal bf_prime           :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
                    
    constant A: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"0000000000000200");
    constant B: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"1000000000000798");
    constant X: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"00000000000001f7");
    constant Y: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"0000000000000209");
                                    
    constant PRIME: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"10000000000007a1");
    constant PRIME_I: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"081a85435318023a");
    constant PRIME_LEN : integer := 61; 
            
begin

    butterfly_inst : entity work.butterfly_dif_22
        generic map (
            C_LENGTH_WIDTH         => C_LENGTH_WIDTH,
            C_MAX_FFT_PRIME_WIDTH  => C_MAX_FFT_PRIME_WIDTH
        )
        port map (
            clk => clk,
                    
            -- Ports of butterfly
            a       => bf_a,
            b       => bf_b,
            x       => bf_x,
            y       => bf_y, 
            prime   => bf_prime
        );  

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
        
        bf_prime   <= PRIME;
            
        bf_a <= A;
        bf_b <= B;            
        
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        
        assert bf_x = X;
        assert bf_y = Y;

        stop <= '1';
        
        wait;
    end process;

end;