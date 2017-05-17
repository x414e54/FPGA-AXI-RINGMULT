library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_crt is
    generic (		
        C_PARAM_WIDTH                : integer   := 64;
        C_PARAM_ADDR_WIDTH           : integer   := 32;
        C_PARAM_ADDR_TOP             : integer   := b"0000";
        C_LENGTH_WIDTH               : integer   := 16;	
        C_MAX_FFT_PRIME_WIDTH        : integer   := 64;		
        C_MAX_CRT_PRIME_WIDTH        : integer   := 192; -- 256;	
        C_MAX_FFT_PRIMES             : integer   := 6;--9;
        C_MAX_FFT_PRIMES_FOLDS       : integer   := 1--(256/64)-2--C_MAX_CRT_PRIME_WIDTH/C_MAX_FFT_PRIME_WIDTH - 2
    );
    --port ();
end tb_crt;

architecture behavior of tb_crt is

    type REGISTER_TYPE is array(natural range <>) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    type VALID_TYPE is array(natural range <>) of std_logic;

    signal   stop               : std_logic := '0';
    constant clk_period         : time := 10ns;

    signal clk                  : std_logic := '0';

    --crt       
    signal crt_value           :  std_logic_vector(C_MAX_CRT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal crt_primes          :  REGISTER_TYPE(C_MAX_FFT_PRIMES-1 downto 0) := (others => (others => '0'));
    signal crt_primes_red      :  REGISTER_TYPE(C_MAX_FFT_PRIMES-1 downto 0) := (others => (others => '0'));
    signal crt_prime_len       :  std_logic_vector(16-1 downto 0) := (others => '0');
    signal crt_remainders      :  REGISTER_TYPE(C_MAX_FFT_PRIMES-1 downto 0) := (others => (others => '0'));

    type FOLD_REGISTER_TYPE is array(natural range <>) of REGISTER_TYPE(C_MAX_FFT_PRIMES_FOLDS to 0);

    constant INPUT: std_logic_vector(C_MAX_CRT_PRIME_WIDTH-1 downto 0) := x"00000002c36e5d4e53f1650fd56d99480361ff7e07877040";
    constant OUTPUT: REGISTER_TYPE     := (x"020A2F4F0C26E334", x"0AA23BED8E77C371", x"00C135850F9AAB2C", x"0C3DF3362B816015", x"0EE57F0B945D498D", x"05141BBACDD6E19E");-- x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF");
    constant PRIMES: REGISTER_TYPE     := (x"1000000000000D41", x"1000000000004341", x"1000000000007041", x"10000000000104C1", x"1000000000011FC1", x"1000000000012F81");-- x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF");
    constant PRIMES_RED: REGISTER_TYPE := (x"0FFFFFFFFFFFF2BF", x"0FFFFFFFFFFFBCBF", x"0FFFFFFFFFFF8FBF", x"0FFFFFFFFFFEFB3F", x"0FFFFFFFFFFEE03F", x"0FFFFFFFFFFED07F");-- x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF");
    constant PRIMES_FOLDS: FOLD_REGISTER_TYPE := ((x"00000000AFAA8100", x"FFFFFFFFFFFFFFFF"), (x"00000011AB168100", x"FFFFFFFFFFFFFFFF"), (x"0000003138F08100", x"FFFFFFFFFFFFFFFF"), (x"0000010998998100", x"FFFFFFFFFFFFFFFF"), (x"00000143724F8100", x"FFFFFFFFFFFFFFFF"), (x"00000167D29F0100", x"FFFFFFFFFFFFFFFF"));
                                            --((x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF"), (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF"), (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF"), (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF"), (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF"), 
                                            -- (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF")); (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF"), (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF"), (x"FFFFFFFFFFFFFFFF", x"FFFFFFFFFFFFFFFF"));
    constant PRIME_LEN : integer := 61; 
    
begin
    crt_inst : for i in 0 to C_MAX_FFT_PRIMES - 1 generate
        prime_i : entity work.rem_fold
            generic map (
                C_PARAM_WIDTH       => C_PARAM_WIDTH,
                C_PARAM_ADDR_WIDTH  => C_PARAM_ADDR_WITH,
                C_PARAM_ADDR_TOP    => C_PARAM_ADDR_TOP + i,
                C_LENGTH_WIDTH      => C_LENGTH_WIDTH,	
                C_MAX_MODULUS_WIDTH => C_MAX_FFT_PRIME_WIDTH,
                C_MAX_INPUT_WIDTH   => C_MAX_CRT_PRIME_WIDTH,
                C_MAX_INPUT_LEN     => C_MAX_CRT_PRIME_WIDTH/C_MAX_MODULUS_WIDTH,
                C_MAX_MODULUS_FOLDS => C_MAX_FFT_PRIMES_FOLDS
            )
            port map (
                clk	         => clk,
                param        => crt_param,
                param_addr   => crt_param_addr,
                param_valid  => crt_param_valid,
                modulus      => crt_primes(i),
                modulus_r    => crt_primes_red(i),
                modulus_s    => crt_prime_len,
                value	     => crt_value,
                remainder    => crt_remainders(i)
         );
    end generate crt;
 
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
        end loop;
        		        
        wait until rising_edge(clk);
        
        param_addr <= C_PARAM_ADDR_TOP;
        
        for i in 0 to C_MAX_FFT_PRIMES - 1 loop
            for j in 0 to C_MAX_FFT_PRIMES_FOLDS - 1 loop
                param <= PRIMES_FOLD(i)(j);
                wait until rising_edge(clk);
                param_addr <= param_addr + 1;
            end loop;
        end loop;
        
		crt_value <= INPUT;
        
        wait until rising_edge(clk);
        wait for 500ns;

		for i in 0 to C_MAX_FFT_PRIMES - 1 loop
			assert crt_remainders(i) = OUTPUT(i);
		end loop;

        stop <= '1';
        
        wait;
    end process;

end;