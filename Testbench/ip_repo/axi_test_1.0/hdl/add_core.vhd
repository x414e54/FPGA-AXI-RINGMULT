----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/19/2017 02:00:20 PM
-- Design Name: 
-- Module Name: add_core - Behavioral
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
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity add_core is
	Generic (C_MAX_DATA_WIDTH    : integer    := 32);
    Port ( clk : in STD_LOGIC;
           a : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
           b : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
           q : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
           c : out std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0));
end add_core;

architecture Behavioral of add_core is
    signal a_reg : unsigned(a'length - 1 downto 0);
    signal b_reg : unsigned(b'length - 1 downto 0);
    signal q_reg : unsigned(q'length - 1 downto 0);
    signal c_reg : unsigned(c'length - 1 downto 0);
begin
    add_proc : process (clk) is
    begin    
        if rising_edge(clk) then
            a_reg <= unsigned(a);
            b_reg <= unsigned(b);
            q_reg <= unsigned(q);
            
            c_reg <= a_reg + b_reg mod q_reg;
            c <= std_logic_vector(c_reg);
        end if;
    end process add_proc;
end Behavioral;
