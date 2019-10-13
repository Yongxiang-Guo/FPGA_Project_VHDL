library ieee;
use ieee.std_logic_1164.all;

entity sd_test is
	port
	(
		clk_50MHz	:	in		std_logic;
		rst			:	in		std_logic;
		sd_clk		:	out	std_logic;
		sd_cs			:	out	std_logic;
		sd_data_in	:	out	std_logic;
		sd_data_out	:	in		std_logic;
		LED1			:	out	std_logic
	);
end sd_test;

architecture tt of sd_test is
--元件例化
component sd_init
	port
	(
		sd_clk		:	in		std_logic;			--sd卡SPI时钟25MHz
		rst			:	in		std_logic;			--复位信号，低电平有效
		sd_cs			:	out	std_logic;			--sd片选信号
		sd_data_in	:	out	std_logic;			--sd卡数据输入
		sd_data_out	:	in		std_logic;			--sd卡数据输出
		rx				:	buffer	std_logic_vector(47 downto 0);		--接收sd卡输出数据（存储48位）
		init_o		:	out	std_logic;			--sd卡初始化完成信号，高电平有效
		init_state	:	buffer	std_logic_vector(3 downto 0)			--sd初始化状态
	);
end component;

component sd_write
	port
	(
		sd_clk		:	in			std_logic;			--sd时钟
		sd_cs			:	out		std_logic;			--sd片选信号
		sd_data_in	:	out		std_logic;			--sd数据输入
		sd_data_out	:	in			std_logic;			--sd数据输出
		init_o		:	in			std_logic;			--初始化完成信号：高电平有效
		sec			:	in			std_logic_vector(31 downto 0);		--写sd的sec地址
		write_req	:	in			std_logic;			--写sd卡请求
		write_state	:	buffer	std_logic_vector(3 downto 0);			--写sd卡的状态
		rx_valid		:	buffer	std_logic;			--接收数据有效（即接收应答完成）
		write_o		:	out		std_logic			--写sd完成
	);
end component;

component sd_read
	port
	(
		sd_clk		:	in			std_logic;			--SD卡时钟
		sd_cs			:	out		std_logic;			--SD卡片选
		sd_data_in	:	out		std_logic;			--SD卡数据输入
		sd_data_out	:	in			std_logic;			--SD卡数据输出
		sec			:	in			std_logic_vector(31 downto 0);	--SD卡的sec地址
		read_req		:	in			std_logic;			--SD卡数据读请求信号
		sd_data		:	out		std_logic_vector(7 downto 0);		--SD卡读出的数据
		data_valid	:	out		std_logic;			--数据有效信号
		data_come	:	out		std_logic;			--SD卡数据读出指示信号
		init_o		:	in			std_logic;			--SD卡初始化完成信号
		read_state	:	buffer	std_logic_vector(3 downto 0);		--SD卡读状态
		read_o		:	out		std_logic			--SD卡读完成
	);
end component;

--常量定义
constant status_init:std_logic_vector(1 downto 0):= "00";
constant status_write:std_logic_vector(1 downto 0):= "01";
constant status_read:std_logic_vector(1 downto 0):= "10";
constant status_idle:std_logic_vector(1 downto 0):= "11";

--信号定义
signal clk_25MHz:std_logic;

signal sd_data_in_i:std_logic;
signal sd_data_in_w:std_logic;
signal sd_data_in_r:std_logic;
signal sd_data_in_o:std_logic;
signal sd_cs_i:std_logic;
signal sd_cs_w:std_logic;
signal sd_cs_r:std_logic;
signal sd_cs_o:std_logic;

signal read_sec:std_logic_vector(31 downto 0);
signal read_req:std_logic;
signal write_sec:std_logic_vector(31 downto 0);
signal write_req:std_logic;
signal data_come:std_logic;

signal sd_data:std_logic_vector(7 downto 0);
signal data_valid:std_logic;
signal rx_valid:std_logic;
signal init_o:std_logic;		--初始化完成
signal write_o:std_logic;		--写完成
signal read_o:std_logic;		--读完成

