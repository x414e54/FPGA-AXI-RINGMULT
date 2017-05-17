library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_mulmodfft is
    generic (	
	    C_PARAM_WIDTH                        : integer   := 64;
        C_PARAM_ADDR_WIDTH                   : integer   := 32;
        ---
        C_LENGTH_WIDTH                       : integer   := 16;	
		C_MAX_FFT_PRIME_WIDTH                : integer   := 64;
        C_MAX_FFT_LENGTH                     : integer   := 16384; 
        C_MAX_POLY_LENGTH                    : integer   := 7710; 
		C_MAX_CRT_PRIME_WIDTH                : integer   := 256; 
		C_MAX_FFT_PRIMES		             : integer   := 9;
		C_MAX_FFT_PRIMES_FOLDS               : integer   := (256/64)-2;--C_MAX_CRT_PRIME_WIDTH / C_MAX_FFT_PRIME_WIDTH - 2
		---
		C_PARAM_ADDR_MUL_TABLE_START         : integer := x"0000";
        C_PARAM_ADDR_FFT_TABLE_START         : integer := C_PARAM_ADDR_MUL_TABLE_START + C_MAX_FFT_PRIMES;
        C_PARAM_ADDR_IFFT_TABLE_START        : integer := C_PARAM_ADDR_FFT_TABLE_START + C_MAX_FFT_PRIMES;
        C_PARAM_ADDR_BS_MUL_TABLE_START      : integer := C_PARAM_ADDR_IFFT_TABLE_START + C_MAX_FFT_PRIMES;
        C_PARAM_ADDR_BS_MUL_FFT_TABLE_START  : integer := C_PARAM_ADDR_BS_MUL_TABLE_START + C_MAX_FFT_PRIMES;
        C_PARAM_ADDR_IBS_MUL_TABLE_START     : integer := C_PARAM_ADDR_BS_MUL_FFT_TABLE_START + C_MAX_FFT_PRIMES;
        C_PARAM_ADDR_IBS_MUL_FFT_TABLE_START : integer := C_PARAM_ADDR_IBS_MUL_TABLE_START + C_MAX_FFT_PRIMES;
        C_PARAM_ADDR_FOLDS_START             : integer := C_PARAM_ADDR_IBS_MUL_FFT_TABLE_START + C_MAX_FFT_PRIMES
        ---
    );
    --port ();
end tb_fft;

