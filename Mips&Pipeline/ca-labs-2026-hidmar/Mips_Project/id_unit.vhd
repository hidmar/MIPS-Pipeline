library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ID_Unit is
    Port ( clk : in STD_LOGIC;
           en : in STD_LOGIC;
           RegWrite : in STD_LOGIC;
           Instr : in STD_LOGIC_VECTOR(15 downto 0);
           RegDst : in STD_LOGIC;
           ExtOp : in STD_LOGIC;
           WD : in STD_LOGIC_VECTOR(15 downto 0);
           RD1 : out STD_LOGIC_VECTOR(15 downto 0);
           RD2 : out STD_LOGIC_VECTOR(15 downto 0);
           Ext_Imm : out STD_LOGIC_VECTOR(15 downto 0);
           func : out STD_LOGIC_VECTOR(2 downto 0);
           sa : out STD_LOGIC);
end ID_Unit;

architecture Behavioral of ID_Unit is
    type reg_array is array (0 to 7) of std_logic_vector(15 downto 0);
    signal reg_file : reg_array := (others => x"0000");
    
    signal WriteAddress : std_logic_vector(2 downto 0);
begin
    -- MUX for Write Address (RegDst)
    WriteAddress <= Instr(6 downto 4) when RegDst = '1' else Instr(9 downto 7);

    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' and RegWrite = '1' then
                reg_file(conv_integer(WriteAddress)) <= WD;
            end if;
        end if;
    end process;

    RD1 <= reg_file(conv_integer(Instr(12 downto 10)));
    RD2 <= reg_file(conv_integer(Instr(9 downto 7)));

    Ext_Imm(6 downto 0) <= Instr(6 downto 0);
    Ext_Imm(15 downto 7) <= (others => Instr(6)) when ExtOp = '1' else (others => '0');

    -- Pass function and shift amount
    func <= Instr(2 downto 0);
    sa <= Instr(3);

end Behavioral;