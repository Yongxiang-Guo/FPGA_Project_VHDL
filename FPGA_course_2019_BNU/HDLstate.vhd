library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

entity HDLstate is
	port
	(
		clk		:	in		std_logic;
		rst		:	in		std_logic;			--状态机复位：s0
		func_sel	:	in		std_logic_vector(3 downto 0);
		ar, br	:	in		std_logic_vector(15 downto 0);
		result	:	out	std_logic_vector(31 downto 0)
	);
end HDLstate;

architecture tt of HDLstate is
type states_type is (s3, s2, s1, s0);
signal state:states_type := s0;
signal ar32, br32:std_logic_vector(31 downto 0); 
signal result_reg:std_logic_vector(31 downto 0);

begin
	ar32 <= x"0000" & ar;
	br32 <= x"0000" & br;
	
	process(clk, rst)
	begin
		if(rst = '1')then
			state <= s0;
		elsif(clk'event and clk = '1')then
			case state is
				when s0 => 	state <= s1;
				when s1 => 	state <= s2;
								if(func_sel = "0001")then
									result_reg <= ar32 + br32;
								elsif(func_sel = "0011")then
									result_reg <= ar * br;
								elsif(func_sel = "0101")then
									result_reg <= ar32 and br32;
								elsif(func_sel = "1000")then
									result_reg <= ar32(30 downto 0) & '0';
								else null;
								end if;
				when s2 => 	state <= s3;
				when s3 => 	state <= s0;
								result <= result_reg;
				when others => state <= s0;
			end case;
		end if;
	end process;
	
end tt;
	
	