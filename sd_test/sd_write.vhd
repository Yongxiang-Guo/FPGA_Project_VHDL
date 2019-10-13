library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity sd_write is
	port
	(
		sd_clk		:	in			std_logic;			--sd时钟
		sd_cs			:	out		std_logic;			--sd片选信号，0有效，在发送和接收数据时，CS都需要置0
		sd_data_in	:	out		std_logic;			--sd数据输入
		sd_data_out	:	in			std_logic;			--sd数据输出
		init_o		:	in			std_logic;			--初始化完成信号：1有效
		sec			:	in			std_logic_vector(31 downto 0);		--写sd的sec地址
		write_req	:	in			std_logic;			--写sd卡请求，1有效
		write_state	:	buffer	std_logic_vector(3 downto 0);			--写sd卡的状态
		rx_valid		:	buffer	std_logic;			--接收数据有效（即接收应答完成），1有效
		write_o		:	out		std_logic			--写sd完成，1有效
	);
end sd_write;

architecture tt of sd_write is
--常量定义
constant idle:std_logic_vector(3 downto 0):= "0000";			--空闲状态
constant write_cmd:std_logic_vector(3 downto 0):= "0001";	--发送CMD24命令
constant wait_8clk:std_logic_vector(3 downto 0):= "0010";	--写数据前等待8clock
constant start_taken:std_logic_vector(3 downto 0):= "0011";	--发送start block taken
constant writea:std_logic_vector(3 downto 0):= "0100";		--写512个字节(0~255,0~255)到SD卡
constant write_crc:std_logic_vector(3 downto 0):= "0101";	--写crc:0xff,0xff
constant write_wait:std_logic_vector(3 downto 0):= "0110";	--等待数据写入完成
constant write_done:std_logic_vector(3 downto 0):= "0111";	--数据写入完成

--信号定义
signal rx:std_logic_vector(7 downto 0);		--接收数据
signal rx_start:std_logic;		--开始接收数据：高电平有效
signal bit_cnt:integer range 0 to 7;
signal write_cnt:integer range 0 to 1023;
signal data_cnt:integer range 0 to 7;
signal write_cnt_reg:std_logic_vector(9 downto 0);
signal CMD24:std_logic_vector(47 downto 0):= x"5800000000ff";
signal start_block_token:std_logic_vector(7 downto 0):= x"fe";	--令牌字

begin
	write_cnt_reg <= conv_std_logic_vector(write_cnt, 10);
	
	--接收SD卡输出数据
	process(sd_clk)
	begin
		if(sd_clk'event and sd_clk = '1')then
			rx(0) <= sd_data_out;
			rx(7 downto 1) <= rx(6 downto 0);
		end if;
	end process;
	
	--接收SD卡应答信号
	process(sd_clk)
	begin
		if(sd_clk'event and sd_clk = '1')then
			if(sd_data_out = '0' and rx_start = '0')then		--检测到应答起始位0
				rx_valid <= '0';
				bit_cnt <= 1;
				rx_start <= '1';
			elsif(rx_start = '1')then
				if(bit_cnt < 7)then
					bit_cnt <= bit_cnt + 1;
					rx_valid <= '0';
				else
					bit_cnt <= 0;
					rx_start <= '0';
					rx_valid <= '1';		--接收完成，数据有效
				end if;
			else
				rx_start <= '0';
				bit_cnt <= 0;
				rx_valid <= '0';
			end if;
		end if;
	end process;
	
	--SD卡写程序
	process(sd_clk)
	begin
		if(sd_clk'event and sd_clk = '1')then
			if(init_o = '0')then		--只有当初始化工作完成，才进行写入
				write_state <= idle;
				CMD24 <= x"5800000000ff";
				write_o <= '0';
			else
				case write_state is
					when idle		=>
						sd_cs <= '1';
						sd_data_in <= '1';
						write_cnt <= 0;
						if(write_req = '1')then		--当有写请求时，开始写流程，给SD卡发送命令
							write_state <= write_cmd;
							CMD24 <= x"58" & sec & x"ff";
							start_block_token <= x"fe";
							write_o <= '0';
						else
							write_state <= idle;
						end if;
					when write_cmd	=>		--发送写命令
						if(CMD24 /= x"000000000000")then
							sd_cs <= '0';
							sd_data_in <= CMD24(47);
							CMD24 <= CMD24(46 downto 0) & '0';
						else
							if(rx_valid = '1')then
								data_cnt <= 7;
								write_state <= wait_8clk;
								sd_cs <= '1';
								sd_data_in <= '1';
							end if;
						end if;
					when wait_8clk	=>		--写数据之前等待8clock
						if(data_cnt > 0)then
							data_cnt <= data_cnt - 1;
							sd_cs <= '1';
							sd_data_in <= '1';
						else
							sd_cs <= '1';
							sd_data_in <= '1';
							write_state <= start_taken;
							data_cnt <= 7;
						end if;
					when start_taken	=>		--发送Start Block Taken
						if(data_cnt > 0)then
							data_cnt <= data_cnt - 1;
							sd_cs <= '0';
							sd_data_in <= start_block_token(data_cnt);
						else
							sd_cs <= '0';
							sd_data_in <= start_block_token(0);
							write_state <= writea;
							data_cnt <= 7;
							write_cnt <= 0;
						end if;
					when writea		=>		--写512个字节(0~255,0~255)到SD卡
						if(write_cnt < 512)then
							if(data_cnt > 0)then
								sd_cs <= '0';
								sd_data_in <= write_cnt_reg(data_cnt);
								data_cnt <= data_cnt - 1;
							else
								sd_cs <= '0';
								sd_data_in <= write_cnt_reg(0);
								data_cnt <= 7;
								write_cnt <= write_cnt + 1;
							end if;
						else			--写last byte
							if(data_cnt > 0)then
								sd_data_in <= write_cnt_reg(data_cnt);
								data_cnt <= data_cnt - 1;
							else
								sd_data_in <= write_cnt_reg(0);
								data_cnt <= 7;
								write_cnt <= 0;
								write_state <= write_crc;
							end if;
						end if;
					when write_crc	=>		--写crc:0xff,0xff
						if(write_cnt < 16)then
							sd_cs <= '0';
							sd_data_in <= '1';
							write_cnt <= write_cnt + 1;
						else
							if(rx_valid = '1')then		--等待Data Response Token
								write_state <= write_wait;
							else
								write_state <= write_crc;
							end if;
						end if;
					when write_wait	=>		--等待数据写入完成
						if(rx = x"ff")then
							write_state <= write_done;
						else
							write_state <= write_wait;
						end if;
					when write_done	=>
						if(write_cnt < 15)then		--等待15个clock
							sd_cs <= '1';
							sd_data_in <= '1';
							write_cnt <= write_cnt + 1;
						else
							write_state <= idle;
							write_o <= '1';
							write_cnt <= 0;
						end if;
					when others	=>
						write_state <= idle;
				end case;
			end if;
		end if;
	end process;
	
end tt;	

	