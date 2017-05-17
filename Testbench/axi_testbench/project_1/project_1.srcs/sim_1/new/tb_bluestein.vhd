library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fft_stage_pkg.all;

entity tb_bs is
    generic (		
        C_PARAM_WIDTH              : integer   := 64;
        C_PARAM_ADDR_WIDTH         : integer   := 32;
        C_PARAM_ADDR_MUL_TABLE     : integer   := 0;
        C_PARAM_ADDR_MUL_FFT_TABLE : integer   := 1;
        C_PARAM_ADDR_FFT_TABLE     : integer   := 2;
        C_PARAM_ADDR_IFFT_TABLE    : integer   := 3;
        C_LENGTH_WIDTH             : integer   := 16;	
        C_FFT_LENGTH               : integer   := 64;
        C_BLUESTEIN_LENGTH         : integer   := 18;	
        C_MAX_FFT_PRIME_WIDTH      : integer   := 64	
    );
    --port ();
end tb_bs;

architecture behavior of tb_bs is
                        
    signal   stop               : std_logic := '0';
    constant clk_period         : time := 10ns;

    signal clk                  : std_logic := '0';

    --bs       ');
    signal bs_param           :  std_logic_vector(C_PARAM_WIDTH-1 downto 0) := (others => '0');
    signal bs_param_addr      :  std_logic_vector(C_PARAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal bs_param_valid     :  std_logic := '0';
    signal bs_prime           :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal bs_prime_red       :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal bs_prime_len       :  std_logic_vector(C_LENGTH_WIDTH-1 downto 0) := (others => '0');
    signal bs_value           :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal bs_value_valid     :  std_logic := '0';
    signal bs_output          :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal bs_output_valid    :  std_logic := '0';
            
    type bs_array is array(0 to C_MAX_BLUESTEIN_LENGTH - 1) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    type fft_table_array is array(0 to C_MAX_FFT_LENGTH - 1) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    type bs_table_array is array(0 to C_MAX_BLUESTEIN_LENGTH - 1) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);

    constant INPUT: bs_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant OUTPUT: bs_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant W_TABLE: fft_table_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant WI_TABLE: fft_table_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant MUL_TABLE: bs_table_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant MUL_FFT_TABLE: fft_table_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant PRIME: stage_io := (x"1000000000000D41");
    constant PRIME_RED: stage_io := (x"0FFFFFFFFFFFF2BF");
    constant PRIME_LEN : integer := 61; 
        
    alias param_addr_top : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is bs_param_addr(C_PARAM_ADDR_WIDTH-1 downto C_PARAM_ADDR_WIDTH/2);
    alias param_addr_bottom : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is bs_param_addr((C_PARAM_ADDR_WIDTH/2)-1 downto 0);

begin

    bs_inst : entity work.bluestein_fft
        generic map (
            C_PARAM_WIDTH              => C_PARAM_WIDTH,
            C_PARAM_ADDR_WIDTH         => C_PARAM_ADDR_WIDTH,
            C_PARAM_ADDR_MUL_TABLE     => C_PARAM_ADDR_MUL_TABLE,
            C_PARAM_ADDR_MUL_FFT_TABLE => C_PARAM_ADDR_MUL_FFT_TABLE,
            C_PARAM_ADDR_FFT_TABLE     => C_PARAM_ADDR_FFT_TABLE,
            C_PARAM_ADDR_IFFT_TABLE    => C_PARAM_ADDR_IFFT_TABLE,
            C_LENGTH_WIDTH             => C_LENGTH_WIDTH, 
            C_MAX_FFT_LENGTH           => C_MAX_FFT_LENGTH, 
            C_MAX_BLUESTEIN_LENGTH     => C_MAX_BLUESTEIN_LENGTH,
            C_MAX_FFT_PRIME_WIDTH      => C_MAX_FFT_PRIME_WIDTH
        )
        port map (
            clk => clk,
                    
            -- Ports of bluestein_fft
            mode           => bs_mode,
            param          => bs_param,
            param_addr     => bs_param_addr,
            param_valid    => bs_param_valid,
            prime          => bs_prime,
            prime_r        => bs_prime_r,
            prime_s        => bs_prime_len,
            fft_length     => bs_fft_length,
            length         => bs_length,
            value          => bs_value,
            value_valid    => bs_value_valid,
            output         => bs_output,
            output_valid   => bs_output_valid
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
                        
        bs_prime_len <= std_logic_vector(to_unsigned(PRIME_LEN, bs_prime_len'length));
        bs_prime <= PRIME;
        bs_prime_red <= PRIMES_RED;
        bs_fft_length <= C_FFT_LENGTH;
        bs_length <= C_BLUESTEIN_LENGTH;
        
        bs_param_addr_top <= C_PARAM_ADDR_MUL_TABLE;
        bs_param_addr_bottom <= 0;
        
        for i in 0 to C_MAX_BLUESTEIN_LENGTH - 1 loop
            param <= MUL_TABLE(i);
            bs_param_valid <= '1';
            wait until rising_edge(clk);
            bs_param_addr_bottom <= bs_param_addr_bottom + 1;
        end loop;
                   
        bs_param_addr_top <= C_PARAM_ADDR_MUL_FFT_TABLE;
        bs_param_addr_bottom <= 0;
        
        for i in 0 to C_MAX_FFT_LENGTH - 1 loop
            param <= MUL_FFT_TABLE(i);
            bs_param_valid <= '1';
            wait until rising_edge(clk);
            bs_param_addr_bottom <= bs_param_addr_bottom + 1;
        end loop;
                   
        bs_param_addr_top <= C_PARAM_ADDR_FFT_TABLE;
        bs_param_addr_bottom <= 0;
                
        for i in 0 to C_MAX_FFT_LENGTH - 1 loop
            param <= W_TABLE(i);
            bs_param_valid <= '1';
            wait until rising_edge(clk);
            bs_param_addr_bottom <= bs_param_addr_bottom + 1;
        end loop;
                
        bs_param_addr_top <= C_PARAM_ADDR_IFFT_TABLE;
        bs_param_addr_bottom <= 0;
                
        for i in 0 to C_MAX_FFT_LENGTH - 1 loop
            param <= WI_TABLE(i);
            bs_param_valid <= '1';
            wait until rising_edge(clk);
            bs_param_addr_bottom <= bs_param_addr_bottom + 1;
        end loop;
                
        wait until rising_edge(clk);
        
        for i in 0 to C_MAX_BLUESTEIN_LENGTH - 1 loop
        	bs_value <= INPUT(i);
        	bs_value_valid <= '1';
        	wait until rising_edge(clk);
        	bs_value_valid <= '0';
        end loop;
        
        wait until bs_output_valid = '1';

		for i in 0 to C_MAX_BLUESTEIN_LENGTH - 1 loop
			assert bs_output = OUTPUT(i);
            wait until rising_edge(clk);
		end loop;

        stop <= '1';
        
        wait;
    end process;

end;