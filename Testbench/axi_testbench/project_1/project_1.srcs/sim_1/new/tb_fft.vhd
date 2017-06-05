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
        C_FFT_LENGTH             : integer   := 16	
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

    constant INPUT: fft_array :=  (x"0fd868c34e228cb8", x"08446ea1bafa97ea", x"0277227c62203448", x"0d88dd839ddfd359", x"07bb915e45056fb7", x"0027973cb1dd7ae9", x"0000000000000001", x"0027973cb1dd7ae9", x"07bb915e45056fb7", x"0d88dd839ddfd359", x"0277227c62203448", x"08446ea1bafa97ea", x"0fd868c34e228cb8", x"0000000000000000", x"0000000000000000", x"0000000000000000");
    constant OUTPUT: fft_array := (x"0000000000000001", x"082c7277d5209517", x"0a39af4a620f810b", x"0a39af4a620f810b", x"0f8ff74817c53dce", x"0c59a0eddd9d8881", x"03a65f1222627f20", x"007008b7e83ac9d3", x"04fc1b20c8b5ab29", x"0d03f2f2d7f24cf1", x"067cc0d5b3e3b6be", x"08a1276b944bfa4e", x"06ff53e8f49c3fe3", x"00108288607f0462", x"024ac820d2f7b12b", x"066e264137fe41d1");   
    
    constant W_TABLE: fft_table_array := (x"0000000000000001", x"02988d35c17ccc9f", x"0b95ba03d2895a0b", x"008ce9213c497ee6", x"081a85435318023a", x"04d42929728e6e1c", x"08b88974961e1594", x"047928ca80c01ac0", x"10000000000007a0", x"0d6772ca3e833b02");
    constant PRIME: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"10000000000007a1");
    constant PRIME_RED: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"0FFFFFFFFFFFF85f");
    constant PRIME_I: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"081a85435318023a");
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
            fft_param <= W_TABLE(i);
            wait until rising_edge(clk);
            param_addr_bottom <= std_logic_vector(unsigned(param_addr_bottom) + 1);
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