library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_test_tb is
    generic (		
        C_MAX_DATA_WIDTH        : integer   := 64;		
        C_MAX_DATA_LENGTH       : integer   := 771;
        C_MAX_PROG_LENGTH       : integer   := 3;       
        ---
        C_PARAM_WIDTH        : integer   := 64;
        C_PARAM_ADDR_WIDTH   : integer   := 32;
        ---
        C_LENGTH_WIDTH         : integer   := 16;    
        C_MAX_FFT_PRIME_WIDTH  : integer   := 64;
        C_MAX_FFT_LENGTH       : integer   := 64; 
        C_MAX_POLY_LENGTH      : integer   := 16; 
        C_MAX_CRT_PRIME_WIDTH  : integer   := 256; 
        C_MAX_FFT_PRIMES       : integer   := 3;
        C_MAX_FFT_PRIMES_FOLDS : integer   := 2;
        ---
        
		-- Parameters of Axi Master Bus Interface M00_AXIS
        C_M00_AXIS_TDATA_WIDTH  : integer   := 64;
        C_M00_AXIS_START_COUNT  : integer   := 32;

        -- Parameters of Axi Slave Bus Interface S00_AXIS
        C_S00_AXIS_TDATA_WIDTH  : integer   := 64;

        -- Parameters of Axi Slave Bus Interface S00_AXI
        C_S00_AXI_DATA_WIDTH    : integer   := 32;
        C_S00_AXI_ADDR_WIDTH    : integer   := 4
    );
    --port ();
end axi_test_tb;

