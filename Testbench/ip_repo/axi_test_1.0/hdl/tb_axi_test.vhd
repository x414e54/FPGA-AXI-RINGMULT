library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_test_tb is
    generic (		
        C_MAX_DATA_WIDTH        : integer   := 32;
        
		-- Parameters of Axi Master Bus Interface M00_AXIS
        C_M00_AXIS_TDATA_WIDTH  : integer   := 32;
        C_M00_AXIS_START_COUNT  : integer   := 32;

        -- Parameters of Axi Slave Bus Interface S00_AXIS
        C_S00_AXIS_TDATA_WIDTH  : integer   := 32;

        -- Parameters of Axi Slave Bus Interface S00_AXI
        C_S00_AXI_DATA_WIDTH    : integer   := 32;
        C_S00_AXI_ADDR_WIDTH    : integer   := 4
    );
    --port ();
end axi_test_tb;

architecture behavior of axi_test_tb is
        subtype addr_type is std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
        subtype data_type is std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        
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
begin

    axi_test_v1_0_inst : entity work.axi_test_v1_0
            generic map (
            C_MAX_DATA_WIDTH => C_MAX_DATA_WIDTH,
            
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
    send : process
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
    end process send;
   
     -- Initiate process which simulates a master wanting to read.
     -- This process is blocked on a "Read Flag" (readIt).
     -- When the flag goes to 1, the process exits the wait state and
     -- execute a read transaction.
    read : PROCESS
    BEGIN
        s00_axi_arvalid <= '0';
        s00_axi_rready <= '0';
        loop
            wait until reading = '1';
            wait until clk = '0';
                s00_axi_arvalid <= '1';
                s00_axi_rready <= '1';
            wait until (s00_axi_rvalid and s00_axi_arready) = '1';  --Client provided data
                assert s00_axi_rresp = "00" report "AXI data not written" severity failure;
                s00_axi_arvalid <= '0';
                s00_axi_rready <= '0';
        end loop;
    end process read;
--- END --- https://github.com/frobino/axi_custom_ip_tb/blob/master/led_controller_1.0/hdl/testbench.vhd

    stimulus : process                        
        procedure begin_send(variable address: in addr_type; 
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
        end procedure begin_send;
    
        procedure begin_read(variable address: in addr_type; 
                             variable data: out data_type) is
        begin
            s00_axi_araddr <= address;
            data := s00_axi_rdata;
            reading <= '1';
            wait for 1ns;
            reading <= '0';
            wait until s00_axi_rready = '1';
            wait until s00_axi_rready = '0';
        end procedure begin_read;
        
        variable address : addr_type := x"0";
        variable data : data_type := x"DEADBEEF";
        variable rdata : data_type := x"00000000";
    begin
        reset <= '0';
        wait until falling_edge(clk);
        reset <= '1';
        wait until rising_edge(clk);
        
        begin_send(address, data);
        begin_read(address, rdata);
        assert(data = rdata);
        
        address := x"3";
        data := x"BADDCAFE";
        begin_send(address, data);
        begin_read(address, rdata);
        assert(data = rdata);
        
        stop <= '1';
        wait;
    end process;

end;