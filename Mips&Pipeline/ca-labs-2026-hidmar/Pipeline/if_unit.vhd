library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity IF_Unit is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in STD_LOGIC;
           BranchAddress : in STD_LOGIC_VECTOR(15 downto 0);
           JumpAddress : in STD_LOGIC_VECTOR(15 downto 0);
           Jump : in STD_LOGIC;
           PCSrc : in STD_LOGIC;
           Instruction : out STD_LOGIC_VECTOR(15 downto 0);
           PC_plus_1 : out STD_LOGIC_VECTOR(15 downto 0));
end IF_Unit;

architecture Behavioral of IF_Unit is
    signal PC : std_logic_vector(15 downto 0) := (others => '0');
    signal next_PC : std_logic_vector(15 downto 0);
    signal PC_adder : std_logic_vector(15 downto 0);
    
    type rom_type is array (0 to 255) of std_logic_vector(15 downto 0);
    
    signal ROM : rom_type := (
        signal ROM : rom_type := (
        B"001_000_001_0000101",   -- 00: ADDI $1, $0, 5    (Write 5 to $1)
        x"0000",                  -- 01: NoOp (Wait for EX)
        x"0000",                  -- 02: NoOp (Wait for MEM)
        x"0000",                  -- 03: NoOp (Wait for WB)
        
        B"001_001_010_0000010",   -- 04: ADDI $2, $1, 2    (Reads $1. 5 + 2 = 7. Write to $2)
        x"0000",                  -- 05: NoOp (Wait for EX)
        x"0000",                  -- 06: NoOp (Wait for MEM)
        x"0000",                  -- 07: NoOp (Wait for WB)
        
        B"000_001_010_011_0_000", -- 08: ADD  $3, $1, $2   (Reads $1 and $2. 5 + 7 = 12. Write to $3)
        x"0000",                  -- 09: NoOp (Wait for EX)
        x"0000",                  -- 10: NoOp (Wait for MEM)
        x"0000",                  -- 11: NoOp (Wait for WB)
        
        B"111_0000000001100",     -- 12: J 12 (Infinite loop)
        others => x"0000"
    );
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                PC <= x"0000";
            elsif en = '1' then
                PC <= next_PC;
            end if;
        end if;
    end process;

    PC_adder <= PC + 1;
    PC_plus_1 <= PC_adder;

    process(Jump, PCSrc, PC_adder, BranchAddress, JumpAddress)
    begin
        if Jump = '1' then
            next_PC <= JumpAddress;
        elsif PCSrc = '1' then
            next_PC <= BranchAddress;
        else
            next_PC <= PC_adder;
        end if;
    end process;

    Instruction <= ROM(conv_integer(PC(7 downto 0)));

end Behavioral;