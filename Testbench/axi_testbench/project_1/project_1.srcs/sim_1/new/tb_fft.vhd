library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fft is
    generic (	
        C_PARAM_WIDTH            : integer   := 64;
        C_PARAM_ADDR_WIDTH       : integer   := 32;
        C_PARAM_ADDR_FFT_TABLE   : integer   := 0;
        C_LENGTH_WIDTH           : integer   := 16;
        C_MAX_FFT_PRIME_WIDTH    : integer   := 64;	
        C_FFT_LENGTH             : integer   := 64	
    );
    --port ();
end tb_fft;

architecture behavior of tb_fft is
                        
    signal   stop               : std_logic := '0';
    constant clk_period         : time := 10ns;

    signal clk                  : std_logic := '0';

    -- fft
    signal fft_param           :  std_logic_vector(C_PARAM_WIDTH-1 downto 0) := (others => '0');
    signal fft_param_addr      :  std_logic_vector(C_PARAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal fft_param_valid     :  std_logic := '0';
    signal fft_prime           :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal fft_prime_r         :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal fft_prime_i         :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal fft_prime_s         :  std_logic_vector(C_LENGTH_WIDTH-1 downto 0) := (others => '0');
    signal fft_length          :  std_logic_vector(C_LENGTH_WIDTH-1 downto 0) := (others => '0');
    signal fft_value           :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal fft_value_valid     :  std_logic := '0';
    signal fft_output          :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal fft_output_valid    :  std_logic := '0';
                    
    constant FFT_TABLE_LENGTH: integer := (3*((C_FFT_LENGTH/4)-1)) + 1;
    type fft_array is array(0 to C_FFT_LENGTH - 1) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    type fft_table_array is array(0 to FFT_TABLE_LENGTH - 1) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);

    constant INPUT: fft_array := (x"05da70c865fceff8", x"0a1996af809f5eea", x"0eb3e56f9f718027", x"0e2ebeb634481c01", x"0488b321b3b901b8", x"0000000000000001", x"059cdc15e64a1b91", x"07b7aa9a4b189f97", x"0eb3e56f9f718027", x"07b7aa9a4b189f97", x"059cdc15e64a1b91", x"0000000000000001", x"0488b321b3b901b8", x"0e2ebeb634481c01", x"0eb3e56f9f718027", x"0a1996af809f5eea", x"05da70c865fceff8", x"0000000000000001", x"05da70c865fceff8", x"0a1996af809f5eea", x"0eb3e56f9f718027", x"0e2ebeb634481c01", x"0488b321b3b901b8", x"0000000000000001", x"059cdc15e64a1b91", x"07b7aa9a4b189f97", x"0eb3e56f9f718027", x"07b7aa9a4b189f97", x"059cdc15e64a1b91", x"0000000000000001", x"0488b321b3b901b8", x"0e2ebeb634481c01", x"0eb3e56f9f718027", x"0a1996af809f5eea", x"05da70c865fceff8", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant OUTPUT: fft_array := (x"0837609dbca8beaa", x"0837609dbca8bea0", x"0eb3e56f9f718027", x"014c1a90608e8d1a", x"0a150adea428b242", x"0276070b0887d0ef", x"05b5d7d85a6f80e3", x"031c993208c546c5", x"072e504d3da22e8b", x"006f0447128500c4", x"0e1299a07c1a2c3a", x"0b168274ccfb1715", x"0784c05fa8fefc94", x"097c79d1afc18e62", x"084976f64cfcc19c", x"06af0a05ee847109", x"0aa7550a72633120", x"0df34b59eb84e426", x"0deec8ac512665c9", x"007e0e37dd51cf34", x"06ab4355042b5273", x"09a56c98c05d0615", x"081211d72c2cc26e", x"0701a7eb8371293f", x"0cf23a963c42561e", x"01e2dabb7a10320c", x"0722374dbdd7ad2e", x"063e7f71776fb439", x"028d223bab9c93b2", x"089a8955f5831d85", x"08284a002156adf8", x"054cb45e4880ce71", x"0d67a4ec92d463c1", x"010dcc9ea3290839", x"06ec6dffb69daeb9", x"09b25e9cb5de5fb3", x"0d90b46b93127c7d", x"065e811bef883fc1", x"0d7ecd06a96cc620", x"0aad7952a35aba83", x"0bde9605ade65c65", x"06130eb9694f0a69", x"0ff18c6d976d5eff", x"08231f63fbe22ab5", x"0452fd3e6dc2c74e", x"0a6be056424a90b7", x"0bc28f24a62e0224", x"0736949544925a48", x"0779cb79ad4c6f36", x"0bbef1ad9d943f55", x"08fd4fb174b9de97", x"08395b9372f93316", x"072a73e08e217b03", x"019cbabec756c996", x"0b3173c516c258ae", x"024c4453bc2e260c", x"0ac44c73a8159ad6", x"0899485df055f4fc", x"04f4ba2842d1cfae", x"0f094efc55ea27ba", x"004e2e10365ae8c8", x"085478c186d104c5", x"08a0b21fe664466d", x"0a901924ea8d2f0a");
    
    constant W: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"072283f8f018f3a7");
    constant PRIME: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"1000000000000d41");
    constant PRIME_RED: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"0ffffffffffff2bf");
    constant PRIME_I: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"0eb3e56f9f718027");
    constant PRIME_LEN : integer := 61; 
            
    alias param_addr_top : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is fft_param_addr(C_PARAM_ADDR_WIDTH-1 downto C_PARAM_ADDR_WIDTH/2);
    alias param_addr_bottom : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is fft_param_addr((C_PARAM_ADDR_WIDTH/2)-1 downto 0);
        
