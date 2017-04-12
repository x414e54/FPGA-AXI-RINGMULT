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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity red is
	generic (
		C_MAX_MODULUS_WIDTH : integer    := 64;
		C_MAX_INPUT_WIDTH   : integer    := 128
	);
	port (
		clk       : in std_logic;
		modulus   : in std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0)       := (others => '0');
		modulus_r : in std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0)       := (others => '0');
        modulus_s : in std_logic_vector(16-1 downto 0)                        := (others => '0');
        value     : in std_logic_vector(C_MAX_INPUT_WIDTH-1 downto 0)         := (others => '0');
		remainder : out std_logic_vector(C_MAX_MODULUS_WIDTH-1 downto 0)      := (others => '0')
	);  
end red;

architecture Behavioral of red is
signal a_reg_0 : unsigned(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');
signal a_reg_1 : unsigned(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');
signal a_reg_2 : unsigned(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');
signal a_reg_3 : unsigned(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');
signal a_reg_4 : unsigned(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');

signal b_reg : unsigned(C_MAX_MODULUS_WIDTH-1 downto 0) := (others => '0');
signal c_reg : unsigned(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');
signal d_reg : unsigned(C_MAX_MODULUS_WIDTH-1 downto 0) := (others => '0');
signal e_reg : unsigned(C_MAX_INPUT_WIDTH-1 downto 0) := (others => '0');
signal f_reg : unsigned(C_MAX_MODULUS_WIDTH-1 downto 0) := (others => '0');
begin
    state_proc : process (clk) is
    begin	
        if rising_edge(clk) then
            -- pipeline barret
            -- convert to shift register
            a_reg_4 <= a_reg_3;
            a_reg_3 <= a_reg_2;
            a_reg_2 <= a_reg_1;
            a_reg_1 <= a_reg_0;
            a_reg_0 <= unsigned(value);
            --
            b_reg <= a_reg_0 srl 60;--modulus_s;
            c_reg <= b_reg * unsigned(modulus_r);
            d_reg <= c_reg srl 60;--modulus_s;
            e_reg <= b_reg * unsigned(modulus);
            f_reg <= a_reg_4 - e_reg;
            
            if (f_reg >= unsigned(modulus)) then
                remainder <= std_logic_vector(f_reg - unsigned(modulus));
            else
                remainder <= std_logic_vector(f_reg);
            end if; 
        end if;
    end process state_proc;

end Behavioral;
