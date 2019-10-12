library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity ALU is
port(	func_sel:in std_logic_vector(3 downto 0);
		ar:in std_logic_vector(15 downto 0);
		br:in std_logic_vector(15 downto 0);
		data_acc:out std_logic_vector(31 downto 0);
		carry:out std_logic
);
end ALU;

architecture tt of ALU is
--信号定义
signal ar32, br32:std_logic_vector(31 downto 0);
signal result:std_logic_vector(31 downto 0);
signal r:std_logic_vector(31 downto 0);

begin
ar32 <= x"0000" & ar;
br32 <= x"0000" & br;
data_acc <= result;

with func_sel select
	result <= 	ar32 + br32					when "0001",
					r								when "0010",
					ar * br						when "0011",
					ar32 and br32 				when "0100",
					ar32 or br32				when "0101",
					x"0000" & (not ar)		when "0110",
					ar32(30 downto 0) & '0' when "0111",
					'0' & ar32(31 downto 1)	when "1000",
					x"00000000" 				when others;

process(func_sel, ar32, br32)
begin
if(func_sel = "0010")then
	if(ar32 < br32)then
		r <= x"0001" & (br - ar);
	else
		r <= ar32 - br32;
	end if;
	carry <= result(16);
elsif(func_sel = "0001")then
	carry <= result(16);
else
	carry <= '0';
end if;

end process;

end tt;

