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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity he_processor is
	generic (
        C_MAX_PROG_LENGTH    : integer   := 5;
        C_MAX_DATA_WIDTH     : integer   := 256;
        C_REGISTER_WIDTH     : integer   := 32;
        ---
	    C_PARAM_WIDTH        : integer   := 64;
        C_PARAM_ADDR_WIDTH   : integer   := 32;
        ---
        C_LENGTH_WIDTH         : integer   := 16;    
        C_MAX_FFT_PRIME_WIDTH  : integer   := 64;
        C_MAX_FFT_LENGTH       : integer   := 64; 
        C_MAX_POLY_LENGTH      : integer   := 18; 
        C_MAX_CRT_PRIME_WIDTH  : integer   := 256; 
        C_MAX_FFT_PRIMES       : integer   := 3;
        C_MAX_FFT_PRIMES_FOLDS : integer   := 2
        ---
	);
    port (
        clk : in std_logic;
        reset : in std_logic;
        start : in std_logic;
        mode : in std_logic_vector(C_REGISTER_WIDTH-1 downto 0);
        a_valid : in std_logic;
        a_ready : out std_logic;
        a_data : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
        b_valid : in std_logic;
        b_ready : out std_logic;
        b_data : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
        out_valid : out std_logic;
        out_data : out std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0)
    );
end he_processor;

architecture Behavioral of he_processor is

    type FFT_DATA_TYPE is array(natural range <>) of std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0);
    type DATA_TYPE is array(natural range <>) of std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
    type VALID_TYPE is array(natural range <>) of std_logic;
    
    subtype CONTROL_TYPE is std_logic_vector(C_REGISTER_WIDTH-1 downto 0);
    subtype OPCODE_TYPE is std_logic_vector(3 downto 0);
    subtype REGISTER_INDEX_TYPE is std_logic_vector(3 downto 0);
    subtype INSTRUCTION_TYPE is std_logic_vector(C_REGISTER_WIDTH-1 downto 0);
    type RAM_TYPE is array(C_MAX_PROG_LENGTH-1 downto 0) of INSTRUCTION_TYPE;
    
    type STATE_TYPE is (IDLE, LOAD_CODE, LOAD_INFO, LOAD_PRIMES_1, LOAD_PRIMES_2, LOAD_PRIMES_3, LOAD_FFT_TABLE, RUN, EXEC_FFT, EXEC_FFT_OUTPUT, EXEC_SIMD, EXEC_CRT);

    -- Program integer registers (not for HE)
    constant REG_0              : REGISTER_INDEX_TYPE := b"0000";
    constant REG_1              : REGISTER_INDEX_TYPE := b"0001";
    constant REG_2              : REGISTER_INDEX_TYPE := b"0010";   
    -- Encrypted buffers (for HE)
    ----
        
    constant MODE_LOAD_CODE   : CONTROL_TYPE := x"00000000";
    constant MODE_RUN         : CONTROL_TYPE := x"00000001";
    constant MODE_TERM        : CONTROL_TYPE := x"00000002";
    constant MODE_LOAD_PARAMS : CONTROL_TYPE := x"00000003";
    
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
        
    constant NUM_MUX     : integer := 4;
    constant MUX_TO_SIMD : integer := 0;
    constant MUX_TO_FFT  : integer := 1;
    constant MUX_TO_CRT  : integer := 2;
    constant MUX_TO_ICRT : integer := 3;
    
    signal state                : STATE_TYPE;
        
    signal program_length       : integer := 0;
    signal program_counter      : integer := 0;
    signal instruction          : INSTRUCTION_TYPE := (others => '0');
        alias opcode : OPCODE_TYPE is instruction(31 downto 28); -- unhard code these values 'left/'range etc.
        alias reg : REGISTER_INDEX_TYPE is instruction(27 downto 24); -- unhard code these values
    
    constant simd_add_enabled  : std_logic_vector(4-1 downto 0) := "0000";
    constant simd_sub_enabled  : std_logic_vector(4-1 downto 0) := "0001";
    constant simd_mul_enabled  : std_logic_vector(4-1 downto 0) := "0010";
        
    signal mux_mode : integer := 0;
    signal simd_mode : std_logic_vector(4-1 downto 0);
        
    signal mux_out   : DATA_TYPE(NUM_MUX downto 0) := (others => (others => '0'));
    signal mux_valid : VALID_TYPE(NUM_MUX downto 0) := (others => '0');   
    
    signal program : RAM_TYPE;
    
    -- FFT       
    signal num_primes       : unsigned(C_LENGTH_WIDTH-1 downto 0)   := (others => '0');
    signal poly_length      : unsigned(C_LENGTH_WIDTH-1 downto 0)   := (others => '0');
    signal fft_length       : unsigned(C_LENGTH_WIDTH-1 downto 0)   := (others => '0');
    signal fft_table_length : unsigned(C_LENGTH_WIDTH-1 downto 0)   := (others => '0');

    signal primes      : FFT_DATA_TYPE(0 to C_MAX_FFT_PRIMES-1)  := (others => (others => '0'));
    signal primes_r    : FFT_DATA_TYPE(0 to C_MAX_FFT_PRIMES-1)  := (others => (others => '0'));
    signal primes_i    : FFT_DATA_TYPE(0 to C_MAX_FFT_PRIMES-1)  := (others => (others => '0'));
    signal prime_s     : std_logic_vector(C_LENGTH_WIDTH-1 downto 0)   := (others => '0');
   
    signal prime : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
    signal prime_r : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
    signal prime_i : std_logic_vector(C_MAX_FFT_PRIME_WIDTH-1 downto 0)   := (others => '0');
    
    signal fft_param       : std_logic_vector(C_PARAM_WIDTH-1 downto 0)   := (others => '0');
    signal fft_param_addr  : std_logic_vector(C_PARAM_ADDR_WIDTH-1 downto 0)   := (others => '0');
    signal fft_param_valid : std_logic := '0';
    
    signal simd_valid_enabled : std_logic := '0';
    signal fft_valid_enabled : std_logic := '0';
    signal crt_valid_enabled : std_logic := '0';
    signal icrt_valid_enabled : std_logic := '0';
        
    signal prime_idx : integer := 0;
    signal fft_table_idx : integer := 0;
                
