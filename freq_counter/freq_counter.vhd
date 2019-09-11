----------------------------------------------
--实体功能：数字频率计，实现1~999999Hz的测频，利用六位数码管显示
--显示更新速度约为1s
----------------------------------------------
entity freq_counter is
port(	clk_50Mhz:in bit;
		clk_out:buffer bit;
		clk_in:in bit;
		smg_data:out bit_vector(7 downto 0);
		smg_sig:out bit_vector(5 downto 0)
);
end freq_counter;

architecture tt of freq_counter is
--信号定义
signal clk_1khz:bit;			--数码管扫描时钟
signal clk_10hz:bit;			--用于设置门限时间1s，10个周期为1s
									--第10个时钟将计数值发送到数码管显示，第11个时钟将计数值清零，再下一个时钟重新开始计数
signal clk_in_buf:bit;
signal clk_in_rise:bit;		--检测到输入信号上升沿
signal clear:bit;				--记完1s后，将计数值清零

--频率数值显示：单位Hz、范围1~999999Hz
signal f0:bit_vector(7 downto 0);							--个位数码管
signal f1:bit_vector(7 downto 0);							--十位数码管
signal f2:bit_vector(7 downto 0);							--百位数码管
signal f3:bit_vector(7 downto 0);							--千位数码管
signal f4:bit_vector(7 downto 0);							--万位数码管
signal f5:bit_vector(7 downto 0);							--十万位数码管

signal f0_count:integer range 0 to 10;						--个位计数值
signal f1_count:integer range 0 to 10;						--十位计数值
signal f2_count:integer range 0 to 10;						--百位计数值
signal f3_count:integer range 0 to 10;						--千位计数值
signal f4_count:integer range 0 to 10;						--万位计数值
signal f5_count:integer range 0 to 10;						--十万位计数值

signal f0_sig:bit;												--个位进位
signal f1_sig:bit;												--十位进位
signal f2_sig:bit;												--百位进位
signal f3_sig:bit;												--千位进位
signal f4_sig:bit;												--万位进位
signal f5_sig:bit;												--十万位进位：溢出标志

signal f0_sig_buf:bit;
signal f1_sig_buf:bit;
signal f2_sig_buf:bit;
signal f3_sig_buf:bit;
signal f4_sig_buf:bit;
signal f5_sig_buf:bit;

signal f0_sig_rise:bit;											--检测到个位进位上升沿
signal f1_sig_rise:bit;											--检测到十位进位上升沿
signal f2_sig_rise:bit;											--检测到百位进位上升沿
signal f3_sig_rise:bit;											--检测到千位进位上升沿
signal f4_sig_rise:bit;											--检测到万位进位上升沿
signal f5_sig_rise:bit;											--检测到十万位进位上升沿

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
		clk_out <= not clk_out;
	end if;
end if;
end process;

