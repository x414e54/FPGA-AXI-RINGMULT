----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2017/04/03 13:09:21
-- Design Name: 
-- Module Name: reduce - Behavioral
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package rem_pkg is
	type rem_bus is array(natural range <>) of std_logic_vector(64-1 downto 0);
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.rem_pkg.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rem_fold is
	generic (
		C_MAX_MODULUS_WIDTH : integer    := 64;
		C_MAX_INPUT_WIDTH   : integer    := 256;
        C_MAX_INPUT_LEN     : integer    := 256/64;--C_MAX_INPUT_WIDTH / C_MAX_MODULUS_WIDTH;
        C_MAX_MODULUS_FOLDS : integer    := (256/64)-2;--C_MAX_INPUT_LEN - 2
        C_PARAM_ADDR_TOP    : integer    := x"0000"
	);
	port (
		clk               : in std_logic;
		----
        param          : in std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0)     := (others => '0');
        param_addr     : in std_logic_vector(32-1 downto 0)                      := (others => '0');
        param_valid    : in std_logic;
        ----
        modulus        : in std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0)     := (others => '0');
        modulus_r      : in std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0)     := (others => '0');
        modulus_s      : in std_logic_vector(16-1 downto 0)                      := (others => '0'); 
        ----
        value             : in std_logic_vector(C_MAX_INPUT_WIDTH-1 downto 0)    := (others => '0');
		remainder         : out std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0) := (others => '0')
	);  
end rem_fold;

architecture Behavioral of rem_fold is
type REGISTER_TYPE is array(natural range <>) of std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0);

type fold_array is array(natural range <>) of std_logic_vector(C_MAX_INPUT_WIDTH-1 downto 0);
signal red_reg : std_logic_vector((2*C_MAX_MODULUS_WIDTH)-1 downto 0) := (others => '0');
signal fold_reg : fold_array(0 to C_MAX_MODULUS_FOLDS) := (others => (others => '0'));
signal fold_carry_reg : std_logic_vector(C_MAX_MODULUS_FOLDS-1 downto 0) := (others => '0');

signal modulus_ms : in REGISTER_TYPE(0 to (C_MAX_MODULUS_FOLDS+3)-1) := (others => '0'): 
         
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
               if (param_valid = '1' and param_addr = C_PARAM_ADDR_TOP) then
                   modulus_ms(param_addr) <= param;
               end if;
           end if;
       end process state_proc;
end Behavioral;
