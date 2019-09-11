library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity divider is												
port(	divident:in std_logic_vector(15 downto 0);	--被除数
		dividor:in std_logic_vector(7 downto 0);		--除数
		result:out std_logic_vector(15 downto 0);		--商的整数部分
		frac:out std_logic_vector(7 downto 0);			--小数部分
		carrybit:out std_logic								--溢出位
);
end divider;

architecture tt of divider is
begin
process(divident, dividor)
variable cnt:integer range 0 to 16;
variable dt, dr, dt_1, dr_1, dr_2, rt, fc_dt, fc:std_logic_vector(15 downto 0);
variable rl:std_logic_vector(7 downto 0);		--余数

begin
dt := divident;							--被除数
dr := "00000000" & dividor;			--除数
dt_1 := dt;
dr_1 := dr;
dr_2 := dr;
cnt := 0;

if(dr = x"0000")then			--除数为0，溢出
	rt := x"ffff";
	rl := x"ff";
	fc_dt := x"ffff";
	fc := x"ffff";
	carrybit <= '1';
else
	carrybit <= '0';
	if(dt < dr)then 			--被除数小于除数
		rt := x"0000";
		rl := dt(7 downto 0);
	else
		if(dt = x"0000")then	--被除数为0
			rt := x"0000";
			rl := x"00";
		else
			for i in 15 downto 0 loop		--将除数右移至最高位不为0
				if(dr_1(15) = '0')then
					for j in 15 downto 1 loop
						dr_1(j) := dr_1(j-1);
					end loop;
					dr_1(0) := '0';
					cnt := cnt + 1;
				end if;
			end loop;
			dr_2 := dr_1;						--取出移位后的除数，之后用于求小数部分
			for i in 15 downto 0 loop
				if(i > cnt)then
					rt(i) := '0';
				elsif(dt_1 < dr_1)then
					for j in 0 to 14 loop
						dr_1(j) := dr_1(j+1);
					end loop;
					dr_1(15) := '0';
					rt(i) := '0';
				else
					dt_1 := dt_1 - dr_1;
					rt(i) := '1';
					for j in 0 to 14 loop
						dr_1(j) := dr_1(j+1);
					end loop;
					dr_1(15) := '0';
				end if;
			end loop;
			rl := dt_1(7 downto 0);
		end if;
	end if;
	
	fc_dt := rl * x"64";		--余数乘以100，再作为被除数，求小数部分
	if(fc_dt = x"0000")then	--余数为0
		fc := x"0000";
	else
		if(fc_dt < dr)then	
			fc := x"0000";
		else
			for i in 15 downto 0 loop
				if(i > cnt)then
					fc(i) := '0';
				elsif(fc_dt < dr_2)then
					fc(i) := '0';
					for j in 0 to 14 loop
						dr_2(j) := dr_2(j+1);
					end loop;
					dr_2(15) := '0';
				else
					fc_dt := fc_dt - dr_2;
					for j in 0 to 14 loop
						dr_2(j) := dr_2(j+1);
					end loop;
					dr_2(15) := '0';
					fc(i) := '1';
				end if;
			end loop;
		end if;
	end if;		
end if;

result <= rt;
frac <= fc(7 downto 0);

end process;
end tt;