architecture behavior of axi_test_tb is
        subtype addr_type is std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        subtype data_type is std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        subtype INSTRUCTION_TYPE is std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
        type STREAM_TYPE is array(C_MAX_DATA_LENGTH-1 downto 0) of INSTRUCTION_TYPE;
                        
        signal   stop               : std_logic := '0';
        constant clk_period         : time := 10ns;

        signal clk                  : std_logic := '0';
        signal reset                : std_logic := '1';

        -- Signals of Axi Master Bus Interface M00_AXIS
        signal m00_axis_tvalid      :  std_logic := '0';
        signal m00_axis_tdata       :  std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0) := (others => '0');
        signal m00_axis_tstrb       :  std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0) := (others => '0');
        signal m00_axis_tlast       :  std_logic := '0';
        signal m00_axis_tready      :  std_logic := '0';

        -- Signals of Axi Slave Bus Interface S00_AXIS
        signal s00_axis_tready      :  std_logic := '0';
        signal s00_axis_tdata       :  std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0) := (others => '0');
        signal s00_axis_tstrb       :  std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0) := (others => '0');
        signal s00_axis_tlast       :  std_logic := '0';
        signal s00_axis_tvalid      :  std_logic := '0';
        
        -- Signals of Axi Slave Bus Interface S00_AXIS
        signal s01_axis_tready      :  std_logic := '0';
        signal s01_axis_tdata       :  std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0) := (others => '0');
        signal s01_axis_tstrb       :  std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0) := (others => '0');
        signal s01_axis_tlast       :  std_logic := '0';
        signal s01_axis_tvalid      :  std_logic := '0';

        -- Signals of Axi Slave Bus Interface S00_AXI
        signal s00_axi_awaddr       :  addr_type := (others => '0');
        signal s00_axi_awprot       :  std_logic_vector(2 downto 0) := (others => '0');
        signal s00_axi_awvalid      :  std_logic := '0';
        signal s00_axi_awready      :  std_logic := '0';
        signal s00_axi_wdata        :  data_type := (others => '0');
        signal s00_axi_wstrb        :  std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0) := (others => '0');
        signal s00_axi_wvalid       :  std_logic := '0';
        signal s00_axi_wready       :  std_logic := '0';
        signal s00_axi_bresp        :  std_logic_vector(1 downto 0) := (others => '0');
        signal s00_axi_bvalid       :  std_logic := '0';
        signal s00_axi_bready       :  std_logic := '0';
        signal s00_axi_araddr       :  addr_type := (others => '0');
        signal s00_axi_arprot       :  std_logic_vector(2 downto 0) := (others => '0');
        signal s00_axi_arvalid      :  std_logic := '0';
        signal s00_axi_arready      :  std_logic := '0';
        signal s00_axi_rdata        :  data_type := (others => '0');
        signal s00_axi_rresp        :  std_logic_vector(1 downto 0) := (others => '0');
        signal s00_axi_rvalid       :  std_logic := '0';
        signal s00_axi_rready       :  std_logic := '0';
    
        signal sending              : std_logic := '0';
        signal reading              : std_logic := '0';
            
        signal sending_stream       : std_logic := '0';
        signal reading_stream       : std_logic := '0';
        
        shared variable test_rdata  : STREAM_TYPE := (others => (others => '0'));
                               
        constant FFT_TABLE_LENGTH: integer := (3*((C_MAX_FFT_LENGTH/4)-1)) + 1;
        type fft_array is array(0 to C_MAX_FFT_LENGTH - 1) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
        type fft_table_array is array(0 to FFT_TABLE_LENGTH - 1) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);

        constant INPUT: fft_array := (x"05da70c865fceff8", x"0a1996af809f5eea", x"0eb3e56f9f718027", x"0e2ebeb634481c01", x"0488b321b3b901b8", x"0000000000000001", x"059cdc15e64a1b91", x"07b7aa9a4b189f97", x"0eb3e56f9f718027", x"07b7aa9a4b189f97", x"059cdc15e64a1b91", x"0000000000000001", x"0488b321b3b901b8", x"0e2ebeb634481c01", x"0eb3e56f9f718027", x"0a1996af809f5eea", x"05da70c865fceff8", x"0000000000000001", x"05da70c865fceff8", x"0a1996af809f5eea", x"0eb3e56f9f718027", x"0e2ebeb634481c01", x"0488b321b3b901b8", x"0000000000000001", x"059cdc15e64a1b91", x"07b7aa9a4b189f97", x"0eb3e56f9f718027", x"07b7aa9a4b189f97", x"059cdc15e64a1b91", x"0000000000000001", x"0488b321b3b901b8", x"0e2ebeb634481c01", x"0eb3e56f9f718027", x"0a1996af809f5eea", x"05da70c865fceff8", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000", x"0000000000000000");
        constant OUTPUT: fft_array := (x"0837609dbca8beaa", x"0837609dbca8bea0", x"0eb3e56f9f718027", x"014c1a90608e8d1a", x"0a150adea428b242", x"0276070b0887d0ef", x"05b5d7d85a6f80e3", x"031c993208c546c5", x"072e504d3da22e8b", x"006f0447128500c4", x"0e1299a07c1a2c3a", x"0b168274ccfb1715", x"0784c05fa8fefc94", x"097c79d1afc18e62", x"084976f64cfcc19c", x"06af0a05ee847109", x"0aa7550a72633120", x"0df34b59eb84e426", x"0deec8ac512665c9", x"007e0e37dd51cf34", x"06ab4355042b5273", x"09a56c98c05d0615", x"081211d72c2cc26e", x"0701a7eb8371293f", x"0cf23a963c42561e", x"01e2dabb7a10320c", x"0722374dbdd7ad2e", x"063e7f71776fb439", x"028d223bab9c93b2", x"089a8955f5831d85", x"08284a002156adf8", x"054cb45e4880ce71", x"0d67a4ec92d463c1", x"010dcc9ea3290839", x"06ec6dffb69daeb9", x"09b25e9cb5de5fb3", x"0d90b46b93127c7d", x"065e811bef883fc1", x"0d7ecd06a96cc620", x"0aad7952a35aba83", x"0bde9605ade65c65", x"06130eb9694f0a69", x"0ff18c6d976d5eff", x"08231f63fbe22ab5", x"0452fd3e6dc2c74e", x"0a6be056424a90b7", x"0bc28f24a62e0224", x"0736949544925a48", x"0779cb79ad4c6f36", x"0bbef1ad9d943f55", x"08fd4fb174b9de97", x"08395b9372f93316", x"072a73e08e217b03", x"019cbabec756c996", x"0b3173c516c258ae", x"024c4453bc2e260c", x"0ac44c73a8159ad6", x"0899485df055f4fc", x"04f4ba2842d1cfae", x"0f094efc55ea27ba", x"004e2e10365ae8c8", x"085478c186d104c5", x"08a0b21fe664466d", x"0a901924ea8d2f0a");

        constant W: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"072283f8f018f3a7");
        constant PRIME: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"1000000000000d41");
        constant PRIME_RED: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"0ffffffffffff2bf");
        constant PRIME_I: std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := (x"0eb3e56f9f718027");

