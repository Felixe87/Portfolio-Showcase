library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity lfsr is 
    port(
        clk : in std_logic;
        reset : in std_logic;
        rand : out std_logic_vector(7 downto 0)
    );
end entity lfsr;

architecture behaviour of lfsr is
    signal regValue : std_logic_vector(7 downto 0) := "01001001"; -- preassigned to random seed (49)
    signal feedback : std_logic;
begin
    -- recommended tap from assignment slides
    feedback <= regValue(7) XOR regValue(3) XOR regValue(2) XOR regValue(1);

    process(clk, reset) 
    begin
        if reset = '1' then
            regValue <= "01001001";
        elsif rising_edge(clk) then
            regValue <= regValue(6 downto 0) & feedback;
        end if;
    end process;
	 
	 rand <= regValue;

end architecture behaviour;