library ieee;
use ieee.std_logic_1164.all;

entity sd_init is
	port
	(
		sd_clk		:	in		std_logic;			--sd卡SPI时钟25MHz
		rst			:	in		std_logic;			--复位信号，低电平有效
		sd_cs			:	out	std_logic;			--sd片选信号，低电平有效，在发送和接收数据时，CS都需要置0
		sd_data_in	:	out	std_logic;			--sd卡数据输入
		sd_data_out	:	in		std_logic;			--sd卡数据输出
		rx				:	buffer	std_logic_vector(47 downto 0);		--接收sd卡输出数据（存储48位）
		init_o		:	out	std_logic;			--sd卡初始化完成信号，高电平有效
		init_state	:	buffer	std_logic_vector(3 downto 0)			--sd初始化状态
	);
end sd_init;

architecture tt of sd_init is
--常量定义
constant idle:std_logic_vector(3 downto 0):= "0000";				--状态为idle
constant send_cmd0:std_logic_vector(3 downto 0):= "0001";		--状态为发送CMD0
constant wait_cmd0:std_logic_vector(3 downto 0):= "0010";		--状态为等待CMD0应答
constant wait_time:std_logic_vector(3 downto 0):= "0011";		--状态为等待一段时间
constant send_cmd8:std_logic_vector(3 downto 0):= "0100";		--状态为发送CMD8
constant wait_cmd8:std_logic_vector(3 downto 0):= "0101";		--状态为等待CMD8应答
constant send_cmd55:std_logic_vector(3 downto 0):= "0110";		--状态为发送CMD55
constant send_acmd41:std_logic_vector(3 downto 0):= "0111";		--状态为发送ACMD41
constant init_done:std_logic_vector(3 downto 0):= "1000";		--状态为初始化结束
constant init_fail:std_logic_vector(3 downto 0):= "1001";		--状态为初始化错误

--信号定义
signal CMD0:std_logic_vector(47 downto 0):= x"400000000095";	--CMD0命令, 需要CRC 95
signal CMD8:std_logic_vector(47 downto 0):= x"48000001aa87";	--CMD8命令, 需要CRC 87 
signal CMD55:std_logic_vector(47 downto 0):= x"7700000000ff";	--CMD55命令, 不需要CRC
signal ACMD41:std_logic_vector(47 downto 0):= x"6940000000ff";	--ACMD41命令, 不需要CRC

signal reset:std_logic:= '1';		--复位信号，高电平时有效，进行延时片选sd卡复位；低电平时进行sd卡初始化
signal init_cnt:integer range 0 to 1023  	:= 0;		--初始化计时计数器
signal delay_cnt:integer range 0 to 1023 	:= 0;		--延时计数器
signal bit_cnt:integer range 0 to 47		:= 0;		--48位命令传输计数器
signal rx_valid:std_logic:= '0';		--接收数据有效信号（即接收48位命令完成）
signal rx_start:std_logic:= '0';		--开始接收数据

