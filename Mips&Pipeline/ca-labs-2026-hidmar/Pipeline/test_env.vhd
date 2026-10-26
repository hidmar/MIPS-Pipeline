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
        Port ( clk, en, RegWrite : in STD_LOGIC; Instr : in STD_LOGIC_VECTOR(15 downto 0); ExtOp : in STD_LOGIC; WD : in STD_LOGIC_VECTOR(15 downto 0); WA : in STD_LOGIC_VECTOR(2 downto 0); RD1, RD2, Ext_Imm : out STD_LOGIC_VECTOR(15 downto 0); func : out STD_LOGIC_VECTOR(2 downto 0); sa : out STD_LOGIC);
    end component;

    component EX_Unit
        Port ( PC_plus_1, RD1, RD2, Ext_Imm : in STD_LOGIC_VECTOR(15 downto 0); func : in STD_LOGIC_VECTOR(2 downto 0); sa, ALUSrc : in STD_LOGIC; ALUOp : in STD_LOGIC_VECTOR(2 downto 0); BranchAddress, ALURes : out STD_LOGIC_VECTOR(15 downto 0); Zero : out STD_LOGIC);
    end component;

    component MEM_Unit
        Port ( clk, en : in STD_LOGIC; ALURes, RD2 : in STD_LOGIC_VECTOR(15 downto 0); MemWrite : in STD_LOGIC; MemData, ALURes_out : out STD_LOGIC_VECTOR(15 downto 0));
    end component;

    signal en, rst : std_logic;
    signal Instruction, PC_plus_1 : std_logic_vector(15 downto 0);
    signal RD1, RD2, Ext_Imm : std_logic_vector(15 downto 0);
    signal func : std_logic_vector(2 downto 0);
    signal sa : std_logic;
    signal BranchAddress, ALURes, ALURes_out, MemData, WD : std_logic_vector(15 downto 0);
    signal Zero : std_logic;
    signal JumpAddress : std_logic_vector(15 downto 0);
    
    signal RegDst, ExtOp, ALUSrc, Branch, Jump, MemWrite, MemtoReg, RegWrite : std_logic;
    signal ALUOp : std_logic_vector(2 downto 0);
    signal PCSrc : std_logic;
    
    signal digits_out : std_logic_vector(15 downto 0);

    --PIPELINE REGISTERS
    -- IF/ID Stage
    signal IF_ID_PC_plus_1, IF_ID_Instruction : std_logic_vector(15 downto 0);
    
    -- ID/EX Stage
    signal ID_EX_PC_plus_1, ID_EX_RD1, ID_EX_RD2, ID_EX_Ext_Imm : std_logic_vector(15 downto 0);
    signal ID_EX_func : std_logic_vector(2 downto 0);
    signal ID_EX_sa : std_logic;
    signal ID_EX_rt, ID_EX_rd : std_logic_vector(2 downto 0);
    signal ID_EX_RegDst, ID_EX_ALUSrc, ID_EX_Branch, ID_EX_MemWrite, ID_EX_MemtoReg, ID_EX_RegWrite : std_logic;
    signal ID_EX_ALUOp : std_logic_vector(2 downto 0);
    
    -- EX/MEM Stage
    signal EX_MEM_BranchAddress, EX_MEM_ALURes, EX_MEM_RD2 : std_logic_vector(15 downto 0);
    signal EX_MEM_Zero : std_logic;
    signal EX_MEM_WriteAddress : std_logic_vector(2 downto 0);
    signal EX_MEM_Branch, EX_MEM_MemWrite, EX_MEM_MemtoReg, EX_MEM_RegWrite : std_logic;
    
    -- MEM/WB Stage
    signal MEM_WB_MemData, MEM_WB_ALURes : std_logic_vector(15 downto 0);
    signal MEM_WB_WriteAddress : std_logic_vector(2 downto 0);
    signal MEM_WB_MemtoReg, MEM_WB_RegWrite : std_logic;

