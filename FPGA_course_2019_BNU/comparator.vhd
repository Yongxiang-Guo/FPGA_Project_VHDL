library ieee;
use ieee.std_logic_1164.all;

entity comparator is
port(	a, b:in std_logic_vector(15 downto 0);
		sel:in std_logic_vector(2 downto 0);
		compout:out std_logic
);
end comparator;

architecture tt of comparator is
signal same:std_logic;
signal more:std_logic;
signal less:std_logic;
begin

process(sel)
begin
if(a = b)then
	same <= '1';
else
	same <= '0';
end if;

if(a > b)then
	more <= '1';
else
	more <= '0';
end if;

if(a < b)then
	less <= '1';
else
	less <= '0';
end if;

case sel is
	when "000" => 	compout <= same;
	when "001" => 	compout <= not same;
	when "010" => 	compout <= more;
	when "011" => 	compout <= not less;
	when "100" => 	compout <= less;
	when "101" => 	compout <= not more;
	when others =>	null;
end case;

end process;
end tt;

