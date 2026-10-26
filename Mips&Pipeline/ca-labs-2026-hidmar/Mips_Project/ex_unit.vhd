library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity EX_Unit is
    Port ( PC_plus_1 : in STD_LOGIC_VECTOR(15 downto 0);
           RD1 : in STD_LOGIC_VECTOR(15 downto 0);
           RD2 : in STD_LOGIC_VECTOR(15 downto 0);
           Ext_Imm : in STD_LOGIC_VECTOR(15 downto 0);
           func : in STD_LOGIC_VECTOR(2 downto 0);
           sa : in STD_LOGIC;
           ALUSrc : in STD_LOGIC;
           ALUOp : in STD_LOGIC_VECTOR(2 downto 0);
           BranchAddress : out STD_LOGIC_VECTOR(15 downto 0);
           ALURes : out STD_LOGIC_VECTOR(15 downto 0);
           Zero : out STD_LOGIC);
end EX_Unit;

architecture Behavioral of EX_Unit is
    signal ALU_In2 : std_logic_vector(15 downto 0);
    signal ALUCtrl : std_logic_vector(2 downto 0);
    signal ALURes_internal : std_logic_vector(15 downto 0);
begin
    -- Branch Address Computation (No shift left 2 because it's word addressable)
    BranchAddress <= PC_plus_1 + Ext_Imm;

    -- ALUSrc MUX
    ALU_In2 <= Ext_Imm when ALUSrc = '1' else RD2;

    -- ALU Control
    process(ALUOp, func)
    begin
        case ALUOp is
            when "000" => -- R-Type
                case func is
                    when "000" => ALUCtrl <= "000"; -- ADD
                    when "001" => ALUCtrl <= "001"; -- SUB
                    when "010" => ALUCtrl <= "010"; -- SLL
                    when "011" => ALUCtrl <= "011"; -- SRL
                    when "100" => ALUCtrl <= "100"; -- AND
                    when "101" => ALUCtrl <= "101"; -- OR
                    when "110" => ALUCtrl <= "110"; -- XOR
                    when others => ALUCtrl <= "111"; -- SLT
                end case;
            when "001" => ALUCtrl <= "000"; -- ADDI, LW, SW (ADD)
            when "010" => ALUCtrl <= "001"; -- BEQ, BNE (SUB)
            when others => ALUCtrl <= "000"; -- Default
        end case;
    end process;

    -- Main ALU
    process(ALUCtrl, RD1, ALU_In2, sa)
    begin
        case ALUCtrl is
            when "000" => ALURes_internal <= RD1 + ALU_In2; -- ADD
            when "001" => ALURes_internal <= RD1 - ALU_In2; -- SUB
            when "010" => -- SLL
                if sa = '1' then ALURes_internal <= ALU_In2(14 downto 0) & '0';
                else ALURes_internal <= ALU_In2; end if;
            when "011" => -- SRL
                if sa = '1' then ALURes_internal <= '0' & ALU_In2(15 downto 1);
                else ALURes_internal <= ALU_In2; end if;
            when "100" => ALURes_internal <= RD1 and ALU_In2; -- AND
            when "101" => ALURes_internal <= RD1 or ALU_In2;  -- OR
            when "110" => ALURes_internal <= RD1 xor ALU_In2; -- XOR
            when others => -- SLT
                if RD1 < ALU_In2 then ALURes_internal <= x"0001";
                else ALURes_internal <= x"0000"; end if;
        end case;
    end process;

    ALURes <= ALURes_internal;
    Zero <= '1' when ALURes_internal = x"0000" else '0';

end Behavioral;