begin

    fft_inst : entity work.fft
        generic map (
            C_PARAM_WIDTH          => C_PARAM_WIDTH,
            C_PARAM_ADDR_WIDTH     => C_PARAM_ADDR_WIDTH,
            C_PARAM_ADDR_FFT_TABLE => C_PARAM_ADDR_FFT_TABLE,
            C_LENGTH_WIDTH         => C_LENGTH_WIDTH,
            C_MAX_FFT_PRIME_WIDTH  => C_MAX_FFT_PRIME_WIDTH,
            C_MAX_FFT_LENGTH       => C_FFT_LENGTH
        )
        port map (
            clk => clk,
                    
            -- Ports of fft
            param          => fft_param,
            param_addr     => fft_param_addr,
            param_valid    => fft_param_valid,
            prime          => fft_prime,
            prime_r        => fft_prime_r,
            prime_i        => fft_prime_i,
            prime_s        => fft_prime_s,
            length         => fft_length,
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
    
        variable tmp: unsigned(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := to_unsigned(1, C_MAX_FFT_PRIME_WIDTH);
        
    begin
        wait until rising_edge(clk);
        
        fft_prime   <= PRIME;
        fft_prime_r <= PRIME_RED;
        fft_prime_i <= PRIME_I;
        fft_prime_s <= std_logic_vector(to_unsigned(PRIME_LEN, C_LENGTH_WIDTH));
        fft_length  <= std_logic_vector(to_unsigned(C_FFT_LENGTH, C_LENGTH_WIDTH));
        
        param_addr_top <= std_logic_vector(to_unsigned(C_PARAM_ADDR_FFT_TABLE, (C_PARAM_ADDR_WIDTH/2)));
        param_addr_bottom <= x"0000";
        
               
        for i in 0 to FFT_TABLE_LENGTH - 1 loop   
            fft_param_valid <= '1';
            fft_param <= std_logic_vector(tmp);
            wait until rising_edge(clk);
            param_addr_bottom <= std_logic_vector(unsigned(param_addr_bottom) + 1);
            tmp := (tmp * unsigned(W)) mod unsigned(PRIME);
        end loop;
        
        fft_param_valid <= '0';
        wait until rising_edge(clk);
        
        for i in 0 to C_FFT_LENGTH - 1 loop
            fft_value_valid <= '1';
        	fft_value <= INPUT(i);
        	wait until rising_edge(clk);
        end loop;
        
        fft_value_valid <= '0';
                
        -- fill pipeline with extra data
        for i in 0 to C_FFT_LENGTH - 1 loop
            fft_value_valid <= '1';
            fft_value <= OUTPUT(i);
        	wait until rising_edge(clk);
        end loop;
        
        fft_value_valid <= '0';
                
        wait until fft_output_valid = '1' and rising_edge(clk);
        
		for i in 0 to C_FFT_LENGTH - 1 loop
			assert fft_output = OUTPUT(i);
            wait until rising_edge(clk);
		end loop;

        wait until fft_output_valid = '0';
        
        stop <= '1';
        
        wait;
    end process;

end;