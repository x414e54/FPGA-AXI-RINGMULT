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
        signal crt_rem        :  std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (others => '0');
        signal crt_enabled    :  std_logic := '0';

        signal stop_simulation: boolean;

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
        
        --Test AXI Lite
        send(address, data);
        read(address, rdata);
        assert(data = rdata);
        
        address := b"1100";
        data := x"BADDCAFE";
        send(address, data);
        read(address, rdata);
        assert(data = rdata);
        
        --Test Loading Program
        address := b"0000";
        data := x"00000000";
        send(address, data);
        address := b"0100";
        data := x"00000001";
        send(address, data);
        
        test_data(0) := x"06000000";
        test_data(1) := x"00000000";
        test_data(2) := x"00000000";
        length := C_MAX_PROG_LENGTH;
        send_stream(test_data, length);
        
        address := b"0000";
        data := x"00000001";
        send(address, data);
        address := b"0100";
        data := x"00000000";
        send(address, data);
        wait until rising_edge(clk);
        address := b"0100";
        data := x"00000001";
        send(address, data);
        
        wait until rising_edge(clk);
        test_data(0) := x"00000001";
        test_data(1) := x"00000002";
        test_data(2) := x"00000003";
        test_rdata(0) := x"00000000";
        test_rdata(1) := x"00000000";
        test_rdata(2) := x"00000000";
        read_stream;
        length := 3;
        send_stream(test_data, length);
        --stop <= '1';
        
        wait;
    end process;

end;