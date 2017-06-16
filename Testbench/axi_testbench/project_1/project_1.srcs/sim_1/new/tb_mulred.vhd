library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mulred is
    generic (
        C_LENGTH_WIDTH           : integer   := 16;
        C_MAX_FFT_PRIME_WIDTH    : integer   := 64;
        C_USE_CORE               : boolean   := true
    );
    --port ();
end tb_mulred;

architecture behavior of tb_mulred is
                        
    signal   stop               : std_logic := '0';
    constant clk_period         : time := 10ns;

    signal clk                  : std_logic := '0';

    -- mulred
    signal mr_modulus        :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal mr_modulus_r      :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal mr_modulus_s      :  std_logic_vector(C_LENGTH_WIDTH-1 downto 0) := (others => '0');
    signal mr_a              :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal mr_b              :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal mr_c              :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
                    
    --constant INPUT: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"07E3289AF6E2EAA0");
    --constant OUTPUT: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"082AA6303118D119");
    constant INPUT_A: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"0fd1993b46be49de");
    constant INPUT_B: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"08524e3b9736ec6f");
    constant OUTPUT: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"002695a122bce814");
                                    
    constant PRIME: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"100000000e1e0001");
    constant PRIME_RED: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"0ffffffff1e1ffff");
    constant PRIME_I: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"081A85435318023A");
    constant PRIME_LEN : integer := 61; 
            
begin

    i_mul : entity work.mulred
        generic map (
            C_LENGTH_WIDTH      => C_LENGTH_WIDTH,
            C_MAX_MODULUS_WIDTH => C_MAX_FFT_PRIME_WIDTH,
            C_USE_CORE          => C_USE_CORE
        )
        port map (
            clk         => clk,
            modulus     => mr_modulus,
            modulus_r   => mr_modulus_r,
            modulus_s   => mr_modulus_s,
            a           => mr_a,
            b           => mr_b,
            c           => mr_c
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
        
        mr_modulus   <= PRIME;
        mr_modulus_r <= PRIME_RED;
        mr_modulus_s <= std_logic_vector(to_unsigned(PRIME_LEN, C_LENGTH_WIDTH));
            
        mr_a <= INPUT_A;   
        mr_b <= INPUT_B;           
        
        wait until rising_edge(clk);
        mr_a <= PRIME_I;   
         
        wait for clk_period * (3 * 18);   
        
        assert mr_c = OUTPUT;

        stop <= '1';
        
        wait;
    end process;

end;