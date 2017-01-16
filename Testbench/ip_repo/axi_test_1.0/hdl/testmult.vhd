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
        C_MAX_DATA_WIDTH    : integer    := 32;
        C_REGISTER_WIDTH    : integer    := 32
	);
    Port ( clk : in std_logic;
           reset : in std_logic;
           start : in std_logic;
           mode : in std_logic_vector(C_REGISTER_WIDTH-1 downto 0);
           valid_a : in std_logic;
           data_in_a : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
           valid_b : in std_logic;
           data_in_b : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
           valid : out std_logic;
           data_out : out std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0));
end testmult;

architecture Behavioral of testmult is
    subtype CONTROL_TYPE is std_logic_vector(C_REGISTER_WIDTH-1 downto 0);
    subtype OPCODE_TYPE is std_logic_vector(3 downto 0);
    type INSTRUCTION_TYPE is record
        opcode  : OPCODE_TYPE;
        reg     : std_logic_vector(C_REGISTER_WIDTH-5 downto C_REGISTER_WIDTH-7);
        rfu     : std_logic_vector(C_REGISTER_WIDTH-8 downto 0);
    end record INSTRUCTION_TYPE;  
    type POLY_BUFFER is record
        addr_start      : std_logic_vector(C_REGISTER_WIDTH-1 downto 0);
        size            : std_logic_vector(C_REGISTER_WIDTH-1 downto 0);
        stride          : std_logic_vector(C_REGISTER_WIDTH-1 downto 0);
    end record POLY_BUFFER;  
    
    type STATE_TYPE is (IDLE, LOAD_CODE, RUN, EXEC);
    
    signal state                : STATE_TYPE;
    signal program_counter      : std_logic_vector(C_REGISTER_WIDTH-1 downto 0) := (others => '0');
    signal instruction          : INSTRUCTION_TYPE := (others => (others => '0'));
    signal buffer_a             : POLY_BUFFER := (others => (others => '0'));
    signal buffer_b             : POLY_BUFFER := (others => (others => '0'));
    signal buffer_c             : POLY_BUFFER := (others => (others => '0'));
        
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
    
begin
    state_proc : process (clk) is
    begin	
        if clk'event and clk = '1' then
            case state is
                when IDLE =>
                    if (start = '1') then
                        case mode is
                            when MODE_LOAD_CODe =>
                                state <= LOAD_CODE;
                            when MODE_RUN =>
                                state <= RUN;
                            when others =>
                                --- Set error register
                        end case;
                    end if;
                   
                when LOAD_CODE =>
                    assert(false);
              
                when RUN =>
                    --program_counter <= program_counter + 1;
                    case instruction.opcode is
                        when OP_SUB =>
                        when OP_ADD =>
                        when OP_MUL =>
                        when OP_B =>
                        when OP_CRT =>
                        when OP_ICRT =>
                        when OP_ENC =>
                        when OP_DEC =>
                        when OP_LOAD => -- Load "buffer" addresses with start, size and stride
                        when others =>
                            --- Set error register
                    end case;
                
                when EXEC => --- Execute current instruction
                
                
            end case;
        end if;
    end process state_proc;
end Behavioral;
