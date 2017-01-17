----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/11/2017 08:15:57 PM
-- Design Name: 
-- Module Name: testmult - Behavioral
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

entity testmult is
	generic (
        C_MAX_PROG_LENGTH   : integer    := 5;
        C_MAX_DATA_WIDTH    : integer    := 32;
        C_REGISTER_WIDTH    : integer    := 32
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
end testmult;

architecture Behavioral of testmult is
    subtype CONTROL_TYPE is std_logic_vector(C_REGISTER_WIDTH-1 downto 0);
    subtype OPCODE_TYPE is std_logic_vector(3 downto 0);
    subtype BUFFER_INDEX_TYPE is std_logic_vector(3 downto 0);
    subtype INSTRUCTION_TYPE is std_logic_vector(C_REGISTER_WIDTH-1 downto 0);
    type RAM_TYPE is array(C_MAX_PROG_LENGTH-1 downto 0) of INSTRUCTION_TYPE;
    
    type POLY_BUFFER is record
        addr_start      : INSTRUCTION_TYPE;
        size            : INSTRUCTION_TYPE;
        stride          : INSTRUCTION_TYPE;
    end record POLY_BUFFER;  
    
    type STATE_TYPE is (IDLE, LOAD_CODE, RUN, EXEC);

    constant BUF_A              : BUFFER_INDEX_TYPE := b"0000";
    constant BUF_B              : BUFFER_INDEX_TYPE := b"0001";
    constant BUF_C              : BUFFER_INDEX_TYPE := b"0010";   
    
    constant MODE_LOAD_CODE : CONTROL_TYPE := x"00000000";
    constant MODE_RUN       : CONTROL_TYPE := x"00000001";
    constant MODE_TERM      : CONTROL_TYPE := x"00000002";
    
    constant OP_SUB : OPCODE_TYPE := "0000";
    constant OP_ADD : OPCODE_TYPE := "0001";
    constant OP_MUL : OPCODE_TYPE := "0010";
    constant OP_B   : OPCODE_TYPE := "0011";
    constant OP_CRT : OPCODE_TYPE := "0100";
    constant OP_ICRT: OPCODE_TYPE := "0101";
    constant OP_ENC : OPCODE_TYPE := "0110";
    constant OP_DEC : OPCODE_TYPE := "0111";
    constant OP_LOAD: OPCODE_TYPE := "1000";
    
    constant MUX_IN_VALID_TO_ADD : integer := 0;
    constant MUX_IN_VALID_TO_SUB : integer := 1;
    constant MUX_IN_VALID_TO_MUL : integer := 2;
    constant MUX_IN_VALID_TO_ENC : integer := 3;
    constant MUX_IN_VALID_TO_DEC : integer := 4;
    
    signal state                : STATE_TYPE;
        
    signal program_length       : integer := 0;
    signal program_counter      : integer := 0;
    signal instruction          : INSTRUCTION_TYPE := (others => '0');
        alias opcode : OPCODE_TYPE is instruction(31 downto 28); -- unhard code these values 'left/'range etc.
        alias buf : BUFFER_INDEX_TYPE is instruction(27 downto 24); -- unhard code these values
        
    signal buffer_a             : POLY_BUFFER := (others => (others => '0'));
    signal buffer_b             : POLY_BUFFER := (others => (others => '0'));
    signal buffer_c             : POLY_BUFFER := (others => (others => '0'));
    
    signal add_enabled : std_logic := '0';
    signal sub_enabled : std_logic := '0';
    signal mul_enabled : std_logic := '0';
    signal enc_enabled : std_logic := '0';
    signal dec_enabled : std_logic := '0';
    
    shared variable program : RAM_TYPE;
    
begin
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
              
                when RUN =>
                    if (program_counter = program_length - 1) then
                        state <= IDLE;
                    end if;
                    program_counter <= program_counter + 1;
                    instruction <= program(program_counter + 1);
                    state <= EXEC;
                    case opcode is
                        when OP_SUB =>
                            sub_enabled <= '1';
                        when OP_ADD =>
                            add_enabled <= '1';
                        when OP_MUL =>
                            mul_enabled <= '1';
                        when OP_B =>
                        --when OP_CRT =>
                        --when OP_ICRT =>
                        when OP_ENC =>
                            enc_enabled <= '1';
                        when OP_DEC =>
                            dec_enabled <= '1';
                        when OP_LOAD => -- Load "buffer" addresses with start, size and stride
                            case buf is
                                when BUF_A =>
                                    buffer_a.addr_start <= program(program_counter + 2);
                                    buffer_a.size <= program(program_counter + 3);
                                    buffer_a.stride <= program(program_counter + 4);
                                when BUF_B =>
                                    buffer_b.addr_start <= program(program_counter + 2);
                                    buffer_b.size <= program(program_counter + 3);
                                    buffer_b.stride <= program(program_counter + 4);
                                when BUF_C =>
                                    buffer_c.addr_start <= program(program_counter + 2);
                                    buffer_c.size <= program(program_counter + 3);
                                    buffer_c.stride <= program(program_counter + 4);
                                program_counter <= program_counter + 3;
                                state <= IDLE;
                            end case;
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
