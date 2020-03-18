library ieee;
use ieee.std_logic_1164.all;

entity servo is
	port
	(
		clk_50M		:	in		std_logic;
		rst_n			:	in		std_logic;
		servo_out	:	out	std_logic
	);
end servo;

architecture tt of servo is

signal clk_2khz	:	std_logic;
signal pulse_1ms	:	std_logic;
signal pulse_2ms	:	std_logic;

begin

--分频：得到2khz
process(clk_50M)
variable cnt1	:	integer range 0 to 12500;
begin
if(rst_n = '0')then
	clk_2khz <= '0';
	cnt1 := 0;
elsif(clk_50M'event and clk_50M = '1')then
	if(cnt1 = 12499)then
		cnt1 := 0;
		clk_2khz <= not clk_2khz;
	else
		cnt1 := cnt1 + 1;
	end if;
end if;
end process;

--产生周期20ms，1ms正脉冲波
process(clk_2khz)
variable cnt2	:	integer range 0 to 40;
begin
if(rst_n = '0')then
	pulse_1ms <= '0';
	cnt2 := 0;
elsif(clk_2khz'event and clk_2khz = '1')then
	if(cnt2 = 1)then
		cnt2 := cnt2 + 1;
		pulse_1ms <= '0';
	elsif(cnt2 = 39)then
		cnt2 := 0;
		pulse_1ms <= '1';
	else
		cnt2 := cnt2 + 1;
	end if;
end if;
end process;

--产生周期20ms，2ms正脉冲波
process(clk_2khz)
variable cnt3	:	integer range 0 to 40;
begin
if(rst_n = '0')then
	pulse_2ms <= '0';
	cnt3 := 0;
elsif(clk_2khz'event and clk_2khz = '1')then
	if(cnt3 = 3)then
		cnt3 := cnt3 + 1;
		pulse_2ms <= '0';
	elsif(cnt3 = 39)then
		cnt3 := 0;
		pulse_2ms <= '1';
	else
		cnt3 := cnt3 + 1;
	end if;
end if;
end process;

--脉冲选择输出
process(clk_2khz)
variable cnt4	:	integer range 0 to 4000;
begin
if(rst_n = '0')then
	servo_out <= '0';
	cnt4 := 0;
elsif(clk_2khz'event and clk_2khz = '1')then
	if(cnt4 = 1999)then
		cnt4 := cnt4 + 1;
		servo_out <= pulse_2ms;
	elsif(cnt4 = 3999)then
		cnt4 := 0;
		servo_out <= pulse_1ms;
	else
		cnt4 := cnt4 + 1;
	end if;
end if;
end process;

end tt;
