----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/11/2017 08:15:57 PM
-- Design Name: 
-- Module Name: he_processor - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity he_processor is
	generic (
        C_MAX_PROG_LENGTH    : integer   := 5;
        C_MAX_DATA_WIDTH     : integer   := 32;
        C_REGISTER_WIDTH     : integer   := 32;
	    C_PARAM_WIDTH        : integer   := 64;
        C_PARAM_ADDR_WIDTH   : integer   := 32;
        ---
        C_LENGTH_WIDTH         : integer   := 16;    
        C_MAX_FFT_PRIME_WIDTH  : integer   := 64;
        C_MAX_FFT_LENGTH       : integer   := 64; 
        C_MAX_POLY_LENGTH      : integer   := 18; 
        C_MAX_CRT_PRIME_WIDTH  : integer   := 256; 
        C_MAX_FFT_PRIMES       : integer   := 3;
        C_MAX_FFT_PRIMES_FOLDS : integer   := 2;--(256/64)-2;--C_MAX_CRT_PRIME_WIDTH / C_MAX_FFT_PRIME_WIDTH - 2
        ---
	);
    Port ( clk : in std_logic;
           reset : in std_logic;
           start : in std_logic;
           mode : in std_logic_vector(C_REGISTER_WIDTH-1 downto 0);
           valid_a : in std_logic;
           ready_a : out std_logic;
           data_a : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
           valid_b : in std_logic;
           ready_b : out std_logic;
           data_b : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
           valid : out std_logic;
           data_out : out std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0));
end he_processor;

architecture Behavioral of he_processor is
    type FFT_DATA_TYPE is array(natural range <>) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    
    subtype CONTROL_TYPE is std_logic_vector(C_REGISTER_WIDTH-1 downto 0);
    subtype OPCODE_TYPE is std_logic_vector(3 downto 0);
    subtype REGISTER_INDEX_TYPE is std_logic_vector(3 downto 0);
    subtype INSTRUCTION_TYPE is std_logic_vector(C_REGISTER_WIDTH-1 downto 0);
    type RAM_TYPE is array(C_MAX_PROG_LENGTH-1 downto 0) of INSTRUCTION_TYPE;
    
    type STATE_TYPE is (IDLE, LOAD_CODE, LOAD_MOD_CHAIN, LOAD_PUB_KEY, LOAD_SEC_KEY, LOAD_EV_KEY, LOAD_FFT_TABLE, RUN, EXEC);

    -- Program integer registers (not for HE)
    constant REG_0              : REGISTER_INDEX_TYPE := b"0000";
    constant REG_1              : REGISTER_INDEX_TYPE := b"0001";
    constant REG_2              : REGISTER_INDEX_TYPE := b"0010";   
    -- Encrypted buffers (for HE)
    ----
        
    constant MODE_LOAD_CODE : CONTROL_TYPE := x"00000000";
    constant MODE_RUN       : CONTROL_TYPE := x"00000001";
    constant MODE_TERM      : CONTROL_TYPE := x"00000002";
    
    constant OP_SUB   : OPCODE_TYPE := "0000";
    constant OP_ADD   : OPCODE_TYPE := "0001";
    constant OP_MUL   : OPCODE_TYPE := "0010";
    constant OP_B     : OPCODE_TYPE := "0011";
    constant OP_CRT   : OPCODE_TYPE := "0100";
    constant OP_ICRT  : OPCODE_TYPE := "0101";
    constant OP_FFT   : OPCODE_TYPE := "0110";
    constant OP_IFFT  : OPCODE_TYPE := "0111";
    constant OP_LOAD  : OPCODE_TYPE := "1000";
    constant OP_STORE : OPCODE_TYPE := "1001";
    constant OP_BNE   : OPCODE_TYPE := "1010"; -- Loop for program integer registers only
    
    constant MUX_IN_VALID_TO_ADD  : integer := 0;
    constant MUX_IN_VALID_TO_SUB  : integer := 1;
    constant MUX_IN_VALID_TO_MUL  : integer := 2;
    constant MUX_IN_VALID_TO_FFT  : integer := 3;
    constant MUX_IN_VALID_TO_IFFT : integer := 4;
    constant MUX_IN_VALID_TO_CRT  : integer := 5;
    constant MUX_IN_VALID_TO_ICRT : integer := 6;
    
    signal state                : STATE_TYPE;
        
    signal program_length       : integer := 0;
    signal program_counter      : integer := 0;
    signal instruction          : INSTRUCTION_TYPE := (others => '0');
        alias opcode : OPCODE_TYPE is instruction(31 downto 28); -- unhard code these values 'left/'range etc.
        alias reg : REGISTER_INDEX_TYPE is instruction(27 downto 24); -- unhard code these values
    
    constant add_enabled  : std_logic_vector(4-1 downto 0) := "0000";
    constant sub_enabled  : std_logic_vector(4-1 downto 0) := "0001";
    constant mul_enabled  : std_logic_vector(4-1 downto 0) := "0010";
    constant fft_enabled  : std_logic_vector(4-1 downto 0) := "0011";
    constant ifft_enabled : std_logic_vector(4-1 downto 0) := "0100";
    constant crt_enabled  : std_logic_vector(4-1 downto 0) := "0101";
    constant icrt_enabled : std_logic_vector(4-1 downto 0) := "0110";
    
    signal mux_mode : std_logic_vector(4-1 downto 0);
    signal modulus : std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0) := (others => '0');
    
    shared variable program : RAM_TYPE;
    
    -- FFT       
    signal poly_length : std_logic_vector(C_LENGTH_WIDTH-1 downto 0)   := (others => '0');
    signal fft_length  : std_logic_vector(C_LENGTH_WIDTH-1 downto 0)   := (others => '0');

    signal mul_table   : FFT_DATA_TYPE(0 to (C_MAX_POLY_LENGTH*C_MAX_FFT_PRIMES)-1)  := (others => (others => '0'));

    signal primes      : FFT_DATA_TYPE(0 to C_MAX_FFT_PRIMES-1)  := (others => (others => '0'));
    signal primes_r    : FFT_DATA_TYPE(0 to C_MAX_FFT_PRIMES-1)  := (others => (others => '0'));
    signal primes_i    : FFT_DATA_TYPE(0 to C_MAX_FFT_PRIMES-1)  := (others => (others => '0'));
    signal prime_s     : std_logic_vector(C_LENGTH_WIDTH-1 downto 0)   := (others => '0');
   
    signal prime : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
    signal prime_r : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
    signal prime_i : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
        
    signal prime_idx : integer := 0;
    
