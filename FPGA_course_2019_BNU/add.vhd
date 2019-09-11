entity add is
port(	a:in bit;
		b:in bit;
		sum:out bit;
		q:out bit
);
end add;

architecture tt of add is
begin

sum <= a xor b;
q <= a and b;

end tt;