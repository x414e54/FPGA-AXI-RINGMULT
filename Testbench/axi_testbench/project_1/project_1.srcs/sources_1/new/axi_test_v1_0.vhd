library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axi_test_v1_0 is
	generic (
		-- Users to add parameters here
        C_MAX_DATA_WIDTH    : integer    := 32;
        C_MAX_PROG_LENGTH   : integer    := 5;
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Master Bus Interface M00_AXIS
		C_M00_AXIS_TDATA_WIDTH	: integer	:= 32;
		C_M00_AXIS_START_COUNT	: integer	:= 32;

		-- Parameters of Axi Slave Bus Interface S00_AXIS
		C_S00_AXIS_TDATA_WIDTH	: integer	:= 32;

		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
		-- Users to add ports here
        clk : in std_logic;
        reset : in std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Master Bus Interface M00_AXIS
		m00_axis_aclk	: in std_logic;
		m00_axis_aresetn	: in std_logic;
		m00_axis_tvalid	: out std_logic;
		m00_axis_tdata	: out std_logic_vector(C_M00_AXIS_TDATA_WIDTH-1 downto 0);
		m00_axis_tstrb	: out std_logic_vector((C_M00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		m00_axis_tlast	: out std_logic;
		m00_axis_tready	: in std_logic;

		-- Ports of Axi Slave Bus Interface S00_AXIS
		s00_axis_aclk	: in std_logic;
		s00_axis_aresetn	: in std_logic;
		s00_axis_tready	: out std_logic;
		s00_axis_tdata	: in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
		s00_axis_tstrb	: in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
		s00_axis_tlast	: in std_logic;
		s00_axis_tvalid	: in std_logic;
        
        -- Ports of Axi Slave Bus Interface S00_AXIS
        s01_axis_aclk    : in std_logic;
        s01_axis_aresetn    : in std_logic;
        s01_axis_tready    : out std_logic;
        s01_axis_tdata    : in std_logic_vector(C_S00_AXIS_TDATA_WIDTH-1 downto 0);
        s01_axis_tstrb    : in std_logic_vector((C_S00_AXIS_TDATA_WIDTH/8)-1 downto 0);
        s01_axis_tlast    : in std_logic;
        s01_axis_tvalid    : in std_logic;

		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end axi_test_v1_0;

architecture arch_imp of axi_test_v1_0 is
	signal start            : std_logic;
	signal mode	            : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    signal valid_a          : std_logic;
    signal valid_b          : std_logic;
    signal ready_a          : std_logic;
    signal ready_b          : std_logic;
    signal data_a           : std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
    signal data_b           : std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
    signal out_data         : std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
    signal out_valid        : std_logic;
	
	-- component declaration
	component axi_test_v1_0_M00_AXIS is
		generic (
        C_MAX_DATA_WIDTH    : integer    := 32;
		C_M_AXIS_TDATA_WIDTH	: integer	:= 32;
		C_M_START_COUNT	: integer	:= 32
		);
		port (
        clk             : in std_logic;
        valid           : in std_logic;
        data            : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
		M_AXIS_ACLK	    : in std_logic;
		M_AXIS_ARESETN	: in std_logic;
		M_AXIS_TVALID	: out std_logic;
		M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		M_AXIS_TLAST	: out std_logic;
		M_AXIS_TREADY	: in std_logic
		);
	end component axi_test_v1_0_M00_AXIS;

	component axi_test_v1_0_S00_AXIS is
		generic (
        C_MAX_DATA_WIDTH    : integer    := 32;
		C_S_AXIS_TDATA_WIDTH	: integer	:= 32
		);
		port (
        clk             : in std_logic;
        valid           : out std_logic;
        ready           : in std_logic;
        data            : out std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
		S_AXIS_ACLK   	: in std_logic;
		S_AXIS_ARESETN	: in std_logic;
		S_AXIS_TREADY	: out std_logic;
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		S_AXIS_TLAST	: in std_logic;
		S_AXIS_TVALID	: in std_logic
		);
	end component axi_test_v1_0_S00_AXIS;
        
    component axi_test_v1_0_S01_AXIS is
        generic (
        C_MAX_DATA_WIDTH    : integer    := 32;
        C_S_AXIS_TDATA_WIDTH    : integer    := 32
        );
        port (
        clk             : in std_logic;
        valid           : out std_logic;
        ready           : in std_logic;
        data            : out std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
        S_AXIS_ACLK     : in std_logic;
        S_AXIS_ARESETN  : in std_logic;
        S_AXIS_TREADY   : out std_logic;
        S_AXIS_TDATA    : in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
        S_AXIS_TSTRB    : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
        S_AXIS_TLAST    : in std_logic;
        S_AXIS_TVALID   : in std_logic
        );
    end component axi_test_v1_0_S01_AXIS;

	component axi_test_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (
        start           : out std_logic;
        mode            : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_ACLK	    : in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	    : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	    : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	    : out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	    : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP     : out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component axi_test_v1_0_S00_AXI;

begin

-- Instantiation of Axi Bus Interface M00_AXIS
axi_test_v1_0_M00_AXIS_inst : axi_test_v1_0_M00_AXIS
	generic map (
	    C_MAX_DATA_WIDTH => C_MAX_DATA_WIDTH,
		C_M_AXIS_TDATA_WIDTH	=> C_M00_AXIS_TDATA_WIDTH,
		C_M_START_COUNT	=> C_M00_AXIS_START_COUNT
	)
	port map (
        clk             => clk,    
        valid           => out_valid,
        data            => out_data,
		M_AXIS_ACLK	    => m00_axis_aclk,
		M_AXIS_ARESETN	=> m00_axis_aresetn,
		M_AXIS_TVALID	=> m00_axis_tvalid,
		M_AXIS_TDATA	=> m00_axis_tdata,
		M_AXIS_TSTRB	=> m00_axis_tstrb,
		M_AXIS_TLAST	=> m00_axis_tlast,
		M_AXIS_TREADY	=> m00_axis_tready
	);

-- Instantiation of Axi Bus Interface S00_AXIS
axi_test_v1_0_S00_AXIS_inst : axi_test_v1_0_S00_AXIS
	generic map (
	    C_MAX_DATA_WIDTH        => C_MAX_DATA_WIDTH,
		C_S_AXIS_TDATA_WIDTH	=> C_S00_AXIS_TDATA_WIDTH
	)
	port map (
        clk             => clk,
        valid           => valid_a,
        ready           => ready_a,
        data            => data_a,
		S_AXIS_ACLK	    => s00_axis_aclk,
		S_AXIS_ARESETN	=> s00_axis_aresetn,
		S_AXIS_TREADY	=> s00_axis_tready,
		S_AXIS_TDATA	=> s00_axis_tdata,
		S_AXIS_TSTRB	=> s00_axis_tstrb,
		S_AXIS_TLAST	=> s00_axis_tlast,
		S_AXIS_TVALID	=> s00_axis_tvalid
	);
        
-- Instantiation of Axi Bus Interface S00_AXIS
axi_test_v1_0_S01_AXIS_inst : axi_test_v1_0_S00_AXIS
    generic map (
        C_MAX_DATA_WIDTH        => C_MAX_DATA_WIDTH,
        C_S_AXIS_TDATA_WIDTH    => C_S00_AXIS_TDATA_WIDTH
    )
    port map (
        clk             => clk,
        valid           => valid_b,
        ready           => ready_b,
        data            => data_b,
        S_AXIS_ACLK     => s01_axis_aclk,
        S_AXIS_ARESETN  => s01_axis_aresetn,
        S_AXIS_TREADY   => s01_axis_tready,
        S_AXIS_TDATA    => s01_axis_tdata,
        S_AXIS_TSTRB    => s01_axis_tstrb,
        S_AXIS_TLAST    => s01_axis_tlast,
        S_AXIS_TVALID   => s01_axis_tvalid
    );

-- Instantiation of Axi Bus Interface S00_AXI
axi_test_v1_0_S00_AXI_inst : axi_test_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
        start           => start,
        mode            => mode,
		S_AXI_ACLK	    => clk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	    => s00_axi_wdata,
		S_AXI_WSTRB	    => s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	    => s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	    => s00_axi_rdata,
		S_AXI_RRESP	    => s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

	-- Add user logic here
-- Instantiation of testmult
testmult_inst : entity work.he_processor
        generic map (
            C_MAX_PROG_LENGTH => C_MAX_PROG_LENGTH,
            C_MAX_DATA_WIDTH => C_MAX_DATA_WIDTH,
            C_REGISTER_WIDTH => C_S00_AXI_DATA_WIDTH
        )
        port map (
               clk          => clk,
               reset        => reset,
               start        => start,
               mode         => mode,
               valid_a      => valid_a,
               ready_a      => ready_a,
               data_a       => data_a,
               valid_b      => valid_b,
               ready_b      => ready_b,
               data_b       => data_b,
               valid        => out_valid,
               data_out     => out_data
        );
	-- User logic ends

end arch_imp;
