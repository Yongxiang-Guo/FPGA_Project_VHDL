--------------------------------------------
--VGA传输实体
--显示原理：逐行扫描，扫描完一行则列加一，直至完成一帧（一屏），一般1S有60或75帧（即刷新速率60Hz和75Hz）
--VGA传输协议时序：（行、列）同步脉冲+显示后沿+显示数据+显示前沿（一整个周期）
					--	其中同步脉冲+显示后沿+显示前沿是消隐区，RGB信号无效，屏幕不显示数据；
					--	显示数据段是有效数据区，行、列时钟周期和像素点一致（例如1024*768，即行数据1024个时钟，列数据768个（行））
					--	不同的像素需要不同的时钟，以及不同的各时段分配
--------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity VGA is
	port
	(	
		clk_50Mhz:	in 	std_logic;
		rdata		:	out 	std_logic_vector(4 downto 0);		--R
		gdata		:	out 	std_logic_vector(5 downto 0);		--G
		bdata		:	out 	std_logic_vector(4 downto 0);		--B
		hsync		:	out 	std_logic;								--行同步
		vsync		:	out 	std_logic								--场同步
	);
end VGA;

architecture tt of VGA is
component pll is				--pll实例，输出65MHz时钟
	port
	(
		inclk0	: in 	std_logic;
		c0			: out std_logic 
	);
end component pll;

--信号定义
signal clk_VGA:std_logic;				--65MHz
signal clk_1khz:std_logic;
signal clk_1hz:std_logic;
signal rgb_data:std_logic_vector(15 downto 0);
signal rgb_reg:std_logic_vector(15 downto 0);
signal hcnt:integer:=1;					--行计数器
signal vcnt:integer:=1;					--列计数器
signal henable, venable:std_logic:= '0';	--行、列显示使能信号

--常量定义
-----------------------------------------------------------
--水平扫描参数的设定1024*768 60Hz VGA	clk=65M
-----------------------------------------------------------
constant h_sync:integer :=136;			--同步脉冲
constant h_back:integer :=160;			--显示后沿
constant h_data:integer :=1024;			--显示数据
constant h_front:integer :=24;			--显示前沿
constant h_period:integer := 1344;		--h_sync + h_back + h_data + h_front
constant h_start:integer := 296;			--h_sync + h_back		开始显示
constant h_end:integer := 1320;			--h_sync + h_back + h_data		结束显示
-----------------------------------------------------------
--垂直扫描参数的设定1024*768 60Hz VGA	clk=65M
--需要注意的是：列扫描的时钟是以一行为一个时钟周期，扫描完一行列时钟计数值加一
-----------------------------------------------------------
constant v_sync:integer :=6;				--同步脉冲
constant v_back:integer :=29;          --显示后沿
constant v_data:integer :=768;         --显示数据
constant v_front:integer :=3;          --显示前沿
constant v_period:integer := 806;		--v_sync + v_back + v_data + v_front
constant v_start:integer := 35;			--v_sync + v_back		开始显示
constant v_end:integer := 803;			--v_sync + v_back + v_data		结束显示

-----------------------------------------------------------
--水平扫描参数的设定800*600 60Hz VGA	clk=40M
-----------------------------------------------------------
--constant h_data:integer :=800;
--constant h_front:integer :=40;
--constant h_back:integer :=88;
--constant h_sync:integer :=128;
--constant h_period:integer := h_data + h_front + h_back + h_sync;		--1056
-----------------------------------------------------------
--垂直扫描参数的设定800*600 60Hz VGA	clk=40M
-----------------------------------------------------------
--constant v_data:integer :=600;
--constant v_front:integer :=1;
--constant v_back:integer :=23;
--constant v_sync:integer :=4;
--constant v_period:integer := v_data + v_front + v_back + v_sync;		--628

begin

pll_inst : pll PORT MAP (
		inclk0	 => clk_50Mhz,
		c0	 => clk_VGA
	);
	
--分频进程：1khz
--50MHz时钟，50000分频
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

--分频进程：1hz
--1khz时钟，1000分频
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

--行计数器进程，计数周期为h_period
process(clk_VGA)
begin
if(clk_VGA'event and clk_VGA = '1')then
	if(hcnt = h_period)then		--一个周期结束
		hcnt <= 1;					--计数值范围1~h_period
	else
		hcnt <= hcnt + 1;
	end if;
end if;
end process;

--产生行同步信号
process(clk_VGA)
begin
if(clk_VGA'event and clk_VGA = '1')then
	if(hcnt = h_period)then		--一个周期结束，产生行同步脉冲
		hsync <= '0';
	elsif(hcnt = h_sync)then	--从1到h_sync，刚好h_sync个时钟周期
		hsync <= '1';
	end if;
end if;
end process;

--列计数器进程，计数周期为v_period
process(clk_VGA)
begin
if(clk_VGA'event and clk_VGA = '1')then
	if(hcnt = h_period)then			--一行代表一个时钟周期
		if(vcnt = v_period)then		--一个周期结束
			vcnt <= 1;              --计数值范围1~v_period
		else
			vcnt <= vcnt + 1;
		end if;
	end if;
end if;
end process;

--产生列同步信号
process(clk_VGA)
begin
if(clk_VGA'event and clk_VGA = '1')then
	if(vcnt = v_period)then			--一帧结束，产生列同步脉冲
		vsync <= '0';              
	elsif(vcnt = v_sync)then      --从1到v_sync，刚好v_sync个周期
		vsync <= '1';
	end if;
end if;
end process;

--在行消隐时，RGB的数据无效
process(clk_VGA)
begin
if(clk_VGA'event and clk_VGA = '1')then
	if(hcnt = h_start)then
		henable <= '1';		--在数据显示区，数据显示使能
	elsif(hcnt = h_end)then
		henable <= '0';		--在数据消隐区，数据显示失能
	end if;
end if;
end process;

--在列消隐时，RGB的数据无效
process(clk_VGA)
begin
if(clk_VGA'event and clk_VGA = '1')then
	if(vcnt = v_start)then
		venable <= '1';		--在数据显示区，数据显示使能
	elsif(vcnt = v_end)then 
		venable <= '0';		--在数据消隐区，数据显示失能
	end if;
end if;
end process;

--填涂颜色
process(clk_1hz)
begin
if(clk_1hz'event and clk_1hz = '1')then		--每秒RGB值固定递增变化
	rgb_data <= rgb_data + x"2084";
end if;
end process;

rgb_reg <= 	rgb_data when (henable and venable) = '1' else	--只在数据显示区显示RGB数据，其他区域为0
				x"0000";

rdata <= rgb_reg(15 downto 11);		--高5位
gdata <= rgb_reg(10 downto 5);		--中6位
bdata <= rgb_reg(4 downto 0);			--低5位

end tt;


