library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity MEM_Unit is
    Port ( clk : in STD_LOGIC;
           en : in STD_LOGIC;
           ALURes : in STD_LOGIC_VECTOR(15 downto 0);
           RD2 : in STD_LOGIC_VECTOR(15 downto 0);
           MemWrite : in STD_LOGIC;
           MemData : out STD_LOGIC_VECTOR(15 downto 0);
           ALURes_out : out STD_LOGIC_VECTOR(15 downto 0));
end MEM_Unit;

architecture Behavioral of MEM_Unit is
    type ram_type is array (0 to 255) of std_logic_vector(15 downto 0);
    signal RAM : ram_type := (others => x"0000");
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' and MemWrite = '1' then
                RAM(conv_integer(ALURes(7 downto 0))) <= RD2;
            end if;
        end if;
    end process;

    MemData <= RAM(conv_integer(ALURes(7 downto 0)));
    
    ALURes_out <= ALURes;

end Behavioral;