begin

    axi_test_v1_0_inst : entity work.axi_test_v1_0
            generic map (
            C_MAX_DATA_WIDTH => C_MAX_DATA_WIDTH,
            C_MAX_PROG_LENGTH => C_MAX_PROG_LENGTH,      
            ---
            C_PARAM_WIDTH => C_PARAM_WIDTH,
            C_PARAM_ADDR_WIDTH => C_PARAM_ADDR_WIDTH,
            ---
            C_LENGTH_WIDTH => C_LENGTH_WIDTH,
            C_MAX_FFT_PRIME_WIDTH => C_MAX_FFT_PRIME_WIDTH,
            C_MAX_FFT_LENGTH => C_MAX_FFT_LENGTH,
            C_MAX_POLY_LENGTH =>  C_MAX_POLY_LENGTH,
            C_MAX_CRT_PRIME_WIDTH => C_MAX_CRT_PRIME_WIDTH,
            C_MAX_FFT_PRIMES => C_MAX_FFT_PRIMES,
            C_MAX_FFT_PRIMES_FOLDS => C_MAX_FFT_PRIMES_FOLDS,
            ---
            
            -- Parameters of Axi Master Bus Interface M00_AXIS
            C_M00_AXIS_TDATA_WIDTH => C_M00_AXIS_TDATA_WIDTH,
            C_M00_AXIS_START_COUNT => C_M00_AXIS_START_COUNT,
            
            -- Parameters of Axi Slave Bus Interface S00_AXIS
            C_S00_AXIS_TDATA_WIDTH => C_S00_AXIS_TDATA_WIDTH,
            
            -- Parameters of Axi Slave Bus Interface S00_AXI
            C_S00_AXI_DATA_WIDTH => C_S00_AXI_DATA_WIDTH,
            C_S00_AXI_ADDR_WIDTH => C_S00_AXI_ADDR_WIDTH
        )
        port map (
            clk => clk,
            reset => reset,
                    
            -- Ports of Axi Master Bus Interface M00_AXIS
            m00_axis_aclk => clk,
            m00_axis_aresetn => reset,
            m00_axis_tvalid => m00_axis_tvalid,
            m00_axis_tdata => m00_axis_tdata,
            m00_axis_tstrb => m00_axis_tstrb,
            m00_axis_tlast => m00_axis_tlast,
            m00_axis_tready => m00_axis_tready,
            
            -- Ports of Axi Slave Bus Interface S00_AXIS
            s00_axis_aclk => clk,
            s00_axis_aresetn => reset,
            s00_axis_tready => s00_axis_tready,
            s00_axis_tdata => s00_axis_tdata,
            s00_axis_tstrb => s00_axis_tstrb,
            s00_axis_tlast => s00_axis_tlast,
            s00_axis_tvalid => s00_axis_tvalid,
                        
            -- Ports of Axi Slave Bus Interface S00_AXIS
            s01_axis_aclk => clk,
            s01_axis_aresetn => reset,
            s01_axis_tready => s01_axis_tready,
            s01_axis_tdata => s01_axis_tdata,
            s01_axis_tstrb => s01_axis_tstrb,
            s01_axis_tlast => s01_axis_tlast,
            s01_axis_tvalid => s01_axis_tvalid,
            
            -- Ports of Axi Slave Bus Interface S00_AXI
            s00_axi_aclk => clk,
            s00_axi_aresetn => reset,
            s00_axi_awaddr => s00_axi_awaddr,
            s00_axi_awprot => s00_axi_awprot,
            s00_axi_awvalid => s00_axi_awvalid,
            s00_axi_awready => s00_axi_awready,
            s00_axi_wdata => s00_axi_wdata,
            s00_axi_wstrb => s00_axi_wstrb,
            s00_axi_wvalid => s00_axi_wvalid,
            s00_axi_wready => s00_axi_wready,
            s00_axi_bresp => s00_axi_bresp,
            s00_axi_bvalid => s00_axi_bvalid,
            s00_axi_bready => s00_axi_bready,
            s00_axi_araddr => s00_axi_araddr,
            s00_axi_arprot => s00_axi_arprot,
            s00_axi_arvalid => s00_axi_arvalid,
            s00_axi_arready => s00_axi_arready,
            s00_axi_rdata => s00_axi_rdata,
            s00_axi_rresp => s00_axi_rresp,
            s00_axi_rvalid => s00_axi_rvalid,
            s00_axi_rready => s00_axi_rready
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
    
 -------https://github.com/frobino/axi_custom_ip_tb/blob/master/led_controller_1.0/hdl/testbench.vhd----
 -- Initiate process which simulates a master wanting to write.
    -- This process is blocked on a "Send Flag" (sendIt).
    -- When the flag goes to 1, the process exits the wait state and
    -- execute a write transaction.
    send_proc : process
    begin
        s00_axi_awvalid <= '0';
        s00_axi_wvalid <= '0';
        s00_axi_bready <= '0';
        loop
            wait until sending = '1';
            wait until clk = '0';
                s00_axi_awvalid <= '1';
                s00_axi_wvalid <= '1';
            wait until (s00_axi_awready and s00_axi_wready) = '1';  --Client ready to read address/data        
                s00_axi_bready <= '1';
            wait until s00_axi_bvalid = '1';  -- Write result valid
                assert s00_axi_bresp = "00" report "AXI data not written" severity failure;
                s00_axi_awvalid <= '0';
                s00_axi_wvalid <= '0';
                s00_axi_bready <= '1';
            wait until s00_axi_bvalid = '0';  -- All finished
                s00_axi_bready <= '0';
        end loop;
    end process send_proc;
   
     -- Initiate process which simulates a master wanting to read.
     -- This process is blocked on a "Read Flag" (readIt).
     -- When the flag goes to 1, the process exits the wait state and
     -- execute a read transaction.
    read_proc : PROCESS
    BEGIN
        s00_axi_arvalid <= '0';
        s00_axi_rready <= '0';
        loop
            wait until reading = '1';
            wait until clk = '0';
                s00_axi_arvalid <= '1';
                s00_axi_rready <= '1';
                wait until (s00_axi_arready) = '1';  
                wait until (s00_axi_rvalid) = '1';
                assert s00_axi_rresp = "00" report "AXI data not written" severity failure;
                s00_axi_arvalid <= '0';
                s00_axi_rready <= '1';
                wait until s00_axi_rvalid = '0';
                s00_axi_rready <= '0';
        end loop;
    end process read_proc;
--- END --- https://github.com/frobino/axi_custom_ip_tb/blob/master/led_controller_1.0/hdl/testbench.vhd

    read_stream : process
    begin
        loop
            wait until reading_stream = '1';
        end loop;
    end process read_stream;
    
    stimulus : process                        
        procedure send(variable address: in addr_type; 
                       variable data: in data_type) is
        begin
            s00_axi_awaddr <= address;
            s00_axi_wdata <= data;
            s00_axi_wstrb <= b"1111";
            sending <= '1';
            wait for 1ns;
            sending <= '0';
            wait until s00_axi_bready = '1';
            wait until s00_axi_bready = '0';
            s00_axi_wstrb <= b"0000";        
        end procedure send;
    
        procedure read(variable address: in addr_type; 
                       variable data: out data_type) is
        begin
            s00_axi_araddr <= address;
            reading <= '1';
            wait for 1ns;
            reading <= '0';
            wait until s00_axi_rready = '1';
            wait until s00_axi_rready = '0';
            data := s00_axi_rdata;
        end procedure read;
                           
        procedure send_stream(variable data: in STREAM_TYPE; variable length: in integer) is
        begin
            for index in 0 to length - 1 loop
                if (index = length - 1) then
                    s00_axis_tlast <= '1';
                else
                    s00_axis_tlast <= '0';
                end if;
                
                s00_axis_tdata <= data(index);
                s00_axis_tstrb <= b"11111111";
                s00_axis_tvalid <= '1';
                if (s00_axis_tready = '0') then
                    wait until s00_axis_tready = '1';
                end if;
                wait until rising_edge(clk);
                s00_axis_tvalid <= '0';
                s00_axis_tlast <= '0';
                s00_axis_tstrb <= b"00000000";
            end loop;
        end procedure send_stream;
        
        procedure read_stream is
        begin 
            reading_stream <= '1';
            wait for 1ns;
            reading_stream <= '0';
        end procedure read_stream;
        
        variable address : addr_type := x"0";
        variable data : data_type := x"DEADBEEF";
        variable rdata : data_type := x"00000000";
        variable test_data : STREAM_TYPE:= (others => (others => '0'));
        variable length : integer := 0;
        variable tmp: unsigned(C_MAX_FFT_PRIME_WIDTH-1 downto 0) := to_unsigned(1, C_MAX_FFT_PRIME_WIDTH);
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
        
        --Test fill params
        address := b"0000";
        data := x"00000003";
        send(address, data);
        test_data(0)(C_MAX_DATA_WIDTH-1 downto C_MAX_DATA_WIDTH-C_LENGTH_WIDTH) := std_logic_vector(to_unsigned(1, C_LENGTH_WIDTH));
        test_data(0)(C_MAX_DATA_WIDTH-C_LENGTH_WIDTH-1 downto C_MAX_DATA_WIDTH-2*C_LENGTH_WIDTH) := std_logic_vector(to_unsigned(C_MAX_POLY_LENGTH, C_LENGTH_WIDTH));
        test_data(0)(C_MAX_DATA_WIDTH-2*C_LENGTH_WIDTH-1 downto C_MAX_DATA_WIDTH-3*C_LENGTH_WIDTH) := std_logic_vector(to_unsigned(C_MAX_FFT_LENGTH, C_LENGTH_WIDTH));
        test_data(0)(C_MAX_DATA_WIDTH-3*C_LENGTH_WIDTH-1 downto C_MAX_DATA_WIDTH-4*C_LENGTH_WIDTH) := std_logic_vector(to_unsigned(FFT_TABLE_LENGTH, C_LENGTH_WIDTH));
        test_data(1) := PRIME;
        test_data(2) := PRIME_RED;
        test_data(3) := PRIME_I;
        for i in 0 to FFT_TABLE_LENGTH - 1 loop   
            test_data(i + 4) := std_logic_vector(tmp);
            tmp := (tmp * unsigned(W)) mod unsigned(PRIME);
        end loop;
        address := b"0100";
        data := x"00000001";
        send(address, data);
        length := FFT_TABLE_LENGTH + 4;
        send_stream(test_data, length);

        address := b"0100";
        data := x"00000000";
        send(address, data);
        wait until rising_edge(clk);
        
        --Test Loading Program
        address := b"0000";
        data := x"00000000";
        send(address, data);
        
        test_data(0) := x"0000000600000000"; -- OP_FFT 
        test_data(1) := x"0000000000000000";
        test_data(2) := x"0000000000000000";

        address := b"0100";
        data := x"00000001";
        send(address, data);
        length := C_MAX_PROG_LENGTH;
        send_stream(test_data, length);

        address := b"0100";
        data := x"00000000";
        send(address, data);
        wait until rising_edge(clk);
        
        --Test Loading data
        address := b"0000";
        data := x"00000001";
        send(address, data);
        
        for i in 0 to C_MAX_FFT_LENGTH - 1 loop
            test_data(i) := INPUT(i);
        end loop;

        address := b"0100";
        data := x"00000001";
        send(address, data);
        length := C_MAX_FFT_LENGTH;
        send_stream(test_data, length);
        
        wait;
    end process;

end;