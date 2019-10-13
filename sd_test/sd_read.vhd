library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity sd_read is
	port
	(
		sd_clk		:	in			std_logic;			--SD卡时钟
		sd_cs			:	out		std_logic;			--SD卡片选，0有效，在发送和接收数据时，CS都需要置0
		sd_data_in	:	out		std_logic;			--SD卡数据输入
		sd_data_out	:	in			std_logic;			--SD卡数据输出
		sec			:	in			std_logic_vector(31 downto 0);	--SD卡的sec地址
		read_req		:	in			std_logic;			--SD卡数据读请求信号，1有效
		sd_data		:	out		std_logic_vector(7 downto 0);		--SD卡读出的数据
		data_valid	:	out		std_logic;			--数据有效信号，1有效
		data_come	:	out		std_logic;			--SD卡数据起始位读出信号，1有效
		init_o		:	in			std_logic;			--SD卡初始化完成信号，1有效
		read_state	:	buffer	std_logic_vector(3 downto 0);		--SD卡读状态
		read_o		:	out		std_logic			--SD卡读完成，1有效
	);
end sd_read;

architecture tt of sd_read is
--常量定义：SD读取状态
constant idle:std_logic_vector(3 downto 0):= x"0";
constant read_cmd:std_logic_vector(3 downto 0):= x"1";
constant read_wait:std_logic_vector(3 downto 0):= x"2";
constant read_data:std_logic_vector(3 downto 0):= x"3";
constant read_done:std_logic_vector(3 downto 0):= x"4";

--信号定义
signal rx:std_logic_vector(7 downto 0);
signal rx_start:std_logic;
signal rx_valid:std_logic;
signal bit_cnt_1:integer range 0 to 7;
signal bit_cnt_2:integer range 0 to 7;
signal read_cnt_1:integer range 0 to 1023;
signal read_cnt_2:integer range 0 to 1023;
signal read_start:std_logic;
signal read_finish:std_logic;
signal data_buffer:std_logic_vector(7 downto 0);
signal read_step:integer range 0 to 3;
signal CMD17:std_logic_vector(47 downto 0):= x"5100000000ff";

begin
	--接收SD卡数据
	process(sd_clk)
	begin
		if(sd_clk'event and sd_clk = '1')then
			rx(0) <= sd_data_out;
			rx(7 downto 1) <= rx(6 downto 0);
		end if;
	end process;
	
	--接收一个block读命令的应答数据
	process(sd_clk)
	begin
		if(sd_clk'event and sd_clk = '1')then
			if(sd_data_out = '0' and rx_start = '0')then		--检测到应答起始位0
				rx_valid <= '0';
				bit_cnt_1 <= 1;		--第一位：0
				rx_start <= '1';		--开始接收
			elsif(rx_start = '1')then
				if(bit_cnt_1 < 7)then	--共接收8bit应答数据
					bit_cnt_1 <= bit_cnt_1 + 1;
					rx_valid <= '0';
				else
					bit_cnt_1 <= 0;
					rx_start <= '0';
					rx_valid <= '1';		--接收完成，数据有效
				end if;
			else
				rx_start <= '0';
				bit_cnt_1 <= 0;
				rx_valid <= '0';
			end if;
		end if;
	end process;
	
	--block SD读流程
	process(sd_clk)
	begin
		if(sd_clk'event and sd_clk = '1')then
			if(init_o = '0')then		--只有当初始化工作完成，才进行读取
				read_state <= idle;
				CMD17 <= x"5100000000ff";
				read_start <= '0';
				read_o <= '0';
				sd_cs <= '1';
				sd_data_in <= '1';
			else
				case read_state is
					when idle	=>
						read_start <= '0';
						sd_cs <= '1';
						sd_data_in <= '1';
						read_cnt_1 <= 0;
						if(read_req = '1')then		--当有读取请求时，开始读取流程，给SD卡发送命令
							read_state <= read_cmd;
							read_o <= '0';
							CMD17 <= x"51" & sec & x"ff";
						else
							read_state <= idle;
						end if;
					when read_cmd	=>			--发送读取命令
						read_start <= '0';
						if(CMD17 /= x"000000000000")then
							sd_cs <= '0';
							sd_data_in <= CMD17(47);
							CMD17 <= CMD17(46 downto 0) & '0';
							read_cnt_1 <= 0;
						else
							if(rx_valid = '1')then	--接收应答信号完成，进入等待数据读取完成状态...似乎没有检测应答是否正确
								read_cnt_1 <= 0;
								read_state <= read_wait;
							end if;
						end if;
					when read_wait	=>			--等待数据读取完成
						if(read_finish = '1')then	
							read_state <= read_done;
							read_start <= '0';
						else
							read_start <= '1';
						end if;
					when read_done	=>			--读取完成
						read_start <= '0';
						if(read_cnt_1 < 15)then	--等待15个时钟后，进入空闲状态
							sd_cs <= '1';
							sd_data_in <= '1';
							read_cnt_1 <= read_cnt_1 + 1;
						else
							read_cnt_1 <= 0;
							read_state <= idle;
							read_o <= '1';
						end if;
					when others	=>
						read_state <= idle;
				end case;
			end if;
		end if;
	end process;
	
	
	--接收SD的512个数据
	process(sd_clk)
	begin
		if(sd_clk'event and sd_clk = '1')then
			if(init_o = '0')then		
				data_valid <= '0';
				sd_data <= x"00";
				data_buffer <= x"00";
				read_step <= 0;
				read_finish <= '0';
				data_come <= '0';
			else
				case read_step is
					when 0	=>			--等待数据起始位：一般SD卡发出应答信号后，还要等待一段时间，才会发送数据
						bit_cnt_2 <= 0;
						read_cnt_2 <= 0;
						read_finish <= '0';
						if(read_start = '1' and sd_data_out = '0')then	--检测到数据起始位0
							read_step <= 1;
							data_come <= '1';
						else
							read_step <= 0;
						end if;
					when 1	=>
						if(read_cnt_2 < 512)then		--一共512byte
							if(bit_cnt_2 < 7)then		--一字节8bit
								data_valid <= '0';
								data_buffer <= data_buffer(6 downto 0) & sd_data_out;	
								bit_cnt_2 <= bit_cnt_2 + 1;
								data_come <= '0';
							else
								data_valid <= '1';
								sd_data <= data_buffer(6 downto 0) & sd_data_out;
								bit_cnt_2 <= 0;
								read_cnt_2 <= read_cnt_2 + 1;
								data_come <= '0';
							end if;
						else				
							read_finish <= '1';		--读取完成
							read_step <= 0;
							data_valid <= '0';
							data_come <= '0';
						end if;
					when others	=>
						read_step <= 0;
				end case;
			end if;
		end if;
	end process;
		
end tt;
