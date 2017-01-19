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
    subtype REGISTER_INDEX_TYPE is std_logic_vector(3 downto 0);
    subtype INSTRUCTION_TYPE is std_logic_vector(C_REGISTER_WIDTH-1 downto 0);
    type RAM_TYPE is array(C_MAX_PROG_LENGTH-1 downto 0) of INSTRUCTION_TYPE;
    
    type STATE_TYPE is (IDLE, LOAD_CODE, RUN, EXEC);

    constant REG_0              : REGISTER_INDEX_TYPE := b"0000";
    constant REG_1              : REGISTER_INDEX_TYPE := b"0001";
    constant REG_2              : REGISTER_INDEX_TYPE := b"0010";   
    
    constant MODE_LOAD_CODE : CONTROL_TYPE := x"00000000";
    constant MODE_RUN       : CONTROL_TYPE := x"00000001";
    constant MODE_TERM      : CONTROL_TYPE := x"00000002";
    
    constant OP_SUB  : OPCODE_TYPE := "0000";
    constant OP_ADD  : OPCODE_TYPE := "0001";
    constant OP_MUL  : OPCODE_TYPE := "0010";
    constant OP_B    : OPCODE_TYPE := "0011";
    constant OP_CRT  : OPCODE_TYPE := "0100";
    constant OP_ICRT : OPCODE_TYPE := "0101";
    constant OP_ENC  : OPCODE_TYPE := "0110";
    constant OP_DEC  : OPCODE_TYPE := "0111";
    constant OP_LOAD : OPCODE_TYPE := "1000";
    constant OP_STORE: OPCODE_TYPE := "1001";
    
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
        alias reg : REGISTER_INDEX_TYPE is instruction(27 downto 24); -- unhard code these values
    
    constant add_enabled : std_logic_vector(4-1 downto 0) := "0000";
    constant sub_enabled : std_logic_vector(4-1 downto 0) := "0001";
    constant mul_enabled : std_logic_vector(4-1 downto 0) := "0010";
    constant enc_enabled : std_logic_vector(4-1 downto 0) := "0011";
    constant dec_enabled : std_logic_vector(4-1 downto 0) := "0100";
    
    signal mux_mode : std_logic_vector(4-1 downto 0);
    
    shared variable program : RAM_TYPE;
begin

    core_mux_inst : entity work.core_mux
        generic map (
            C_MAX_DATA_WIDTH => C_MAX_DATA_WIDTH
        )
        port map (
            clk => clk,
            a => data_a,
            b => data_b,
            c => data_out,
            mode => mux_mode
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
                        --when OP_ICRT =>
                        when OP_ENC =>
                            mux_mode <= enc_enabled;
                        when OP_DEC =>
                            mux_mode <= dec_enabled;
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
