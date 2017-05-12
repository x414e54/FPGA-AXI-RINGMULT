----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 01/19/2017 02:00:20 PM
-- Design Name: 
-- Module Name: enc_core - Behavioral
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

entity enc_core is
	Generic (C_MAX_DATA_WIDTH    : integer    := 32);
    Port ( clk : in STD_LOGIC;
           a : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
           b : in std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0);
           c : out std_logic_vector(C_MAX_DATA_WIDTH-1 downto 0));
end enc_core;

architecture Behavioral of enc_core is

begin
    -- put this here for now
    fft_proc : process (clk) is
    begin    
        if rising_edge(clk) then
        end if;
    end process fft_proc;
end Behavioral;
