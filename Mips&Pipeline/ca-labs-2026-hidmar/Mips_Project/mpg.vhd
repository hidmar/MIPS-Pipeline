library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity MPG is
    Port ( en : out STD_LOGIC;
           input : in STD_LOGIC;
           clock : in STD_LOGIC);
end MPG;

architecture Behavioral of MPG is
    signal count_int : std_logic_vector(15 downto 0) := (others => '0');
    signal Q1, Q2, Q3 : std_logic := '0';
begin
    process(clock)
    begin
        if rising_edge(clock) then
            count_int <= count_int + 1;
        end if;
    end process;

    process(clock)
    begin
        if rising_edge(clock) then
            if count_int(15 downto 0) = x"FFFF" then
                Q1 <= input;
            end if;
        end if;
    end process;

    process(clock)
    begin
        if rising_edge(clock) then
            Q2 <= Q1;
            Q3 <= Q2;
        end if;
    end process;

    en <= Q2 and (not Q3);
end Behavioral;