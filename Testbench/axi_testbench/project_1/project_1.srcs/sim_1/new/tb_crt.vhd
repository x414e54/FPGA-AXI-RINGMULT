library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.crt_pkg.all;

entity tb_crt is
    generic (		
        C_MAX_FFT_PRIME_WIDTH        : integer   := 64;		
        C_MAX_CRT_PRIME_WIDTH        : integer   := 256;	
        C_MAX_FFT_PRIMES             : integer   := 9
    );
    --port ();
end tb_crt;

architecture behavior of tb_crt is
                        
        signal   stop               : std_logic := '0';
        constant clk_period         : time := 10ns;

        signal clk                  : std_logic := '0';

        -- crt       
        signal crt_enabled    :  std_logic := '0';
        signal crt_value      :  std_logic_vector(C_MAX_CRT_PRIME_WIDTH-1 downto 0) := (others => '0');
        signal crt_primes     :  crt_bus(C_MAX_FFT_PRIMES-1 downto 0) := (others => (others => '0'));
        signal crt_remainders :  crt_bus(C_MAX_FFT_PRIMES-1 downto 0) := (others => (others => '0'));

        type int_array is array(0 to 8) of integer;

		constant INPUT: std_logic_vector(C_MAX_CRT_PRIME_WIDTH-1 downto 0) := x"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
        constant OUTPUT: crt_bus := (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF");
        constant PRIMES: crt_bus := (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF"); 
begin

    crt_inst : entity work.crt
        generic map (
            C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH,
            C_MAX_CRT_PRIME_WIDTH => C_MAX_CRT_PRIME_WIDTH,
            C_MAX_FFT_PRIMES => C_MAX_FFT_PRIMES
        )
        port map (
            clk => clk,
                    
            -- Ports of CRT
            enabled    => crt_enabled,
            value      => crt_value,
            primes     => crt_primes,
            remainders => crt_remainders
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
                
        for i in 0 to C_MAX_FFT_PRIMES - 1 loop
            crt_primes <= primes(i);
        end loop;
        		        
        wait until rising_edge(clk);
        
        crt_enabled <= '1';
		crt_value <= INPUT;
        
        wait until rising_edge(clk);

		for i in 0 to C_MAX_FFT_PRIMES - 1 loop
			assert crt_remainders(i) = OUTPUT(i);
		end loop;

        stop <= '1';
        
        wait;
    end process;

end;