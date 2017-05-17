library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fft is
    generic (	
        C_PARAM_WIDTH            : integer   := 64;
        C_PARAM_ADDR_WIDTH       : integer   := 32;
        C_LENGTH_WIDTH           : integer   := 16;		
        C_MAX_FFT_LENGTH         : integer   := 16;	
        C_MAX_FFT_PRIME_WIDTH    : integer   := 64
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
    signal fft_prime_s         :  std_logic_vector(C_LENGTH_WIDTH-1 downto 0) := (others => '0');
    signal fft_length          :  std_logic_vector(C_LENGTH_WIDTH-1 downto 0) := (others => '0');
    signal fft_value           :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal fft_value_valid     :  std_logic := '0';
    signal fft_output          :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
    signal fft_output_valid    :  std_logic := '0';
                    
    type fft_array is array(0 to C_MAX_FFT_LENGTH - 1) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    type fft_table_array is array(0 to C_MAX_FFT_LENGTH - 1) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);

    constant INPUT: fft_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant OUTPUT: fft_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant W_TABLE: fft_table_array := (x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant PRIME: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"1000000000000D41");
    constant PRIME_RED: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"0FFFFFFFFFFFF2BF");
    constant PRIME_LEN : integer := 61; 
        
begin

    fft_inst : entity work.fft
        generic map (
            C_MAX_FFT_LENGTH       => C_MAX_FFT_LENGTH,
            C_MAX_FFT_PRIME_WIDTH  => C_MAX_FFT_PRIME_WIDTH,
            C_PARAM_ADDR_TOP       => x"0000"
        )
        port map (
            clk => clk,
                    
            -- Ports of fft
            param          => fft_param,
            param_addr     => fft_param,
            param_valid    => fft_param_valid,
            prime          => fft_prime,
            prime_r        => fft_prime_r,
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