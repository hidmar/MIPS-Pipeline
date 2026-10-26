library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity test_env is
    Port ( clk : in STD_LOGIC;
           btn : in STD_LOGIC_VECTOR (4 downto 0);
           sw : in STD_LOGIC_VECTOR (15 downto 0);
           led : out STD_LOGIC_VECTOR (15 downto 0);
           an : out STD_LOGIC_VECTOR (3 downto 0);
           cat : out STD_LOGIC_VECTOR (6 downto 0));
end test_env;

architecture Behavioral of test_env is

    -- Component Declarations
    component MPG
        Port ( en : out STD_LOGIC; input : in STD_LOGIC; clock : in STD_LOGIC);
    end component;

    component SSD
        Port ( clk : in STD_LOGIC; digits : in STD_LOGIC_VECTOR (15 downto 0); an : out STD_LOGIC_VECTOR (3 downto 0); cat : out STD_LOGIC_VECTOR (6 downto 0));
    end component;

    component IF_Unit
        Port ( clk, rst, en : in STD_LOGIC; BranchAddress, JumpAddress : in STD_LOGIC_VECTOR(15 downto 0); Jump, PCSrc : in STD_LOGIC; Instruction, PC_plus_1 : out STD_LOGIC_VECTOR(15 downto 0));
    end component;

    component ID_Unit
        Port ( clk, en, RegWrite : in STD_LOGIC; Instr : in STD_LOGIC_VECTOR(15 downto 0); RegDst, ExtOp : in STD_LOGIC; WD : in STD_LOGIC_VECTOR(15 downto 0); RD1, RD2, Ext_Imm : out STD_LOGIC_VECTOR(15 downto 0); func : out STD_LOGIC_VECTOR(2 downto 0); sa : out STD_LOGIC);
    end component;

    component EX_Unit
        Port ( PC_plus_1, RD1, RD2, Ext_Imm : in STD_LOGIC_VECTOR(15 downto 0); func : in STD_LOGIC_VECTOR(2 downto 0); sa, ALUSrc : in STD_LOGIC; ALUOp : in STD_LOGIC_VECTOR(2 downto 0); BranchAddress, ALURes : out STD_LOGIC_VECTOR(15 downto 0); Zero : out STD_LOGIC);
    end component;

    component MEM_Unit
        Port ( clk, en : in STD_LOGIC; ALURes, RD2 : in STD_LOGIC_VECTOR(15 downto 0); MemWrite : in STD_LOGIC; MemData, ALURes_out : out STD_LOGIC_VECTOR(15 downto 0));
    end component;

    -- Signals interconnecting the units
    signal en, rst : std_logic;
    signal Instruction, PC_plus_1 : std_logic_vector(15 downto 0);
    signal RD1, RD2, Ext_Imm : std_logic_vector(15 downto 0);
    signal func : std_logic_vector(2 downto 0);
    signal sa : std_logic;
    signal BranchAddress, ALURes, ALURes_out, MemData, WD : std_logic_vector(15 downto 0);
    signal Zero : std_logic;
    signal JumpAddress : std_logic_vector(15 downto 0);
    
    -- Control Signals
    signal RegDst, ExtOp, ALUSrc, Branch, Jump, MemWrite, MemtoReg, RegWrite : std_logic;
    signal ALUOp : std_logic_vector(2 downto 0);
    signal PCSrc : std_logic;
    
    -- Mux Output for SSD
    signal digits_out : std_logic_vector(15 downto 0);

begin
    -- Debouncers for buttons
    btn_en: MPG port map (en => en, input => btn(0), clock => clk);
    btn_rst: MPG port map (en => rst, input => btn(1), clock => clk);

    -- Main Control Unit (Inline Decoder)
    process(Instruction(15 downto 13))
    begin
        RegDst <= '0'; ExtOp <= '0'; ALUSrc <= '0'; Branch <= '0'; 
        Jump <= '0'; MemWrite <= '0'; MemtoReg <= '0'; RegWrite <= '0'; 
        ALUOp <= "000";

        case Instruction(15 downto 13) is
            when "000" => -- R-Type
                RegDst <= '1'; RegWrite <= '1'; ALUOp <= "000";
            when "001" => -- ADDI
                ExtOp <= '1'; ALUSrc <= '1'; RegWrite <= '1'; ALUOp <= "001";
            when "010" => -- LW
                ExtOp <= '1'; ALUSrc <= '1'; MemtoReg <= '1'; RegWrite <= '1'; ALUOp <= "001";
            when "011" => -- SW
                ExtOp <= '1'; ALUSrc <= '1'; MemWrite <= '1'; ALUOp <= "001";
            when "100" => -- BEQ
                ExtOp <= '1'; Branch <= '1'; ALUOp <= "010";
            when "111" => -- J
                Jump <= '1';
            when others => null;
        end case;
    end process;

    -- PCSrc and Jump Address Calculation
    PCSrc <= Branch and Zero;
    JumpAddress <= PC_plus_1(15 downto 13) & Instruction(12 downto 0);

    -- Write Back Multiplexer
    WD <= MemData when MemtoReg = '1' else ALURes_out;

    -- Component Instantiations
    IF_inst: IF_Unit port map (clk, rst, en, BranchAddress, JumpAddress, Jump, PCSrc, Instruction, PC_plus_1);
    ID_inst: ID_Unit port map (clk, en, RegWrite, Instruction, RegDst, ExtOp, WD, RD1, RD2, Ext_Imm, func, sa);
    EX_inst: EX_Unit port map (PC_plus_1, RD1, RD2, Ext_Imm, func, sa, ALUSrc, ALUOp, BranchAddress, ALURes, Zero);
    MEM_inst: MEM_Unit port map (clk, en, ALURes, RD2, MemWrite, MemData, ALURes_out);

    -- Multiplexing data to the SSD
    process(sw(7 downto 5), Instruction, PC_plus_1, RD1, RD2, Ext_Imm, ALURes, MemData, WD)
    begin
        case sw(7 downto 5) is
            when "000" => digits_out <= Instruction;
            when "001" => digits_out <= PC_plus_1;
            when "010" => digits_out <= RD1;
            when "011" => digits_out <= RD2;
            when "100" => digits_out <= Ext_Imm;
            when "101" => digits_out <= ALURes;
            when "110" => digits_out <= MemData;
            when others => digits_out <= WD;
        end case;
    end process;

    disp: SSD port map (clk => clk, digits => digits_out, an => an, cat => cat);

    -- Display Control Signals on LEDs
    process(sw(0), RegDst, ExtOp, ALUSrc, Branch, Jump, MemWrite, MemtoReg, RegWrite, ALUOp)
    begin
        if sw(0) = '0' then
            led(7 downto 0) <= RegDst & ExtOp & ALUSrc & Branch & Jump & MemWrite & MemtoReg & RegWrite;
            led(15 downto 8) <= (others => '0');
        else
            led(2 downto 0) <= ALUOp;
            led(15 downto 3) <= (others => '0');
        end if;
    end process;

end Behavioral;