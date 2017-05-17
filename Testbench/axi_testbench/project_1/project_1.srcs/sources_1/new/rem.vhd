----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2017/04/03 13:09:21
-- Design Name: 
-- Module Name: rem_fold - Behavioral
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

entity rem_fold is
	generic (
	    C_PARAM_WIDTH       : integer    := 64;
        C_PARAM_ADDR_WIDTH  : integer    := 32;
        C_PARAM_ADDR_FOLDS  : integer    := x"0000";
        C_LENGTH_WIDTH      : integer    := 16;	
		C_MAX_MODULUS_WIDTH : integer    := 64;
		C_MAX_INPUT_WIDTH   : integer    := 256;
        C_MAX_INPUT_LEN     : integer    := 256/64;--C_MAX_INPUT_WIDTH / C_MAX_MODULUS_WIDTH;
        C_MAX_MODULUS_FOLDS : integer    := (256/64)-2--C_MAX_INPUT_LEN - 2
	);
	port (
		clk            : in std_logic;
		----
        param          : in std_logic_vector(C_PARAM_WIDTH-1 downto 0)           := (others => '0');
        param_addr     : in std_logic_vector(C_PARAM_ADDR_WIDTH-1 downto 0)      := (others => '0');
        param_valid    : in std_logic;
        ----
        modulus        : in std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0)     := (others => '0');
        modulus_r      : in std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0)     := (others => '0');
        modulus_s      : in std_logic_vector(C_LENGTH_WIDTH-1 downto 0)          := (others => '0'); 
        ----
        value          : in std_logic_vector(C_MAX_INPUT_WIDTH-1 downto 0)    := (others => '0');
		remainder      : out std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0) := (others => '0')
	);  
end rem_fold;

architecture Behavioral of rem_fold is

    type REGISTER_TYPE is array(natural range <>) of std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0);

    type fold_array is array(natural range <>) of std_logic_vector(C_MAX_INPUT_WIDTH-1 downto 0);
    signal red_reg : std_logic_vector((2*C_MAX_MODULUS_WIDTH)-1 downto 0) := (others => '0');
    signal fold_reg : fold_array(0 to C_MAX_MODULUS_FOLDS) := (others => (others => '0'));
    signal fold_carry_reg : std_logic_vector(C_MAX_MODULUS_FOLDS-1 downto 0) := (others => '0');

    signal modulus_ms : REGISTER_TYPE(0 to C_MAX_MODULUS_FOLDS-1) := (others => '0');

    alias param_addr_top : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is param_addr(C_PARAM_ADDR_WIDTH-1 downto C_PARAM_ADDR_WIDTH/2);
    alias param_addr_bottom : std_logic_vector((C_PARAM_ADDR_WIDTH/2)-1 downto 0) is param_addr((C_PARAM_ADDR_WIDTH/2)-1 downto 0);
         
begin
    fold_reg(0) <= value;
    red_reg <= fold_reg(C_MAX_MODULUS_FOLDS)((2*C_MAX_MODULUS_WIDTH)-1 downto 0);
    
	folds : for i in 0 to C_MAX_MODULUS_FOLDS - 1 generate
		fold_i : entity work.rem_fold_reg
			generic map (
				C_MAX_MODULUS_WIDTH => C_MAX_MODULUS_WIDTH,
				C_INPUT_WIDTH   => C_MAX_INPUT_WIDTH-(i*C_MAX_MODULUS_WIDTH) 
			)
			port map (
				clk	      => clk,
				value	  => fold_reg(i)(C_MAX_INPUT_WIDTH-(i*C_MAX_MODULUS_WIDTH)-1 downto 0),
                m	      => modulus_ms(i),
				fold      => fold_reg(i+1)(C_MAX_INPUT_WIDTH-((i+1)*C_MAX_MODULUS_WIDTH)-1 downto 0)
			);
	end generate folds;
	
    red : entity work.red
	   generic map (
		  C_MAX_MODULUS_WIDTH => C_MAX_MODULUS_WIDTH,
		  C_MAX_INPUT_WIDTH   => 2 * C_MAX_MODULUS_WIDTH
	   )
	   port map (
		  clk       => clk,
		  modulus   => modulus,
		  modulus_r => modulus_r,
          modulus_s => modulus_s,
          value     => red_reg,
		  remainder => remainder
	   );
	   
       state_proc : process (clk) is
       begin	
           if rising_edge(clk) then
               if (param_valid = '1' and param_addr_top = C_PARAM_ADDR_FOLDS) then
                   modulus_ms(param_addr_bottom) <= param;
               end if;
           end if;
       end process state_proc;
end Behavioral;
