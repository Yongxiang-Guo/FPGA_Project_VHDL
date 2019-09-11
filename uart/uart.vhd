--------------------------------------------
--实体功能：实现串口收发，串口标准协议（波特率为9600，无奇偶校验位）和电脑通信
--电脑发送数据给FPGA，FPGA把接收到的数据再通过串口发送出去
--------------------------------------------
entity uart is
port(	clk_50Mhz:in bit;
		tx:out bit;
		rx:in	bit
		--rx_data:out bit_vector(7 downto 0);
		--tx_data:in bit_vector(7 downto 0);
		--rx_sig:out bit;		--接收完成标志：上升沿有效
		--tx_sig:in bit			--发送启动命令：上升沿有效
);
end uart;

architecture tt of uart is
--信号定义
signal rx_data:bit_vector(7 downto 0);
signal tx_data:bit_vector(7 downto 0);
signal rx_sig:bit;		--接收完成标志：上升沿有效
signal tx_sig:bit;		--发送启动命令：上升沿有效

signal clk_uart:bit;
signal tx_state:bit;		--串口发送线路状态：高电平为忙碌
signal tx_buf:bit;
signal tx_sig_rise:bit;	--检测到发送命令信号上升沿：高电平有效
signal send:bit;			--启动串口发送：高电平有效
signal rx_state:bit;		--串口接收线路状态：高电平为忙碌
signal rx_buf:bit;
signal rx_fall:bit;		--检测到接收命令信号下降沿：高电平有效
signal receive:bit;		--启动串口接收：高电平有效
signal tx_count:integer range 0 to 255;		--tx计数值
signal rx_count:integer range 0 to 255;		--rx计数值

begin
--串口接收数据直接发送出去
tx_sig <= rx_sig;
tx_data <= rx_data;

--时钟分频：串口时钟，波特率为9600
--16个时钟发（收）1bit：1个起始位、8个数据位、1个停止位
--50Mhz时钟326分频
process(clk_50Mhz)
variable cnt:integer range 0 to 163;
begin
if(clk_50Mhz'event and clk_50Mhz = '1')then
	cnt := cnt + 1;
	if(cnt = 163)then
		clk_uart <= not clk_uart;
		cnt := 0;
	end if;
end if;
end process;

---------------------------------------------	
------------------串口发送--------------------
---------------------------------------------
--检测发送命令标志tx_sig的上升沿
process(clk_uart)
begin
if(clk_uart'event and clk_uart = '1')then
	tx_buf <= tx_sig;
	tx_sig_rise <= (not tx_buf) and tx_sig;
end if;
end process;

--启动串口发送
process(clk_uart)
begin
if(clk_uart'event and clk_uart = '1')then
	if(tx_sig_rise = '1' and tx_state = '0')then		--当发送命令有效且线路为空闲时，启动新的数据发送进程
		send <= '1';
	elsif(tx_count = 152)then		--一帧数据发送结束
		send <= '0';
	end if;
end if;
end process;

--串口发送程序：16个时钟发送一个bit
process(clk_uart)
begin
if(clk_uart'event and clk_uart = '1')then
	if(send = '1')then
		case tx_count is
			when 0 => tx <= '0'; tx_state <= '1'; tx_count <= tx_count + 1;				--发送起始位
			when 16 => tx <= tx_data(0); tx_state <= '1'; tx_count <= tx_count + 1;		--发送数据0位
			when 32 => tx <= tx_data(1); tx_state <= '1'; tx_count <= tx_count + 1;		--发送数据1位
			when 48 => tx <= tx_data(2); tx_state <= '1'; tx_count <= tx_count + 1;		--发送数据2位
			when 64 => tx <= tx_data(3); tx_state <= '1'; tx_count <= tx_count + 1;		--发送数据3位
			when 80 => tx <= tx_data(4); tx_state <= '1'; tx_count <= tx_count + 1;		--发送数据4位
			when 96 => tx <= tx_data(5); tx_state <= '1'; tx_count <= tx_count + 1;		--发送数据5位
			when 112 => tx <= tx_data(6); tx_state <= '1'; tx_count <= tx_count + 1;	--发送数据6位
			when 128 => tx <= tx_data(7); tx_state <= '1'; tx_count <= tx_count + 1;	--发送数据7位
			when 144 => tx <= '1'; tx_state <= '1'; tx_count <= tx_count + 1;				--发送停止位
			when 152 => tx <= '1'; tx_state <= '0'; tx_count <= tx_count + 1;				--一帧数据发送结束
			when others => tx_count <= tx_count + 1;
		end case;
	else
		tx <= '1'; tx_count <= 0; tx_state <= '0';
	end if;
end if;
end process;
---------------------------------------------	
---------------------------------------------
---------------------------------------------


---------------------------------------------	
------------------串口接收--------------------
---------------------------------------------
--检测线路的下降沿
process(clk_uart)
begin
if(clk_uart'event and clk_uart = '1')then
	rx_buf <= rx;
	rx_fall <= rx_buf and (not rx);
end if;
end process;

--启动串口发送
process(clk_uart)
begin
if(clk_uart'event and clk_uart = '1')then
	if(rx_fall = '1' and rx_state = '0')then		--检测到线路下降沿且原先线路为空闲时，启动接收数据进程
		receive <= '1';
	elsif(rx_count = 152)then		--接收数据完成
		receive <= '0';
	end if;
end if;
end process;

--串口接收程序：16个时钟接收一个bit
process(clk_uart)
begin
if(clk_uart'event and clk_uart = '1')then
	if(receive = '1')then
		case rx_count is
			when 0 => rx_state <= '1'; rx_count <= rx_count + 1; rx_sig <= '0';
			when 24 => rx_state <= '1'; rx_data(0) <= rx; rx_count <= rx_count + 1; rx_sig <= '0';		--接收数据0位
			when 40 => rx_state <= '1'; rx_data(1) <= rx; rx_count <= rx_count + 1; rx_sig <= '0';		--接收数据1位
			when 56 => rx_state <= '1'; rx_data(2) <= rx; rx_count <= rx_count + 1; rx_sig <= '0';		--接收数据2位
			when 72 => rx_state <= '1'; rx_data(3) <= rx; rx_count <= rx_count + 1; rx_sig <= '0';		--接收数据3位
			when 88 => rx_state <= '1'; rx_data(4) <= rx; rx_count <= rx_count + 1; rx_sig <= '0';		--接收数据4位
			when 104 => rx_state <= '1'; rx_data(5) <= rx; rx_count <= rx_count + 1; rx_sig <= '0';	--接收数据5位
			when 120 => rx_state <= '1'; rx_data(6) <= rx; rx_count <= rx_count + 1; rx_sig <= '0';	--接收数据6位
			when 136 => rx_state <= '1'; rx_data(7) <= rx; rx_count <= rx_count + 1; rx_sig <= '1';	--接收数据7位
			when 152 => rx_state <= '1'; rx_count <= rx_count + 1; rx_sig <= '1';
			when others => rx_count <= rx_count + 1;
		end case;
	else
		rx_state <= '0'; rx_count <= 0; rx_sig <= '0';
	end if;
end if;
end process;

---------------------------------------------	
---------------------------------------------
---------------------------------------------

end tt;

