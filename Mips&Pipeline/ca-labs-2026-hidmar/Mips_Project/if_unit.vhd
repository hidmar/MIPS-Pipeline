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
        -- I-Type Initialization
        B"001_000_001_0001010", -- 00: ADDI $1, $0, 10    | $1 = 10 (0x000A)
        B"001_000_010_0000101", -- 01: ADDI $2, $0, 5     | $2 = 5  (0x0005)
        
        -- R-Type Arithmetic
        B"000_001_010_011_0_000", -- 02: ADD  $3, $1, $2  | $3 = 10 + 5 = 15 (0x000F)
        B"000_001_010_100_0_001", -- 03: SUB  $4, $1, $2  | $4 = 10 - 5 = 5  (0x0005)
        
        -- R-Type Shifts (sa = 1)
        B"000_000_010_101_1_010", -- 04: SLL  $5, $2, 1   | $5 = 5 << 1 = 10 (0x000A)
        B"000_000_010_110_1_011", -- 05: SRL  $6, $2, 1   | $6 = 5 >> 1 = 2  (0x0002)
        
        -- R-Type Logical
        B"000_001_010_111_0_100", -- 06: AND  $7, $1, $2  | $7 = 10 AND 5 = 0 (0x0000)
        B"000_001_010_011_0_101", -- 07: OR   $3, $1, $2  | $3 = 10 OR 5 = 15 (0x000F)
        B"000_001_010_100_0_110", -- 08: XOR  $4, $1, $2  | $4 = 10 XOR 5 = 15 (0x000F)
        
        -- R-Type Set on Less Than
        B"000_010_001_101_0_111", -- 09: SLT  $5, $2, $1  | $5 = (5 < 10) ? 1 : 0 = 1 (0x0001)
        
        -- I-Type Logical Immediate
        B"110_001_110_0000010", -- 10: ANDI $6, $1, 2     | $6 = 10 AND 2 = 2 (0x0002)
        
        -- Memory Operations
        B"011_000_001_0000000", -- 11: SW   $1, 0($0)     | Mem[0] = $1 (Stores 10 at address 0)
        B"010_000_111_0000000", -- 12: LW   $7, 0($0)     | $7 = Mem[0] (Loads 10 into $7)
        
        -- Branching (Testing BNE and BEQ)
        B"101_111_001_0000001", -- 13: BNE  $7, $1, 1     | if ($7 != $1) PC=PC+1+1. Since 10==10, it DOES NOT branch.
        B"100_111_001_0000001", -- 14: BEQ  $7, $1, 1     | if ($7 == $1) PC=PC+1+1. Since 10==10, it DOES branch to 16.
        
        -- Padding / Jump Target Tests
        B"001_001_001_0000001", -- 15: ADDI $1, $1, 1     | Skipped over by BEQ. If executed, branching failed!
        
        -- Jump Operation (Infinite Loop to end program)
        B"111_0000000010000",   -- 16: J    16            | Jumps to address 16, creating an infinite loop to halt execution.
        
        others => x"0000"
    );
begin

    -- PC Register
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

    -- PC Adder (+1)
    PC_adder <= PC + 1;
    PC_plus_1 <= PC_adder;

    -- Multiplexers for next instruction address
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

    -- Asynchronous ROM Read
    Instruction <= ROM(conv_integer(PC(7 downto 0)));

end Behavioral;