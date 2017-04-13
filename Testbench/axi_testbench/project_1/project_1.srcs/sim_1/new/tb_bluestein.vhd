library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.bs_pkg.all;

entity tb_bs is
    generic (		
        C_MAX_FFT_LENGTH             : integer   := 18;
        C_MAX_FFT_PRIME_WIDTH        : integer   := 64;		
        C_MAX_FFT_PRIMES             : integer   := 1
    );
    --port ();
end tb_bs;

architecture behavior of tb_bs is
                        
        signal   stop               : std_logic := '0';
        constant clk_period         : time := 10ns;

        signal clk                  : std_logic := '0';

        -- bs       
        signal bs_enabled         :  std_logic := '0';
        signal bs_values          :  bs_bus(C_MAX_FFT_PRIMES-1 downto 0) := (others => (others => '0'));
        signal bs_primes          :  bs_bus(C_MAX_FFT_PRIMES-1 downto 0) := (others => (others => '0'));
        signal bs_primes_red      :  bs_bus(C_MAX_FFT_PRIMES-1 downto 0) := (others => (others => '0'));
        signal bs_prime_len       :  std_logic_vector(16-1 downto 0) := (others => '0');
        signal bs_output          :  bs_bus(C_MAX_FFT_PRIMES-1 downto 0) := (others => (others => '0'));

        type fft_array is array(0 to C_MAX_FFT_LENGTH - 1) of integer;

		constant INPUT: fft_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
        constant OUTPUT: fft_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
        constant PRIMES: bs_bus := (x"1000000000000D41", x"1000000000004341", x"1000000000007041", x"10000000000104C1", x"1000000000011FC1", x"1000000000012F81");
        constant PRIMES_RED: bs_bus := (x"0FFFFFFFFFFFF2BF", x"0FFFFFFFFFFFBCBF", x"0FFFFFFFFFFF8FBF", x"0FFFFFFFFFFEFB3F", x"0FFFFFFFFFFEE03F", x"0FFFFFFFFFFED07F");
        constant PRIME_LEN : integer := 61; 
begin

    bs_inst : entity work.bs
        generic map (
            C_MAX_FFT_LENGTH       => C_MAX_FFT_LENGTH,
            C_MAX_FFT_PRIME_WIDTH  => C_MAX_FFT_PRIME_WIDTH,
            C_MAX_FFT_PRIMES       => C_MAX_FFT_PRIMES
        )
        port map (
            clk => clk,
                    
            -- Ports of bs
            enabled      => bs_enabled,
            values       => bs_values,
            primes       => bs_primes,
            primes_red   => bs_primes_red,
            primes_folds => bs_primes_folds,
            prime_len    => bs_prime_len,
            outputs      => bs_outputs
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
                        
        crt_prime_len <= std_logic_vector(to_unsigned(PRIME_LEN, crt_prime_len'length));
        
        for i in 0 to C_MAX_FFT_PRIMES - 1 loop
            bs_primes(i) <= PRIMES(i);
            bs_primes_red(i) <= PRIMES_RED(i);
        end loop;
        		        
        wait until rising_edge(clk);
        
        bs_enabled <= '1';
        for i in 0 to C_MAX_FFT_LENGTH - 1 loop
        	bs_values(0) <= INPUT(i);
        	wait until rising_edge(clk);
        end loop;
        
        wait until rising_edge(clk);
        wait for 500ns;

		for i in 0 to C_MAX_FFT_LENGTH - 1 loop
			assert bs_outputs(0) = OUTPUT(i);
            wait until rising_edge(clk);
		end loop;

        stop <= '1';
        
        wait;
    end process;

end;