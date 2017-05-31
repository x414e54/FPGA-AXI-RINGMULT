----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2017/04/03 13:09:21
-- Design Name: 
-- Module Name: rem_fold_reg_core - Behavioral
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

entity rem_fold_reg_core is
	generic (
		C_MAX_MODULUS_WIDTH : integer    := 64;
		C_INPUT_WIDTH       : integer    := 64
	);
	port (
		clk       : in std_logic;
		value     : in std_logic_vector(C_INPUT_WIDTH-1 downto 0)                         := (others => '0');     
        m         : in std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0)                   := (others => '0');
		fold      : out std_logic_vector(C_INPUT_WIDTH-C_MAX_MODULUS_WIDTH-1 downto 0)    := (others => '0');
		carry     : out std_logic
	);  
end rem_fold_reg_core;

architecture Behavioral of rem_fold_reg_core is

    signal a_reg : unsigned(C_INPUT_WIDTH-1 downto 0) := (others => '0');
    alias a_reg_top : unsigned(C_MAX_MODULUS_WIDTH-1 downto 0) is a_reg(C_INPUT_WIDTH-1 downto C_INPUT_WIDTH-C_MAX_MODULUS_WIDTH);
    signal b_reg : unsigned((2*C_MAX_MODULUS_WIDTH)-1 downto 0) := (others => '0');
    signal c_reg : unsigned(C_INPUT_WIDTH-C_MAX_MODULUS_WIDTH-1 downto 0) := (others => '0');
    
begin
    
    state_proc : process (clk) is
    begin	
        if rising_edge(clk) then
            c_reg <= resize(a_reg, C_INPUT_WIDTH-C_MAX_MODULUS_WIDTH);
            a_reg <= unsigned(value);
            b_reg <= unsigned(m) * a_reg_top;
            fold <= std_logic_vector(b_reg + c_reg);
        end if;
    end process state_proc;

end Behavioral;