architecture behavior of tb_mulmodfft is
                        
    signal   stop               : std_logic := '0';
    constant clk_period         : time := 10ns;

    signal clk                  : std_logic := '0';

    -- mm
    signal mm_param           :  std_logic_vector(C_PARAM_WIDTH-1 downto 0) := (others => '0');
    signal mm_param_addr      :  std_logic_vector(C_PARAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal mm_param_valid     :  std_logic := '0';
    signal mm_value           :  std_logic_vector(C_MAX_CRT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal mm_value_valid     :  std_logic := '0';
    signal mm_output          :  std_logic_vector(C_MAX_CRT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal mm_output_valid    :  std_logic := '0';
                        
    type mm_table is array(0 to C_MAX_POLY_LENGTH-1) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    type mm_table_array is array(0 to C_MAX_FFT_PRIMES-1) of mm_table;
    type bs_table_array is array(0 to C_MAX_FFT_PRIMES-1) of mm_table;
    type fft_table is array(0 to C_MAX_FFT_LENGTH-1) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    type fft_table_array is array(0 to C_MAX_FFT_PRIMES-1) of fft_table;
    type prime_array is array(0 to C_MAX_FFT_PRIMES-1) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);

    constant INPUT: mm_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant OUTPUT: mm_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    
    constant MUL_TABLE: mm_table_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant W_TABLE: fft_table_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant WI_TABLE: fft_table_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant BS_MUL_TABLE: bs_table_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant BS_MUL_FFT_TABLE: fft_table_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant IBS_MUL_TABLE: bs_table_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant IBS_MUL_FFT_TABLE: fft_table_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    
    constant PRIMES: prime_array := (x"1000000000000D41");
    constant PRIMES_RED: prime_array := (x"0FFFFFFFFFFFF2BF");
    constant PRIME_LEN : integer := 61; 
                
    alias param_addr_top : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is mm_param_addr(C_PARAM_ADDR_WIDTH-1 downto C_PARAM_ADDR_WIDTH/2);
    alias param_addr_bottom : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is mm_param_addr((C_PARAM_ADDR_WIDTH/2)-1 downto 0);
        
begin

    mulmodfft_inst : entity work.mulmodfft
        generic map (
            C_PARAM_WIDTH                        => C_PARAM_WIDTH,
            C_PARAM_ADDR_WIDTH                   => C_PARAM_ADDR_WIDTH,
            ---
            C_LENGTH_WIDTH                       => C_LENGTH_WIDTH,	
            C_MAX_FFT_PRIME_WIDTH                => C_MAX_FFT_PRIME_WIDTH,
            C_MAX_FFT_LENGTH                     => C_MAX_FFT_LENGTH, 
            C_MAX_POLY_LENGTH                    => C_MAX_POLY_LENGTH, 
            C_MAX_CRT_PRIME_WIDTH                => C_MAX_CRT_PRIME_WIDTH, 
            C_MAX_FFT_PRIMES		             => C_MAX_FFT_PRIMES,
            C_MAX_FFT_PRIMES_FOLDS               => C_MAX_FFT_PRIMES_FOLDS,
            ---
            C_PARAM_ADDR_MUL_TABLE_START         => C_PARAM_ADDR_MUL_TABLE_START,
            C_PARAM_ADDR_FFT_TABLE_START         => C_PARAM_ADDR_FFT_TABLE_START,
            C_PARAM_ADDR_IFFT_TABLE_START        => C_PARAM_ADDR_IFFT_TABLE_START,
            C_PARAM_ADDR_BS_MUL_TABLE_START      => C_PARAM_ADDR_BS_MUL_TABLE_START,
            C_PARAM_ADDR_BS_MUL_FFT_TABLE_START  => C_PARAM_ADDR_BS_MUL_FFT_TABLE_START,
            C_PARAM_ADDR_IBS_MUL_TABLE_START     => C_PARAM_ADDR_IBS_MUL_TABLE_START,
            C_PARAM_ADDR_IBS_MUL_FFT_TABLE_START => C_PARAM_ADDR_IBS_MUL_FFT_TABLE_START,
            C_PARAM_ADDR_FOLDS_START             => C_PARAM_ADDR_FOLDS_START
            ---
        )
        port map (
            clk => clk,
                    
            -- Ports of fft
            param          => mm_param,
            param_addr     => mm_param_addr,
            param_valid    => mm_param_valid,
            value          => mm_value,
            value_valid    => mm_value_valid,
            output         => mm_output,
            output_valid   => mm_output_valid
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
            --bs_prime_len <= std_logic_vector(to_unsigned(PRIME_LEN, bs_prime_len'length));
            --bs_prime <= PRIME;
            --bs_prime_red <= PRIMES_RED;
            --bs_fft_length <= C_FFT_LENGTH;
            --bs_length <= C_BLUESTEIN_LENGTH;

            bs_param_addr_top <= C_PARAM_ADDR_MUL_TABLE + i;
            bs_param_addr_bottom <= 0;

            for j in 0 to C_MAX_POLY_LENGTH - 1 loop
                param <= MUL_TABLE(j)(i);
                mm_param_valid <= '1';
                wait until rising_edge(clk);
                bs_param_addr_bottom <= bs_param_addr_bottom + 1;
            end loop;
    
            bs_param_addr_top <= C_PARAM_ADDR_BS_MUL_TABLE + i;
            bs_param_addr_bottom <= 0;

            for j in 0 to C_MAX_POLY_LENGTH - 1 loop
                param <= BS_MUL_TABLE(j)(i);
                mm_param_valid <= '1';
                wait until rising_edge(clk);
                bs_param_addr_bottom <= bs_param_addr_bottom + 1;
            end loop;
                        
            bs_param_addr_top <= C_PARAM_ADDR_BS_MUL_FFT_TABLE + i;
            bs_param_addr_bottom <= 0;

            for j in 0 to C_MAX_FFT_LENGTH - 1 loop
                param <= BS_MUL_FFT_TABLE(j)(i);
                mm_param_valid <= '1';
                wait until rising_edge(clk);
                bs_param_addr_bottom <= bs_param_addr_bottom + 1;
            end loop;

            bs_param_addr_top <= C_PARAM_ADDR_IBS_MUL_TABLE + i;
            bs_param_addr_bottom <= 0;

            for j in 0 to C_MAX_POLY_LENGTH - 1 loop
                param <= IBS_MUL_TABLE(j)(i);
                mm_param_valid <= '1';
                wait until rising_edge(clk);
                bs_param_addr_bottom <= bs_param_addr_bottom + 1;
            end loop;
                        
            bs_param_addr_top <= C_PARAM_ADDR_IBS_MUL_FFT_TABLE + i;
            bs_param_addr_bottom <= 0;

            for j in 0 to C_MAX_FFT_LENGTH - 1 loop
                param <= IBS_MUL_FFT_TABLE(j)(i);
                mm_param_valid <= '1';
                wait until rising_edge(clk);
                bs_param_addr_bottom <= bs_param_addr_bottom + 1;
            end loop;

            bs_param_addr_top <= C_PARAM_ADDR_FFT_TABLE + i;
            bs_param_addr_bottom <= 0;
 
            for j in 0 to C_MAX_FFT_LENGTH - 1 loop
                param <= W_TABLE(j)(i);
                mm_param_valid <= '1';
                wait until rising_edge(clk);
                bs_param_addr_bottom <= bs_param_addr_bottom + 1;
            end loop;
 
            bs_param_addr_top <= C_PARAM_ADDR_IFFT_TABLE + i;
            bs_param_addr_bottom <= 0;
 
            for j in 0 to C_MAX_FFT_LENGTH - 1 loop
                param <= WI_TABLE(j)(i);
                mm_param_valid <= '1';
                wait until rising_edge(clk);
                bs_param_addr_bottom <= bs_param_addr_bottom + 1;
            end loop;
 
            wait until rising_edge(clk);

            param_addr_top <= C_PARAM_ADDR_FOLDS_START + i;
            param_addr_bottom <= x"0000";
            
            for j in 0 to C_MAX_FFT_PRIMES_FOLDS - 1 loop
                param <= PRIMES_FOLD(i)(j);
                wait until rising_edge(clk);
                param_addr_bottom <= param_addr_bottom + 1;
            end loop;                
        end loop;
        
        mm_param_valid <= '0';
        wait until rising_edge(clk);
               
        for i in 0 to C_MAX_POLY_LENGTH - 1 loop
            mm_value_valid <= '1';
        	mm_value <= INPUT(i);
        	wait until rising_edge(clk);
        end loop;
        
        mm_value_valid <= '0';
        
        wait until mm_output_valid = '1';
        
		for i in 0 to C_MAX_POLY_LENGTH - 1 loop
			assert mm_output = OUTPUT(i);
            wait until rising_edge(clk);
		end loop;

        stop <= '1';
        
        wait;
    end process;

end;