begin

    prime <= primes(prime_idx);
    prime_r <= primes_r(prime_idx);
    prime_i <= primes_i(prime_idx);
    
    fft_valid_enabled <= '1' when (mux_mode = MUX_TO_FFT) and (a_valid = '1') else '0';
    crt_valid_enabled <= '1' when (mux_mode = MUX_TO_CRT) and (a_valid = '1') else '0';
    icrt_valid_enabled <= '1' when (mux_mode = MUX_TO_ICRT) and (a_valid = '1') else '0';
    
    out_data <= mux_out(mux_mode);
    out_valid <= mux_valid(mux_mode);
    
    red_simd_core_mux_inst : entity work.red_simd_core_mux
        generic map (
            C_MAX_SIMD_NUM   => C_MAX_DATA_WIDTH/C_MAX_FFT_PRIME_WIDTH,
            C_MAX_DATA_WIDTH => C_MAX_FFT_PRIME_WIDTH,
            C_LENGTH_WIDTH  => C_LENGTH_WIDTH
        )
        port map (
            clk     => clk,
            prime   => prime,
            prime_r => prime_r,
            prime_s => prime_s, 
            mode    => simd_mode,
            a       => a_data,
            a_valid => a_valid,
            b       => b_data,
            b_valid => b_valid,
            c       => mux_out(MUX_TO_SIMD),
            c_valid => mux_valid(MUX_TO_SIMD)
        );  
    
    fft_inst : entity work.fft
        generic map (
            C_PARAM_WIDTH          => C_PARAM_WIDTH,
            C_PARAM_ADDR_WIDTH     => C_PARAM_ADDR_WIDTH,
            C_PARAM_ADDR_FFT_TABLE => 0,
            C_LENGTH_WIDTH         => C_LENGTH_WIDTH,
            C_MAX_FFT_PRIME_WIDTH  => C_MAX_FFT_PRIME_WIDTH,
            C_MAX_FFT_LENGTH       => C_MAX_FFT_LENGTH
        )
        port map (
            clk            => clk,
            param          => fft_param,
            param_addr     => fft_param_addr,
            param_valid    => fft_param_valid,
            prime          => prime,
            prime_r        => prime_r,
            prime_i        => prime_i,
            prime_s        => prime_s,
            length         => std_logic_vector(fft_length),
            value          => a_data(C_MAX_DATA_WIDTH-1 downto C_MAX_DATA_WIDTH-C_MAX_FFT_PRIME_WIDTH),
            value_valid    => fft_valid_enabled,
            output         => mux_out(MUX_TO_FFT)(C_MAX_DATA_WIDTH-1 downto C_MAX_DATA_WIDTH-C_MAX_FFT_PRIME_WIDTH),
            output_valid   => mux_valid(MUX_TO_FFT)
        );
     
    state_proc : process (clk) is
    begin	
        if rising_edge(clk) then
            case state is
                when IDLE =>
                    fft_param_valid <= '0';
                    if (start = '1') then
                        case mode is
                            when MODE_LOAD_CODE =>
                                state <= LOAD_CODE;
                                a_ready <= '1';
                                program_length <= 0;
                            when MODE_LOAD_PARAMS =>
                                state <= LOAD_INFO;
                                a_ready <= '1';
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
                    if (a_valid = '1') then
                        program(program_length) <= a_data(C_MAX_DATA_WIDTH-1 downto C_MAX_DATA_WIDTH-C_REGISTER_WIDTH);
                        if (program_length = C_MAX_PROG_LENGTH - 1) then
                            state <= IDLE;
                            a_ready <= '0';
                        end if;
                        program_length <= program_length + 1;
                    end if;
                                            
                when LOAD_INFO =>
                    if (a_valid = '1') then
                        num_primes <= unsigned(a_data(C_MAX_DATA_WIDTH-1 downto C_MAX_DATA_WIDTH-C_LENGTH_WIDTH));
                        poly_length <= unsigned(a_data(C_MAX_DATA_WIDTH-C_LENGTH_WIDTH-1 downto C_MAX_DATA_WIDTH-2*C_LENGTH_WIDTH));
                        fft_length <= unsigned(a_data(C_MAX_DATA_WIDTH-2*C_LENGTH_WIDTH-1 downto C_MAX_DATA_WIDTH-3*C_LENGTH_WIDTH));
                        fft_table_length <= unsigned(a_data(C_MAX_DATA_WIDTH-3*C_LENGTH_WIDTH-1 downto C_MAX_DATA_WIDTH-4*C_LENGTH_WIDTH));
                        state <= LOAD_PRIMES_1;
                    end if;
                    
                when LOAD_PRIMES_1 =>
                    if (a_valid = '1') then
                        primes(prime_idx) <= a_data(C_MAX_DATA_WIDTH-1 downto C_MAX_DATA_WIDTH-C_MAX_FFT_PRIME_WIDTH);
                        prime_idx <= prime_idx + 1;
                        if (prime_idx = num_primes - 1) then
                            state <= LOAD_PRIMES_2;
                            prime_idx <= 0;
                        end if;
                    end if;
                    
                when LOAD_PRIMES_2 =>
                    if (a_valid = '1') then
                        primes_r(prime_idx) <= a_data(C_MAX_DATA_WIDTH-1 downto C_MAX_DATA_WIDTH-C_MAX_FFT_PRIME_WIDTH);
                        prime_idx <= prime_idx + 1;
                        if (prime_idx = num_primes - 1) then
                            state <= LOAD_PRIMES_3;
                            prime_idx <= 0;
                        end if;
                    end if;
                    
                when LOAD_PRIMES_3 =>
                    if (a_valid = '1') then
                        primes_i(prime_idx) <= a_data(C_MAX_DATA_WIDTH-1 downto C_MAX_DATA_WIDTH-C_MAX_FFT_PRIME_WIDTH);
                        prime_idx <= prime_idx + 1;
                        if (prime_idx = num_primes - 1) then
                            state <= LOAD_FFT_TABLE;
                            prime_idx <= 0;
                        end if;
                    end if;
                                                               
                when LOAD_FFT_TABLE =>
                    if (a_valid = '1') then
                        fft_param <= a_data(C_MAX_DATA_WIDTH-1 downto C_MAX_DATA_WIDTH-C_PARAM_WIDTH);
                        fft_param_addr <= std_logic_vector(to_unsigned(fft_table_idx, C_PARAM_ADDR_WIDTH));
                        fft_param_valid <= '1';
                        fft_table_idx <= fft_table_idx + 1;
                        if (fft_table_idx = fft_table_length - 1) then
                            state <= IDLE;
                            a_ready <= '0';
                            fft_table_idx <= 0;
                        end if;
                    end if;
                                                                                
                when RUN =>
                    if (program_counter = program_length - 1) then
                        state <= IDLE;
                    end if;
                    program_counter <= program_counter + 1;
                    instruction <= program(program_counter);
                    case opcode is
                        when OP_SUB =>
                            mux_mode <= MUX_TO_SIMD;
                            simd_mode <= simd_sub_enabled;
                        when OP_ADD =>
                            mux_mode <= MUX_TO_SIMD;
                            simd_mode <= simd_add_enabled;
                        when OP_MUL => 
                            mux_mode <= MUX_TO_SIMD;
                            simd_mode <= simd_mul_enabled;
                        when OP_B =>
                        when OP_BNE => 
                        when OP_CRT =>
                            mux_mode <= MUX_TO_CRT;
                        when OP_ICRT =>
                            mux_mode <= MUX_TO_ICRT;
                        when OP_FFT =>
                            mux_mode <= MUX_TO_FFT;
                            state <= EXEC_FFT;
                            a_ready <= '1';
                        when OP_IFFT =>
                            mux_mode <= MUX_TO_FFT;
                            state <= EXEC_FFT;
                        when OP_LOAD => -- Load "register"
                            --case reg is
                            --    when REG_A =>
                            --    when REG_B =>
                            --    when REG_C =>
                            --    state <= IDLE;
                            --end case;
                        when others =>
                            state <= IDLE;
                            --- Set error register
                    end case;
                
                when EXEC_FFT => --- Execute current instruction
                    if (mux_valid(MUX_TO_FFT) = '1') then
                        a_ready <= '0';
                        state <= EXEC_FFT_OUTPUT;
                    end if;
                    
                when EXEC_FFT_OUTPUT => --- Execute current instruction
                    if (mux_valid(MUX_TO_FFT) = '0') then
                        state <= RUN;
                    end if;
                    
                when EXEC_SIMD => --- Execute current instruction
                    state <= RUN;
                    
                when EXEC_CRT => --- Execute current instruction
                    state <= RUN;
                    
            end case;
        end if;
    end process state_proc;
end Behavioral;
