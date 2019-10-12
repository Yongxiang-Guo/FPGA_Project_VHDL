library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity rom is
	generic
	(
		data_width	:	natural	:=	16;		--数据宽度16bit
		addr_width	:	natural	:=	8			--存储器大小2^8=256个单元，每个单元16bit
	);
	
	port
	(
		cs, rd		:	in		std_logic;		--cs高电平有效，rd上升沿有效
		addr			:	in 	std_logic_vector((addr_width - 1) downto 0);
		data			:	out	std_logic_vector((data_width - 1) downto 0)
	);
end rom;

architecture tt of rom is
	--信号定义
	subtype word_t is std_logic_vector((data_width - 1) downto 0);		--每个单元大小16bit
	type memory_t is array((2**addr_width - 1) downto 0) of word_t;	--一共有256个单元
	signal rom_reg		:	memory_t;
	signal addr_reg	:	natural range 0 to (2**addr_width - 1);
	--ROM初始化
	attribute ram_init_file	:	string;
	attribute ram_init_file of rom_reg:
	signal is "init_rom.mif";
	
begin
	addr_reg <= conv_integer(addr);			--读取地址
	process(rd)
	begin
		if(rd'event and rd = '1')then			--检测到rd信号上升沿
			if(cs = '1')then    --当cs有效时，启动读操作
				data <= rom_reg(addr_reg);
			end if;
		end if;
	end process;
end tt;
	