begin

    prime <= primes(prime_idx);
    prime_r <= primes_r(prime_idx);
    prime_i <= primes_i(prime_idx);

    --core_mux_inst : entity work.core_mux
    --    generic map (
    --       C_MAX_DATA_WIDTH => C_MAX_DATA_WIDTH
    --    )
    --    port map (
    --        clk => clk,
    --        a => data_a,
    --        b => data_b,
    --        q => modulus,
    --        c => data_out,
    --        mode => mux_mode
    --    );  
    
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
            prime          => prime,
            prime_r        => prime_r,
            prime_i        => prime_i,
            prime_s        => prime_s,
            length         => fft_length,
            value          => data_a,
            value_valid    => valid_a,
            output         => data_out,
            output_valid   => valid_out
        );  
     
    state_proc : process (clk) is
    begin	
        if rising_edge(clk) then
            case state is
                when IDLE =>
                    if (start = '1') then
                        case mode is
                            when MODE_LOAD_CODE =>
                                state <= LOAD_CODE;
                                ready_a <= '1';
                                program_length <= 0;
                            when MODE_RUN =>
                                if (program_length > 0) then
                                    state <= RUN;
                                    program_counter <= 0;
                                    instruction <= program(program_counter);
                                else
                                    --- Set error register
                                end if;
                            when others =>
                                --- Set error register
                        end case;
                    end if;
                   
                when LOAD_CODE =>
                    if (valid_a = '1') then
                        program(program_length) := data_a;
                        if (program_length = C_MAX_PROG_LENGTH - 1) then
                            state <= IDLE;
                            ready_a <= '0';
                        end if;
                        program_length <= program_length + 1;
                    end if;
                                                               
                when LOAD_FFT_TABLE =>
                    if (valid_a = '1') then
                        program(program_length) := data_a;
                        if (program_length = C_MAX_PROG_LENGTH - 1) then
                            state <= IDLE;
                            ready_a <= '0';
                        end if;
                        program_length <= program_length + 1;
                    end if;
                                                                                
                when RUN =>
                    if (program_counter = program_length - 1) then
                        state <= IDLE;
                    end if;
                    program_counter <= program_counter + 1;
                    instruction <= program(program_counter + 1);
                    state <= EXEC;
                    case opcode is
                        when OP_SUB =>
                            mux_mode <= sub_enabled;
                        when OP_ADD =>
                            mux_mode <= add_enabled;
                        when OP_MUL => -- For now always relin
                            mux_mode <= mul_enabled;
                        when OP_B =>
                        --when OP_CRT =>
                        --    mux_mode <= crt_enabled;
                        --when OP_ICRT =>
                        --    mux_mode <= icrt_enabled;
                        when OP_FFT =>
                            mux_mode <= fft_enabled;
                        when OP_IFFT =>
                            mux_mode <= ifft_enabled;
                        when OP_LOAD => -- Load "regiser"
                            --case reg is
                            --    when REG_A =>
                            --    when REG_B =>
                            --    when REG_C =>
                            --    state <= IDLE;
                            --end case;
                        when others =>
                            --- Set error register
                    end case;
                
                when EXEC => --- Execute current instruction
                    ready_a <= '1';
                    ready_b <= '1';
                    if (valid_a = '1') then
                        --
                        --mux_valid_a <=
                        ready_a <= '0';
                    end if;                    
                    if (valid_b = '1') then
                            --
                    end if;
                
            end case;
        end if;
    end process state_proc;
end Behavioral;
