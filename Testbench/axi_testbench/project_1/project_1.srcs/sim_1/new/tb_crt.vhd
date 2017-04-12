library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.crt_pkg.all;
use work.rem_pkg.all;

entity tb_crt is
    generic (		
        C_MAX_FFT_PRIME_WIDTH        : integer   := 64;		
        C_MAX_CRT_PRIME_WIDTH        : integer   := 162; -- 256;	
        C_MAX_FFT_PRIMES             : integer   := 6;--9;
        C_MAX_FFT_PRIMES_FOLDS       : integer   := 1;--(256/64)-2--C_MAX_CRT_PRIME_WIDTH/C_MAX_FFT_PRIME_WIDTH - 2
    );
    --port ();
end tb_crt;

architecture behavior of tb_crt is
                        
        signal   stop               : std_logic := '0';
        constant clk_period         : time := 10ns;

        signal clk                  : std_logic := '0';

        -- crt       
        signal crt_enabled         :  std_logic := '0';
        signal crt_value           :  std_logic_vector(C_MAX_CRT_PRIME_WIDTH-1 downto 0) := (others => '0');
        signal crt_primes          :  crt_bus(C_MAX_FFT_PRIMES-1 downto 0) := (others => (others => '0'));
        signal crt_primes_red      :  crt_bus(C_MAX_FFT_PRIMES-1 downto 0) := (others => (others => '0'));
        signal crt_primes_folds    :  crt_bus_2(C_MAX_FFT_PRIMES-1 downto 0) := (others => (others => (others => '0')));
        signal crt_prime_len       :  std_logic_vector(16-1 downto 0) := (others => '0');
        signal crt_remainders      :  crt_bus(C_MAX_FFT_PRIMES-1 downto 0) := (others => (others => '0'));

        type int_array is array(0 to 8) of integer;

		constant INPUT: std_logic_vector(C_MAX_CRT_PRIME_WIDTH-1 downto 0) := x"2c36e5d4e53f1650fd56d99480361ff7e07877040";
        constant OUTPUT: crt_bus := (x"20A2F4F0C26E334", x"AA23BED8E77C371", x"C135850F9AAB2C", x"882128516018167829", x"EE57F0B945D498D", x"5141BBACDD6E19E");-- x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF");
        constant PRIMES: crt_bus := (x"1000000000000D41", x"1000000000004341", x"1000000000007041", x"10000000000104C1", x"1000000000011FC1", x"1000000000012F81");-- x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF");
        constant PRIMES_RED: crt_bus := (x"FFFFFFFFFFFF2BF", x"FFFFFFFFFFFBCBF", x"FFFFFFFFFFF8FBF", x"FFFFFFFFFFEFB3F", x"FFFFFFFFFFEE03F", x"FFFFFFFFFFED07F");-- x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF");
        constant PRIMES_FOLDS: crt_bus_2 := ((x"AFAA8100", x"11AB168100", x"3138F08100", x"10998998100", x"143724F8100", x"167D29F0100"));
                                            --((x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF"), (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF"), (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF"), (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF"), (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF"), 
                                            -- (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF")); (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF"), (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF"), (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF"));
        constant PRIME_LEN : integer := 60; 
begin

    crt_inst : entity work.crt
        generic map (
            C_MAX_FFT_PRIME_WIDTH  => C_MAX_FFT_PRIME_WIDTH,
            C_MAX_CRT_PRIME_WIDTH  => C_MAX_CRT_PRIME_WIDTH,
            C_MAX_FFT_PRIMES       => C_MAX_FFT_PRIMES,
            C_MAX_FFT_PRIMES_FOLDS => C_MAX_FFT_PRIMES_FOLDS
        )
        port map (
            clk => clk,
                    
            -- Ports of CRT
            enabled      => crt_enabled,
            value        => crt_value,
            primes       => crt_primes,
            primes_red   => crt_primes_red,
            primes_folds => crt_primes_folds,
            prime_len    => crt_prime_len,
            remainders   => crt_remainders
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
            crt_primes(i) <= PRIMES(i);
            crt_primes_red(i) <= PRIMES_RED(i);
            crt_primes_folds(i) <= PRIMES_FOLDS(i);
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