begin
    -- Debouncers
    btn_en: MPG port map (en => en, input => btn(0), clock => clk);
    btn_rst: MPG port map (en => rst, input => btn(1), clock => clk);

    -- PIPELINE REGISTER PROCESS 
    process(clk)
    begin
        if rising_edge(clk) then
            if en = '1' then
                -- 1. IF/ID Register
                IF_ID_PC_plus_1 <= PC_plus_1;
                IF_ID_Instruction <= Instruction;
                
                -- 2. ID/EX Register
                ID_EX_PC_plus_1 <= IF_ID_PC_plus_1;
                ID_EX_RD1 <= RD1;
                ID_EX_RD2 <= RD2;
                ID_EX_Ext_Imm <= Ext_Imm;
                ID_EX_func <= func;
                ID_EX_sa <= sa;
                ID_EX_rt <= IF_ID_Instruction(9 downto 7);
                ID_EX_rd <= IF_ID_Instruction(6 downto 4)
                
                -- Pass Control Signals
                ID_EX_RegDst <= RegDst;
                ID_EX_ALUSrc <= ALUSrc;
                ID_EX_Branch <= Branch;
                ID_EX_MemWrite <= MemWrite;
                ID_EX_MemtoReg <= MemtoReg;
                ID_EX_RegWrite <= RegWrite;
                ID_EX_ALUOp <= ALUOp;

                -- 3. EX/MEM Register
                EX_MEM_BranchAddress <= BranchAddress;
                EX_MEM_ALURes <= ALURes;
                EX_MEM_Zero <= Zero;
                EX_MEM_RD2 <= ID_EX_RD2;
                
                -- Calculate Write Address (MUX for RegDst)
                if ID_EX_RegDst = '1' then
                    EX_MEM_WriteAddress <= ID_EX_rd;
                else
                    EX_MEM_WriteAddress <= ID_EX_rt;
                end if;

                -- Pass Control Signals
                EX_MEM_Branch <= ID_EX_Branch;
                EX_MEM_MemWrite <= ID_EX_MemWrite;
                EX_MEM_MemtoReg <= ID_EX_MemtoReg;
                EX_MEM_RegWrite <= ID_EX_RegWrite;

                -- 4. MEM/WB Register
                MEM_WB_MemData <= MemData;
                MEM_WB_ALURes <= ALURes_out;
                MEM_WB_WriteAddress <= EX_MEM_WriteAddress;
                
                -- Pass Control Signals
                MEM_WB_MemtoReg <= EX_MEM_MemtoReg;
                MEM_WB_RegWrite <= EX_MEM_RegWrite;
            end if;
        end if;
    end process;

    -- MAIN CONTROL UNIT
    -- Now reads from IF/ID Register instead of the direct IF output
    process(IF_ID_Instruction(15 downto 13))
    begin
        RegDst <= '0'; ExtOp <= '0'; ALUSrc <= '0'; Branch <= '0'; 
        Jump <= '0'; MemWrite <= '0'; MemtoReg <= '0'; RegWrite <= '0'; ALUOp <= "000";

        case IF_ID_Instruction(15 downto 13) is
            when "000" => RegDst <= '1'; RegWrite <= '1'; ALUOp <= "000"; -- R-Type
            when "001" => ExtOp <= '1'; ALUSrc <= '1'; RegWrite <= '1'; ALUOp <= "001"; -- ADDI
            when "010" => ExtOp <= '1'; ALUSrc <= '1'; MemtoReg <= '1'; RegWrite <= '1'; ALUOp <= "001"; -- LW
            when "011" => ExtOp <= '1'; ALUSrc <= '1'; MemWrite <= '1'; ALUOp <= "001"; -- SW
            when "100" => ExtOp <= '1'; Branch <= '1'; ALUOp <= "010"; -- BEQ
            when "111" => Jump <= '1'; -- J
            when others => null;
        end case;
    end process;

    -- PIPELINED LOGIC CONNECTIONS 
    -- PCSrc now evaluates in the EX/MEM stage based on delayed signals!
    PCSrc <= EX_MEM_Branch and EX_MEM_Zero;
    
    -- Jump relies on the ID stage
    JumpAddress <= IF_ID_PC_plus_1(15 downto 13) & IF_ID_Instruction(12 downto 0);

    -- Write Back logic uses the final MEM/WB signals
    WD <= MEM_WB_MemData when MEM_WB_MemtoReg = '1' else MEM_WB_ALURes;


    -- COMPONENT INSTANTIATIONS
    -- IF gets BranchAddress from EX_MEM stage
    IF_inst: IF_Unit port map (clk, rst, en, EX_MEM_BranchAddress, JumpAddress, Jump, PCSrc, Instruction, PC_plus_1);
    
    -- ID gets Instr from IF_ID stage, and WD, WA, RegWrite from MEM_WB stage
    ID_inst: ID_Unit port map (clk, en, MEM_WB_RegWrite, IF_ID_Instruction, ExtOp, WD, MEM_WB_WriteAddress, RD1, RD2, Ext_Imm, func, sa);
    
    -- EX gets inputs from ID_EX stage
    EX_inst: EX_Unit port map (ID_EX_PC_plus_1, ID_EX_RD1, ID_EX_RD2, ID_EX_Ext_Imm, ID_EX_func, ID_EX_sa, ID_EX_ALUSrc, ID_EX_ALUOp, BranchAddress, ALURes, Zero);
    
    -- MEM gets inputs from EX_MEM stage
    MEM_inst: MEM_Unit port map (clk, en, EX_MEM_ALURes, EX_MEM_RD2, EX_MEM_MemWrite, MemData, ALURes_out);


    -- DISPLAY LOGIC 
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

    -- Displaying control signals on the LEDs
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