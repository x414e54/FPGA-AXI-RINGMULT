library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_crt is
    generic (		
        C_MAX_FFT_PRIME_WIDTH        : integer   := 64;		
        C_MAX_CRT_PRIME_WIDTH        : integer   := 256;	
        C_MAX_FFT_PRIMES             : integer   := 9;
    );
    --port ();
end tb_crt;

architecture behavior of tb_crt is
                        
        signal   stop               : std_logic := '0';
        constant clk_period         : time := 10ns;

        signal clk                  : std_logic := '0';
        signal reset                : std_logic := '1';

        -- crt
        signal crt_val        :  std_logic_vector(C_MAX_CRT_PRIME_WIDTH-1 downto 0) := (others => '0');
        signal crt_rem        :  crt_bus(C_MAX_FFT_PRIMES-1 downto 0)(C_MAX_FFT_PRIME_WIDTH-1 downto 0)  := (others => (others => '0'));
        signal crt_enabled    :  std_logic := '0';

        signal stop  		  : boolean;

        type int_array is array(0 to 8) of integer;

		constant INPUT: integer := 2111111111111111111111111111111111111111111111111111;
        constant OUTPUT: int_array := (0, 1, 2, 3, 4, 5, 6, 7, 8);      
begin

    crt_inst : entity work.crt
        generic map (
            C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH,
            C_MAX_CRT_PRIME_WIDTH => C_MAX_CRT_PRIME_WIDTH,
            C_MAX_FFT_PRIMES => C_MAX_FFT_PRIMES
        )
        port map (
            clk => clk,
            reset => reset,
                    
            -- Ports of CRT
            clk => clk,
            val => crt_val,
			enabled = crt_enabled,
            rem => crt_rem,
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
        reset <= '0';
        wait until falling_edge(clk);
        reset <= '1';
        wait until rising_edge(clk);
        
		crt_val <= INPUT;
        
        wait until rising_edge(clk);

		for i 0 to C_MAX_FFT_PRIMES
			assert crt_rem(i) = std_logic_vector(to_unsigned(OUTPUT(i), C_MAX_FFT_PRIME_WIDTH));
		end

        stop <= '1';
        
        wait;
    end process;

end;