signal sd_state:std_logic_vector(1 downto 0);		--SD卡状态：空闲、初始化、写、读
signal init_state:std_logic_vector(3 downto 0);
signal write_state:std_logic_vector(3 downto 0);
signal read_state:std_logic_vector(3 downto 0);

begin
	sd_clk <= clk_25MHz;
	sd_cs <= sd_cs_o;
	sd_data_in <= sd_data_in_o;
	
	--时钟分频
	process(clk_50MHz)
	begin
		if(clk_50MHz'event and clk_50MHz = '1')then
			clk_25MHz <= not clk_25MHz;
		end if;
	end process;
	
	--SD卡初始化，block写，block读
	process(clk_25MHz)
	begin
		if(clk_25MHz'event and clk_25MHz = '1')then
			if(rst = '0')then
				LED1 <= '1';		--用于测试
				sd_state <= status_init;
				read_req <= '0';
				read_sec <= x"00000000";
				write_req <= '0';
				write_sec <= x"00000000";
			else
				LED1 <= '0';
				case sd_state is
					when status_init	=>
						if(init_o = '1')then		--初始化完成，开始写SD卡
							sd_state <= status_write;
							write_sec <= x"00000000";
							write_req <= '1';		--产生写请求
						else
							sd_state <= status_init;
						end if;
					when status_write	=>
						if(write_o = '1')then	--SD卡写完成，开始读SD卡
							sd_state <= status_read;
							read_sec <= x"00000000";
							read_req <= '1';		--产生读请求
						else
							write_req <= '0';		--写入未完成，取消写请求
							sd_state <= status_write;
						end if;
					when status_read	=>
						if(read_o = '1')then		--读完成，进入空闲状态
							sd_state <= status_idle;
						else
							read_req <= '0';		--读未完成，取消读请求
							sd_state <= status_read;
						end if;
					when status_idle	=>
						sd_state <= status_idle;	--处于空闲状态
					when others =>
						sd_state <= status_idle;
				end case;
			end if;
		end if;
	end process;
	
	--SD卡SPI信号的选择
	process(clk_25MHz)
	begin
		if(clk_25MHz'event and clk_25MHz = '1')then
			case sd_state is
				when status_init	=>		--初始化
					sd_cs_o <= sd_cs_i;
					sd_data_in_o <= sd_data_in_i;
				when status_write	=>		--写
					sd_cs_o <= sd_cs_w;
					sd_data_in_o <= sd_data_in_w;
				when status_read	=>		--读
					sd_cs_o <= sd_cs_r;
					sd_data_in_o <= sd_data_in_r;
				when others			=>		--空闲
					sd_cs_o <= '1';
					sd_data_in_o <= '1';
			end case;
		end if;
	end process;
	
	--SD卡初始化
	u1:sd_init port map
		(
			sd_clk		=>	clk_25MHz,
			rst			=>	rst,
         sd_cs			=>	sd_cs_i,
         sd_data_in	=>	sd_data_in_i,
         sd_data_out	=>	sd_data_out,
         --rx				=>
         init_o		=> init_o,
         init_state	=>	init_state
		);
	
	--SD卡写入
	u2:sd_write port map
		(
			sd_clk		=>	clk_25MHz,
			sd_cs			=>	sd_cs_w,
			sd_data_in	=>	sd_data_in_w,
			sd_data_out	=>	sd_data_out,	
			init_o		=>	init_o,
			sec			=>	write_sec,
			write_req	=>	write_req,
			write_state	=>	write_state,
			rx_valid		=>	rx_valid,
			write_o		=>	write_o
		);
	
	--SD卡读取
	u3:sd_read port map
		(
			sd_clk		=>	clk_25MHz,
			sd_cs			=>	sd_cs_r,
			sd_data_in	=>	sd_data_in_r,
			sd_data_out	=>	sd_data_out,
			sec			=>	read_sec,
			read_req		=>	read_req,
			sd_data		=>	sd_data,
			data_valid	=>	data_valid,
			data_come	=>	data_come,
			init_o		=>	init_o,
			read_state	=>	read_state,
			read_o		=>	read_o
		);
		
end tt;