--时钟分频：10Hz
--1khz时钟100分频
process(clk_1khz)
variable cnt:integer range 0 to 50;
begin
if(clk_1khz'event and clk_1khz = '1')then
	cnt := cnt + 1;
	if(cnt = 50)then
		cnt := 0;
		clk_10hz <= not clk_10hz;
	end if;
end if;
end process;

--检测输入信号上升沿
process(clk_50Mhz)
begin
if(clk_50Mhz'event and clk_50Mhz = '1')then
	clk_in_buf <= clk_in;
	clk_in_rise <= (not clk_in_buf) and clk_in;
end if;
end process;

--检测进位上升沿
--检测个位进位
process(clk_50Mhz)
begin
if(clk_50Mhz'event and clk_50Mhz = '1')then
	f0_sig_buf <= f0_sig;
	f0_sig_rise <= (not f0_sig_buf) and f0_sig;
end if;
end process;

--检测十位进位
process(clk_50Mhz)
begin
if(clk_50Mhz'event and clk_50Mhz = '1')then
	f1_sig_buf <= f1_sig;
	f1_sig_rise <= (not f1_sig_buf) and f1_sig;
end if;
end process;

--检测百位进位
process(clk_50Mhz)
begin
if(clk_50Mhz'event and clk_50Mhz = '1')then
	f2_sig_buf <= f2_sig;
	f2_sig_rise <= (not f2_sig_buf) and f2_sig;
end if;
end process;

--检测千位进位
process(clk_50Mhz)
begin
if(clk_50Mhz'event and clk_50Mhz = '1')then
	f3_sig_buf <= f3_sig;
	f3_sig_rise <= (not f3_sig_buf) and f3_sig;
end if;
end process;

--检测万位进位
process(clk_50Mhz)
begin
if(clk_50Mhz'event and clk_50Mhz = '1')then
	f4_sig_buf <= f4_sig;
	f4_sig_rise <= (not f4_sig_buf) and f4_sig;
end if;
end process;

--检测十万位进位
process(clk_50Mhz)
begin
if(clk_50Mhz'event and clk_50Mhz = '1')then
	f5_sig_buf <= f5_sig;
	f5_sig_rise <= (not f5_sig_buf) and f5_sig;
end if;
end process;

--测频法：gate为1s
--个位计数
process(clk_50Mhz)
begin
if(clk_50Mhz'event and clk_50Mhz = '1')then
	if(clear = '1')then			--计数值清零
		f0_count <= 0;
	elsif(clk_in_rise = '1')then
		if(f0_count = 9)then
			f0_count <= 0;
			f0_sig <= '1';
		else
			f0_count <= f0_count + 1;
			f0_sig <= '0';
		end if;
	end if;
end if;
end process;

--十位计数
process(clk_50Mhz)
begin
if(clk_50Mhz'event and clk_50Mhz = '1')then
	if(clear = '1')then			--计数值清零
		f1_count <= 0;
	elsif(f0_sig_rise = '1')then
		if(f1_count = 9)then
			f1_count <= 0;
			f1_sig <= '1';
		else
			f1_count <= f1_count + 1;
			f1_sig <= '0';
		end if;
	end if;
end if;
end process;

--百位计数
process(clk_50Mhz)
begin
if(clk_50Mhz'event and clk_50Mhz = '1')then
	if(clear = '1')then			--计数值清零
		f2_count <= 0;
	elsif(f1_sig_rise = '1')then
		if(f2_count = 9)then
			f2_count <= 0;
			f2_sig <= '1';
		else
			f2_count <= f2_count + 1;
			f2_sig <= '0';
		end if;
	end if;
end if;
end process;

--千位计数
process(clk_50Mhz)
begin
if(clk_50Mhz'event and clk_50Mhz = '1')then
	if(clear = '1')then			--计数值清零
		f3_count <= 0;
	elsif(f2_sig_rise = '1')then
		if(f3_count = 9)then
			f3_count <= 0;
			f3_sig <= '1';
		else
			f3_count <= f3_count + 1;
			f3_sig <= '0';
		end if;
	end if;
end if;
end process;

--万位计数
process(clk_50Mhz)
begin
if(clk_50Mhz'event and clk_50Mhz = '1')then
	if(clear = '1')then			--计数值清零
		f4_count <= 0;
	elsif(f3_sig_rise = '1')then
		if(f4_count = 9)then
			f4_count <= 0;
			f4_sig <= '1';
		else
			f4_count <= f4_count + 1;
			f4_sig <= '0';
		end if;
	end if;
end if;
end process;

--十万位计数
process(clk_50Mhz)
begin
if(clk_50Mhz'event and clk_50Mhz = '1')then
	if(clear = '1')then			--计数值清零
		f5_count <= 0;
	elsif(f4_sig_rise = '1')then
		if(f5_count = 9)then
			f5_count <= 0;
			f5_sig <= '1';
		else
			f5_count <= f5_count + 1;
			f5_sig <= '0';
		end if;
	end if;
end if;
end process;
 
process(clk_10hz)
variable cnt:integer range 0 to 12;
begin
if(clk_10hz'event and clk_10hz = '1')then
	cnt := cnt + 1;
	if(cnt = 1)then
		clear <= '0';
	end if;
	if(cnt = 11)then
		case f0_count is
			when 0 => f0 <= d0;
			when 1 => f0 <= d1;
			when 2 => f0 <= d2;
			when 3 => f0 <= d3;
			when 4 => f0 <= d4;
			when 5 => f0 <= d5;
			when 6 => f0 <= d6;
			when 7 => f0 <= d7;
			when 8 => f0 <= d8;
			when 9 => f0 <= d9;
			when others => null;
		end case;
		
		case f1_count is
			when 0 => f1 <= d0;
			when 1 => f1 <= d1;
			when 2 => f1 <= d2;
			when 3 => f1 <= d3;
			when 4 => f1 <= d4;
			when 5 => f1 <= d5;
			when 6 => f1 <= d6;
			when 7 => f1 <= d7;
			when 8 => f1 <= d8;
			when 9 => f1 <= d9;
			when others => null;
		end case;
		
		case f2_count is
			when 0 => f2 <= d0;
			when 1 => f2 <= d1;
			when 2 => f2 <= d2;
			when 3 => f2 <= d3;
			when 4 => f2 <= d4;
			when 5 => f2 <= d5;
			when 6 => f2 <= d6;
			when 7 => f2 <= d7;
			when 8 => f2 <= d8;
			when 9 => f2 <= d9;
			when others => null;
		end case;
		
		case f3_count is
			when 0 => f3 <= d0;
			when 1 => f3 <= d1;
			when 2 => f3 <= d2;
			when 3 => f3 <= d3;
			when 4 => f3 <= d4;
			when 5 => f3 <= d5;
			when 6 => f3 <= d6;
			when 7 => f3 <= d7;
			when 8 => f3 <= d8;
			when 9 => f3 <= d9;
			when others => null;
		end case;
		
		case f4_count is
			when 0 => f4 <= d0;
			when 1 => f4 <= d1;
			when 2 => f4 <= d2;
			when 3 => f4 <= d3;
			when 4 => f4 <= d4;
			when 5 => f4 <= d5;
			when 6 => f4 <= d6;
			when 7 => f4 <= d7;
			when 8 => f4 <= d8;
			when 9 => f4 <= d9;
			when others => null;
		end case;
		
		case f5_count is
			when 0 => f5 <= d0;
			when 1 => f5 <= d1;
			when 2 => f5 <= d2;
			when 3 => f5 <= d3;
			when 4 => f5 <= d4;
			when 5 => f5 <= d5;
			when 6 => f5 <= d6;
			when 7 => f5 <= d7;
			when 8 => f5 <= d8;
			when 9 => f5 <= d9;
			when others => null;
		end case;
	end if;
	if(cnt = 12)then
		cnt := 0;
		clear <= '1';
	end if;
end if;
end process;

--数值显示程序
process(clk_1khz)
variable cnt:integer range 0 to 6;
begin
if(clk_1khz'event and clk_1khz = '1')then
	cnt := cnt + 1;
	if(cnt = 6)then
		cnt := 0;
	end if;
	case cnt is
		when 0 => smg_data <= f0;	smg_sig <= s0;
		when 1 => smg_data <= f1;	smg_sig <= s1;
		when 2 => smg_data <= f2;	smg_sig <= s2;
		when 3 => smg_data <= f3;	smg_sig <= s3;
		when 4 => smg_data <= f4;	smg_sig <= s4;
		when 5 => smg_data <= f5;	smg_sig <= s5;
		when others => null;
	end case;
end if;
end process;
	
end tt;

