library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity control is
	port
	(
		clk, rst		:	in		std_logic;
		rom_code		:	in		std_logic_vector(15 downto 0);
		rom_cs, rd	:	out	std_logic;
		addr			:	out	std_logic_vector(7 downto 0);
		portin		:	in		std_logic_vector(15 downto 0);
		portout		:	out	std_logic_vector(15 downto 0);
		codeout		:	out	std_logic_vector(15 downto 0)
	);
end control;

architecture tt of control is
type states is (s27, s26, s25, s24, s23, s22, s21, s20, s19, 
					s18, s17, s16, s15, s14, s13, s12, s11, s10, 
					s9, s8, s7, s6, s5, s4, s3, s2, s1, s0);
signal state:states := s0;

signal pc:std_logic_vector(7 downto 0);
signal arin, brin:std_logic_vector(15 downto 0);
signal rom_reg:std_logic_vector(15 downto 0);
signal con_sel:std_logic_vector(2 downto 0);
signal func_sel:std_logic_vector(3 downto 0);
signal ar32, br32:std_logic_vector(31 downto 0);
signal data_acc:std_logic_vector(31 downto 0);
signal hacc:std_logic_vector(15 downto 0);

begin

	con_sel <= rom_reg(15 downto 13);	--指令类别：运算、传输等
	func_sel <= rom_reg(11 downto 8);	--指令
	ar32 <= x"0000" & arin;
	br32 <= x"0000" & brin;
	
	process(clk, rst)
	begin
		if(rst = '1')then		--复位
			state <= s0;
			pc <= "00000000";
			rd <= '0';
			rom_cs <= '0';
			arin <= x"0000";
			brin <= x"0000";
		elsif(clk'event and clk = '1')then
			case state is
				when s0 =>	rom_cs <= '1';
								addr <= pc;
								if(pc >= "10000000")then
									state <= s0;
								else
									state <= s1;
								end if;
				when s1 =>	state <= s2;
								rd <= '1';
				when s2 =>	state <= s3;				--s0、s1、s2完成取指
								rom_reg <= rom_code;
								codeout <= rom_code;			
				when s3 =>	state <= s4;				--译码，按指令类别跳转对应状态
								rom_cs <= '0';
								rd <= '0';
								if(con_sel = "000")then
									state <= s4;
								elsif(con_sel = "001")then
									state <= s8;
								elsif(con_sel = "011")then
									state <= s21;
								else
									state <= s24;
								end if;
								
				when s4 =>	state <= s5;				--算术、逻辑运算
								if(func_sel = "0001")then
									data_acc <= ar32 + br32;
								elsif(func_sel = "0011")then
									data_acc <= arin * brin;
								elsif(func_sel = "0101")then
									data_acc <= ar32 and br32;
								elsif(func_sel = "1000")then
									data_acc <= ar32(30 downto 0) & '0';
								else null;
								end if;
				when s5 =>	state <= s6;
				when s6 => 	state <= s7;
				when s7 =>	state <= s0;
								arin <= data_acc(15 downto 0);		--累加器A结果回送
								hacc <= data_acc(31 downto 16);
								pc <= pc + 1;				--下一条指令
				
				when s8 =>	state <= s9;				--数据传输类指令
								if(func_sel = "0101")then
									arin <= "00000000" & rom_reg(7 downto 0);
								elsif(func_sel = "1101")then
									brin <= "00000000" & rom_reg(7 downto 0);
								else null;
								end if;
				when s9 =>	state <= s24;
				-------------------------
				------其他指令------------
				-------------------------
				when s21 =>	state <= s22;				--IO类指令
								if(func_sel = "0000")then
									arin <= portin;		--输入
								elsif(func_sel = "0001")then
									portout <= arin;		--输出
								else null;
								end if;
				when s22 =>	state <= s23;
				when s23 =>	state <= s0;
								pc <= pc + 1;				--下一条指令
				-------------------------
				------其他指令------------
				-------------------------				
				when s24 =>	state <= s25;				
				when s25 =>	state <= s26;
				when s26 =>	state <= s27;
				when s27 =>	state <= s0;
								pc <= pc + 1;				--下一条指令
								
				when others => state <= s0;
			end case;
		end if;
	end process;

end tt;
