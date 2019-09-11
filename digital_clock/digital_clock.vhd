-----------------------------------------
--实体功能：利用六位数码管显示数字时钟（时分秒），小数点为间隔
--暂未添加其他功能
-----------------------------------------
entity digital_clock is
port(	clk_50Mhz:in bit;
		smg_sig:out bit_vector(5 downto 0);
		smg_data:out bit_vector(7 downto 0)
);
end digital_clock;

architecture tt of digital_clock is
--信号定义
signal clk_1khz:bit;
signal clk_1hz:bit;

signal second_smg_1:bit_vector(7 downto 0) := "00000011";
signal second_smg_2:bit_vector(7 downto 0) := "00000011";
signal minute_smg_1:bit_vector(7 downto 0) := "00000010";
signal minute_smg_2:bit_vector(7 downto 0) := "00000011";
signal hour_smg_1:bit_vector(7 downto 0) := "00000010";
signal hour_smg_2:bit_vector(7 downto 0) := "00000011";
signal second_sig_10:bit;
signal second_sig_6:bit;
signal minute_sig_10:bit;
signal minute_sig_6:bit;

--常量定义
--数码管位选
constant s0:bit_vector(5 downto 0):= "111110";			--末位（0）
constant s1:bit_vector(5 downto 0):= "111101";			--1位
constant s2:bit_vector(5 downto 0):= "111011";			--2位
constant s3:bit_vector(5 downto 0):= "110111";			--3位
constant s4:bit_vector(5 downto 0):= "101111";			--4位
constant s5:bit_vector(5 downto 0):= "011111";			--5位

--共阳数码管：A~G、DP	====>>	data[7]~data[0]
constant d0:bit_vector(7 downto 0):= "00000011";		--0
constant d1:bit_vector(7 downto 0):= "10011111";		--1
constant d2:bit_vector(7 downto 0):= "00100101";		--2
constant d3:bit_vector(7 downto 0):= "00001101";		--3
constant d4:bit_vector(7 downto 0):= "10011001";		--4
constant d5:bit_vector(7 downto 0):= "01001001";		--5
constant d6:bit_vector(7 downto 0):= "01000001";		--6
constant d7:bit_vector(7 downto 0):= "00011111";		--7
constant d8:bit_vector(7 downto 0):= "00000001";		--8
constant d9:bit_vector(7 downto 0):= "00001001";		--9
constant no:bit_vector(7 downto 0):= "11111111";		--空

--共阴数码管：A~G、DP	====>>	data[7]~data[0]
------------------------------------------------------------
--constant d0:bit_vector(7 downto 0):= "11111100";		--0
--constant d1:bit_vector(7 downto 0):= "01100000";		--1
--constant d2:bit_vector(7 downto 0):= "11011010";		--2
--constant d3:bit_vector(7 downto 0):= "11110010";		--3
--constant d4:bit_vector(7 downto 0):= "01100110";		--4
--constant d5:bit_vector(7 downto 0):= "10110110";		--5
--constant d6:bit_vector(7 downto 0):= "10111110";		--6
--constant d7:bit_vector(7 downto 0):= "11100000";		--7
--constant d8:bit_vector(7 downto 0):= "11111110";		--8
--constant d9:bit_vector(7 downto 0):= "11110110";		--9
--constant no:bit_vector(7 downto 0):= "00000000";		--空
------------------------------------------------------------

begin

