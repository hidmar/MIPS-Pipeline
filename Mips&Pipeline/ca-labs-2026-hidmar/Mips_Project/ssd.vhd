library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SSD is
    Port ( clk : in STD_LOGIC;
           digits : in STD_LOGIC_VECTOR (15 downto 0);
           an : out STD_LOGIC_VECTOR (3 downto 0);
           cat : out STD_LOGIC_VECTOR (6 downto 0));
end SSD;

architecture Behavioral of SSD is
    signal count_int : std_logic_vector(15 downto 0) := (others => '0');
    signal hex : std_logic_vector(3 downto 0);
begin
    process(clk)
    begin
        if rising_edge(clk) then
            count_int <= count_int + 1;
        end if;
    end process;

    -- Multiplexing the 4 lower displays, upper 4 are turned off ('1')
    process(count_int(15 downto 14), digits)
    begin
        case count_int(15 downto 14) is
            when "00" => hex <= digits(3 downto 0);   an <= "1110";
            when "01" => hex <= digits(7 downto 4);   an <= "1101";
            when "10" => hex <= digits(11 downto 8);  an <= "1011";
            when others => hex <= digits(15 downto 12); an <= "0111";
        end case;
    end process;

    -- Hex to 7-Segment Decoder
    process(hex)
    begin
        case hex is
            when "0000" => cat <= "1000000"; -- 0
            when "0001" => cat <= "1111001"; -- 1
            when "0010" => cat <= "0100100"; -- 2
            when "0011" => cat <= "0110000"; -- 3
            when "0100" => cat <= "0011001"; -- 4
            when "0101" => cat <= "0010010"; -- 5
            when "0110" => cat <= "0000010"; -- 6
            when "0111" => cat <= "1111000"; -- 7
            when "1000" => cat <= "0000000"; -- 8
            when "1001" => cat <= "0010000"; -- 9
            when "1010" => cat <= "0001000"; -- A
            when "1011" => cat <= "0000011"; -- b
            when "1100" => cat <= "1000110"; -- C
            when "1101" => cat <= "0100001"; -- d
            when "1110" => cat <= "0000110"; -- E
            when others => cat <= "0001110"; -- F
        end case;
    end process;
end Behavioral;