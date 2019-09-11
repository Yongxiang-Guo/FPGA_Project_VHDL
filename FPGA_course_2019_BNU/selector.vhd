entity selector is
port(	a,b:in bit;
		control:in bit;		--control为1时，选择a；为0时，选择b
		q:out bit
);
end selector;
architecture tt of selector is
begin
q <= (a and control) or (b and (not control));
end tt;