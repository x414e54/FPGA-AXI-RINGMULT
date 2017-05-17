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
                    
    type fft_array is array(0 to C_MAX_FFT_LENGTH - 1) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    type fft_table_array is array(0 to C_MAX_FFT_LENGTH - 1) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);

    constant INPUT: fft_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant OUTPUT: fft_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant W_TABLE: fft_table_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant PRIME: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"1000000000000D41");
    constant PRIME_RED: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"0FFFFFFFFFFFF2BF");
    constant PRIME_LEN : integer := 61; 
        
begin

    mulmodfft_inst : entity work.mulmodfft
        generic map (

        )
        port map (
            clk => clk,
                    
            -- Ports of fft
            param          => fft_param,
            param_addr     => fft_param,
            param_valid    => fft_param_valid,
            value          => fft_value,
            value_valid    => fft_value_valid,
            output         => fft_output,
            output_valid   => fft_output_valid
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
        
        fft_prime   <= PRIME;
        fft_prime_r <= PRIME_RED;
        fft_prime_s <= std_logic_vector(to_unsigned(PRIME_LEN, fft_prime_len'length));
        fft_length  <= C_MAX_FFT_LENGTH;
        
        fft_param_addr <= x"00000000";
        
        for i in 0 to C_MAX_FFT_LENGTH - 1 loop   
            fft_param_valid <= '1';
            fft_param <= W_TABLE(i);
            wait until rising_edge(clk);
            fft_param_addr <= fft_param_addr + 1;
        end loop;
        
        fft_param_valid <= '0';
        wait until rising_edge(clk);
        
       
        for i in 0 to C_MAX_FFT_LENGTH - 1 loop
            fft_value_valid <= '1';
        	fft_value <= INPUT(i);
        	wait until rising_edge(clk);
        end loop;
        
        fft_value_valid <= '0';
        
        wait until output_valid = '1';
        
		for i in 0 to C_MAX_FFT_LENGTH - 1 loop
			assert fft_output = OUTPUT(i);
            wait until rising_edge(clk);
		end loop;

        stop <= '1';
        
        wait;
    end process;

end;