begin
	--接收sd卡的数据
	process(sd_clk)
	begin
		if(sd_clk'event and sd_clk = '1')then
			rx(0) <= sd_data_out;
			rx(47 downto 1) <= rx(46 downto 0);
		end if;
	end process;
	
	--接收sd卡的命令应答信号
	process(sd_clk)
	begin
		if(sd_clk'event and sd_clk = '1')then
			if((sd_data_out = '0') and (rx_start = '0'))then		--等待sd_data_out为低，则开始接收数据
				rx_valid <= '0';
				bit_cnt <= 1;		--接收到第一位为0
				rx_start <= '1';	--开始接收命令
			elsif(rx_start = '1')then
				if(bit_cnt < 47)then		--计数
					bit_cnt <= bit_cnt + 1;
					rx_valid <= '0';
				else							
					bit_cnt <= 0;
					rx_start <= '0';
					rx_valid <= '1';		--接收到第48位，命令应答接收完毕，数据有效
				end if;
			else
				rx_start <= '0';
				bit_cnt <= 0;
				rx_valid <= '0';
			end if;
		end if;
	end process;
	
	--上电后延时计数，释放reset信号
	process(sd_clk)
	begin
		if(sd_clk'event and sd_clk = '1')then
			if(rst = '0')then
				init_cnt <= 0;
				reset <= '1';
			else
				if(init_cnt < 1023)then
					init_cnt <= init_cnt + 1;
					reset <= '1';
				else
					reset <= '0';
				end if;
			end if;
		end if;
	end process;
	
	--sd卡初始化程序
	process(sd_clk)
	begin
		if(sd_clk'event and sd_clk = '1')then
-------------------------------不太明白这一段什么作用......经验证CS高低并没有什么用，这段作用纯属延时			
			if(reset = '1')then			--延时复位
				if(init_cnt < 512)then
					sd_cs <= '0';			--片选CS低电平选中sd卡...错误
					sd_data_in <= '1';
					init_o <= '0';
					init_state <= idle;
				else
					sd_cs <= '1';			--片选CS高电平释放sd卡...错误
					sd_data_in <= '1';
					init_o <= '0';
					init_state <= idle;
				end if;
-------------------------------------------------------------				
			else
				case init_state is
					when idle			=>
						sd_cs <= '1';
						sd_data_in <= '1';
						init_o <= '0';
						CMD0 <= x"400000000095";
						delay_cnt <= 0;
						init_state <= send_cmd0;
					when send_cmd0		=>
						if(CMD0 /= x"000000000000")then
							sd_cs <= '0';
							sd_data_in <= CMD0(47);
							CMD0 <= CMD0(46 downto 0) & '0';
						else
							sd_cs <= '0';
							sd_data_in <= '1';
							init_state <= wait_cmd0;
						end if;
					when wait_cmd0		=>
						if(rx_valid = '1' and (rx(47 downto 40) = x"01"))then          
							sd_cs <= '1';
							sd_data_in<= '1';
							init_state <= wait_time;
						elsif(rx_valid = '1' and (rx(47 downto 40) /= x"01"))then
							sd_cs <= '1';
							sd_data_in<= '1';
							init_state <= idle;
						else
							sd_cs <= '0';--------------不太明白......似乎是接收响应时CS需要为0
							sd_data_in<= '1';
							init_state <= wait_cmd0;
						end if;
					when wait_time		=>
						if(delay_cnt < 1023)then
							sd_cs <= '1';
							sd_data_in<= '1';
							init_state <= wait_time;
							delay_cnt <= delay_cnt + 1;
						else
							sd_cs <= '1';
							sd_data_in<= '1';
							init_state <= send_cmd8;
							CMD8 <= x"48000001aa87";
							delay_cnt <= 0;
						end if;
					when send_cmd8		=>
						if(CMD8 /= x"000000000000")then
							sd_cs <= '0';
							sd_data_in <= CMD8(47);
							CMD8 <= CMD8(46 downto 0) & '0';
						else
							sd_cs <= '0';
							sd_data_in<= '1';
							init_state <= wait_cmd8;
						end if;
					when wait_cmd8		=>
						sd_cs <= '0';
						sd_data_in <= '1';
						if(rx_valid = '1' and (rx(19 downto 16) = "0001"))then
							init_state <= send_cmd55;
							CMD55 <= x"7700000000ff";
							ACMD41 <= x"6940000000ff";
						elsif(rx_valid = '1' and (rx(19 downto 16) /= "0001"))then
							init_state <= init_fail;
						end if;
					when send_cmd55	=>
						if(CMD55 /= x"000000000000")then
							sd_cs <= '0';
							sd_data_in <= CMD55(47);
							CMD55 <= CMD55(46 downto 0) & '0';
						else
							sd_cs <= '0';
							sd_data_in <= '1';
							if(rx_valid = '1' and (rx(47 downto 40) = x"01"))then
								init_state <= send_acmd41;
							else
								if(delay_cnt < 127)then
									delay_cnt <= delay_cnt + 1;
								else
									delay_cnt <= 0;
									init_state <= init_fail;
								end if;
							end if;
						end if;
					when send_acmd41	=>
						if(ACMD41 /= x"000000000000")then
							sd_cs <= '0';
							sd_data_in <= ACMD41(47);
							ACMD41 <= ACMD41(46 downto 0) & '0';
						else
							sd_cs <= '0';
							sd_data_in <= '1';
							if(rx_valid = '1' and (rx(47 downto 40) = x"00"))then
								init_state <= init_done;
							else
								if(delay_cnt < 127)then
									delay_cnt <= delay_cnt + 1;
								else
									delay_cnt <= 0;
									init_state <= init_fail;
								end if;
							end if;
						end if;
					when init_done		=>
						init_o <= '1';
						sd_cs <= '1';
						sd_data_in <= '1';
						delay_cnt <= 0;
					when init_fail		=>
						init_o <= '0';
						sd_cs <= '1';
						sd_data_in <= '1';
						delay_cnt <= 0;
						init_state <= wait_time;	--初始化未成功,重新发送CMD8, CMD55 和CMD41
					when others			=>
						init_o <= '0';
						sd_cs <= '1';
						sd_data_in <= '1';
						delay_cnt <= 0;
						init_state <= idle;
				end case;
			end if;
		end if;
	end process;
	
end tt;
	