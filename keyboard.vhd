--所用矩阵键盘原理示意图
--			c1		c2		c3		c4
--	r1		1		2		3		A
--	r2		4		5		6		B
--	r3		7		8		9		C
--	r4		*		0		#		D
--接口顺序：c1 c2 c3 c4 r1 r2 r3 r4（正向：从左到右）

--FPGA引脚col需配置弱上拉

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity keyboard is
port(	clk_50Mhz:in std_logic;
		col:in std_logic_vector(3 downto 0);
		row:out std_logic_vector(3 downto 0);
		smg_data:out std_logic_vector(7 downto 0);
		smg_sig:out std_logic_vector(5 downto 0)
);
end keyboard;

architecture tt of keyboard is
--信号定义
signal row_state:std_logic_vector(3 downto 0);
signal state:std_logic_vector(7 downto 0);
signal clk_1khz:std_logic;
signal keyout:integer range 0 to 20;

--常量定义
--数码管位选
constant s0:std_logic_vector(5 downto 0):= "111110";			--末位（0）
constant s1:std_logic_vector(5 downto 0):= "111101";			--1位
constant s2:std_logic_vector(5 downto 0):= "111011";			--2位
constant s3:std_logic_vector(5 downto 0):= "110111";			--3位
constant s4:std_logic_vector(5 downto 0):= "101111";			--4位
constant s5:std_logic_vector(5 downto 0):= "011111";			--5位

--共阳数码管：A~G、DP	====>>	data[7]~data[0]
constant d0:std_logic_vector(7 downto 0):= "00000011";		--0
constant d1:std_logic_vector(7 downto 0):= "10011111";		--1
constant d2:std_logic_vector(7 downto 0):= "00100101";		--2
constant d3:std_logic_vector(7 downto 0):= "00001101";		--3
constant d4:std_logic_vector(7 downto 0):= "10011001";		--4
constant d5:std_logic_vector(7 downto 0):= "01001001";		--5
constant d6:std_logic_vector(7 downto 0):= "01000001";		--6
constant d7:std_logic_vector(7 downto 0):= "00011111";		--7
constant d8:std_logic_vector(7 downto 0):= "00000001";		--8
constant d9:std_logic_vector(7 downto 0):= "00001001";		--9
constant no:std_logic_vector(7 downto 0):= "11111111";		--空

begin

--时钟分频：时钟1khz
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

--产生行扫描信号
process(clk_1khz)
begin
if(clk_1khz'event and clk_1khz = '1')then
	case row_state is
		when "1110" => row_state <= "1101";
		when "1101" => row_state <= "1011";
		when "1011" => row_state <= "0111";
		when "0111" => row_state <= "1110";
		when others => row_state <= "1110";
	end case;
end if;
end process;

--对行扫描信号和列扫描信号进行整合
row <= row_state;
state <= row_state & col;

--扫描得出按键编号
process(clk_1khz)
begin
if(clk_1khz'event and clk_1khz = '1')then
	case state is
		when "11101110" => keyout <= 1;
		when "11101101" => keyout <= 2;
		when "11101011" => keyout <= 3;
		when "11100111" => keyout <= 4;
		when "11011110" => keyout <= 5;
		when "11011101" => keyout <= 6;
		when "11011011" => keyout <= 7;
		when "11010111" => keyout <= 8;
		when "10111110" => keyout <= 9;
		when "10111101" => keyout <= 10;
		when "10111011" => keyout <= 11;
		when "10110111" => keyout <= 12;
		when "01111110" => keyout <= 13;
		when "01111101" => keyout <= 14;
		when "01111011" => keyout <= 15;
		when "01110111" => keyout <= 16;
		when "11101111" => keyout <= 0;
		when "11011111" => keyout <= 0;
		when "10111111" => keyout <= 0;
		when "01111111" => keyout <= 0;
		when others => null;
	end case;
end if;
end process;

--数码管显示键值
smg_sig <= s0; 
process(clk_1khz)
begin
if(clk_1khz'event and clk_1khz = '1')then
	case keyout is
		when 1 => smg_data <= d1;
		when 2 => smg_data <= d2;
		when 3 => smg_data <= d3;
		when 4 => smg_data <= no;
		when 5 => smg_data <= d4;
		when 6 => smg_data <= d5;
		when 7 => smg_data <= d6;
		when 8 => smg_data <= no;
		when 9 => smg_data <= d7;
		when 10 => smg_data <= d8;
		when 11 => smg_data <= d9;
		when 12 => smg_data <= no;
		when 13 => smg_data <= no;
		when 14 => smg_data <= d0;
		when 15 => smg_data <= no;
		when 16 => smg_data <= no;
		when others => null;
	end case;
end if;
end process;

end tt;