--时钟分频：数码管扫描时钟1khz
--50Mhz时钟50000分频
process(clk_50Mhz)
variable cnt:integer range 0 to 25000;
begin
if(clk_50Mhz'event and clk_50Mhz = '1')then
	cnt := cnt + 1;
	if(cnt = 25000)then	
		cnt := 0;
		clk_1khz <= not clk_1khz;
	end if;
end if;
end process;

--时钟分频：数字钟走秒时钟1hz
--1khz时钟1000分频
process(clk_1khz)
variable cnt:integer range 0 to 500;
begin
if(clk_1khz'event and clk_1khz = '1')then
	cnt := cnt + 1;
	if(cnt = 500)then
		cnt := 0;
		clk_1hz <= not clk_1hz;
	end if;
end if;
end process;

--秒钟计时：个位
process(clk_1hz)
variable cnt:integer range 0 to 10;
begin
if(clk_1hz'event and clk_1hz = '1')then
	cnt := cnt + 1;
	if(cnt = 10)then
		cnt := 0;
		second_sig_10 <= '1';
	else
		second_sig_10 <= '0';
	end if;
	case cnt is
		when 0 => second_smg_1 <= d0;
		when 1 => second_smg_1 <= d1;
		when 2 => second_smg_1 <= d2;
		when 3 => second_smg_1 <= d3;
		when 4 => second_smg_1 <= d4;
		when 5 => second_smg_1 <= d5;
		when 6 => second_smg_1 <= d6;
		when 7 => second_smg_1 <= d7;
		when 8 => second_smg_1 <= d8;
		when 9 => second_smg_1 <= d9; 
		when others => null;
	end case;
end if;
end process;

--秒钟计时：十位
process(second_sig_10)
variable cnt:integer range 0 to 6;
begin
if(second_sig_10'event and second_sig_10 = '1')then
	cnt := cnt + 1;
	if(cnt = 6)then
		cnt := 0;
		second_sig_6 <= '1';
	else
		second_sig_6 <= '0';
	end if;
	case cnt is
		when 0 => second_smg_2 <= d0;
		when 1 => second_smg_2 <= d1;
		when 2 => second_smg_2 <= d2;
		when 3 => second_smg_2 <= d3;
		when 4 => second_smg_2 <= d4;
		when 5 => second_smg_2 <= d5; 
		when others => null;
	end case;
end if;
end process;

--分钟计时：个位
process(second_sig_6)
variable cnt:integer range 0 to 10;
begin
if(second_sig_6'event and second_sig_6 = '1')then
	cnt := cnt + 1;
	if(cnt = 10)then
		cnt := 0;
		minute_sig_10 <= '1';
	else
		minute_sig_10 <= '0';
	end if;
	case cnt is
		when 0 => minute_smg_1 <= d0 and "11111110";
		when 1 => minute_smg_1 <= d1 and "11111110";
		when 2 => minute_smg_1 <= d2 and "11111110";
		when 3 => minute_smg_1 <= d3 and "11111110";
		when 4 => minute_smg_1 <= d4 and "11111110";
		when 5 => minute_smg_1 <= d5 and "11111110";
		when 6 => minute_smg_1 <= d6 and "11111110";
		when 7 => minute_smg_1 <= d7 and "11111110";
		when 8 => minute_smg_1 <= d8 and "11111110";
		when 9 => minute_smg_1 <= d9 and "11111110"; 
		when others => null;
	end case;
end if;
end process;

--分钟计时：十位
process(minute_sig_10)
variable cnt:integer range 0 to 6;
begin
if(minute_sig_10'event and minute_sig_10 = '1')then
	cnt := cnt + 1;
	if(cnt = 6)then
		cnt := 0;
		minute_sig_6 <= '1';
	else 
		minute_sig_6 <= '0';
	end if;
	case cnt is
		when 0 => minute_smg_2 <= d0;
		when 1 => minute_smg_2 <= d1;
		when 2 => minute_smg_2 <= d2;
		when 3 => minute_smg_2 <= d3;
		when 4 => minute_smg_2 <= d4;
		when 5 => minute_smg_2 <= d5;
		when others => null;
	end case;
end if;
end process;

--小时计时
process(minute_sig_6)
variable cnt:integer range 0 to 24;
begin
if(minute_sig_6'event and minute_sig_6 = '1')then
	cnt := cnt + 1;
	if(cnt = 24)then
		cnt := 0;
	end if;
	case cnt is
		when 0 => hour_smg_2 <= d0;	hour_smg_1 <= d0 and "11111110";
		when 1 => hour_smg_2 <= d0;	hour_smg_1 <= d1 and "11111110";
		when 2 => hour_smg_2 <= d0;	hour_smg_1 <= d2 and "11111110";
		when 3 => hour_smg_2 <= d0;	hour_smg_1 <= d3 and "11111110";
		when 4 => hour_smg_2 <= d0;	hour_smg_1 <= d4 and "11111110";
		when 5 => hour_smg_2 <= d0;	hour_smg_1 <= d5 and "11111110";
		when 6 => hour_smg_2 <= d0;	hour_smg_1 <= d6 and "11111110";
		when 7 => hour_smg_2 <= d0;	hour_smg_1 <= d7 and "11111110";
		when 8 => hour_smg_2 <= d0;	hour_smg_1 <= d8 and "11111110";
		when 9 => hour_smg_2 <= d0;	hour_smg_1 <= d9 and "11111110";
		when 10 => hour_smg_2 <= d1;	hour_smg_1 <= d0 and "11111110";
		when 11 => hour_smg_2 <= d1;	hour_smg_1 <= d1 and "11111110";
		when 12 => hour_smg_2 <= d1;	hour_smg_1 <= d2 and "11111110";
		when 13 => hour_smg_2 <= d1;	hour_smg_1 <= d3 and "11111110";
		when 14 => hour_smg_2 <= d1;	hour_smg_1 <= d4 and "11111110";
		when 15 => hour_smg_2 <= d1;	hour_smg_1 <= d5 and "11111110";
		when 16 => hour_smg_2 <= d1;	hour_smg_1 <= d6 and "11111110";
		when 17 => hour_smg_2 <= d1;	hour_smg_1 <= d7 and "11111110";
		when 18 => hour_smg_2 <= d1;	hour_smg_1 <= d8 and "11111110";
		when 19 => hour_smg_2 <= d1;	hour_smg_1 <= d9 and "11111110";
		when 20 => hour_smg_2 <= d2;	hour_smg_1 <= d0 and "11111110";
		when 21 => hour_smg_2 <= d2;	hour_smg_1 <= d1 and "11111110";
		when 22 => hour_smg_2 <= d2;	hour_smg_1 <= d2 and "11111110";
		when 23 => hour_smg_2 <= d2;	hour_smg_1 <= d3 and "11111110";
		when others => null;
	end case;
end if;
end process;

--数字钟数码管显示
process(clk_1khz)
variable cnt:integer range 0 to 6;
begin
if(clk_1khz'event and clk_1khz = '1')then
	cnt := cnt + 1;
	if(cnt = 6)then
		cnt := 0;
	end if;
	case cnt is
		when 0 => smg_data <= second_smg_1;	smg_sig <= s0;
		when 1 => smg_data <= second_smg_2;	smg_sig <= s1;
		when 2 => smg_data <= minute_smg_1;	smg_sig <= s2;
		when 3 => smg_data <= minute_smg_2;	smg_sig <= s3;
		when 4 => smg_data <= hour_smg_1;	smg_sig <= s4;
		when 5 => smg_data <= hour_smg_2;	smg_sig <= s5;
		when others => null;
	end case;
end if;
end process;

end tt;

