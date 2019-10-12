library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity mcu_design_1 is
	generic
	(
		data_width	:	natural	:=	16;
		addr_width	:	natural	:=	8
	);
	
	port
	(
		clk, rst		:	in		std_logic;
		portin		:	in		std_logic_vector(15 downto 0);
		portout		:	out	std_logic_vector(15 downto 0);
		mcodeout		:	out	std_logic_vector(15 downto 0)
	);
end mcu_design_1;

architecture tt of mcu_design_1 is
component control
	port
	(
		clk, rst		:	in		std_logic;
		rom_code		:	in		std_logic_vector(15 downto 0);
		rom_cs, rd	:	out	std_logic;
		addr			:	out	std_logic_vector(7 downto 0);
		portin		:	in		std_logic_vector(15 downto 0);
		portout		:	out	std_logic_vector(15 downto 0);
		codeout		:	out	std_logic_vector(15 downto 0)		
	);
end component;

component rom
	port
	(
		cs, rd		:	in		std_logic;		--cs高电平有效，rd上升沿有效
		addr			:	in 	std_logic_vector((addr_width - 1) downto 0);
		data			:	out	std_logic_vector((data_width - 1) downto 0)
	);
end component;

signal rom_code_node:std_logic_vector(15 downto 0);
signal rom_cs_node, rd_node:std_logic;
signal addr_node:std_logic_vector(7 downto 0);

begin
	u1: control port map
		(
			clk => clk,
			rst => rst,
			rom_code => rom_code_node,
			rom_cs => rom_cs_node,
			rd => rd_node,
			addr => addr_node,
			portin => portin,
			portout => portout,
			codeout => mcodeout
		);
		
	u2: rom port map
		(
			cs => rom_cs_node,
			rd => rd_node,
			addr => addr_node,
			data => rom_code_node
		);
		
end tt;
