library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bin_onehot is
generic(bin_width: natural:= 10;
onehot_width: natural:= 1024);
port(gclk: std_logic;
ctrl_rand: std_logic_vector (2 downto 0);
binary: in unsigned (bin_width-1 downto 0);
onehot: out std_logic_vector (onehot_width-1 downto 0));
end entity;

architecture x of bin_onehot is
signal decoder: std_logic_vector (onehot_width-1 downto 0);

begin

process(binary)
variable code: std_logic_vector (onehot_width-1 downto 0);
begin
  code:=(others=>'0');
  for j in 0 to onehot_width-1 loop
    if to_integer(binary)=j then
      code(j):='1';
    else
      code(j):='0';
    end if;
  end loop;
  decoder<=code;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if ctrl_rand="100" then
      onehot<=decoder;
    elsif ctrl_rand="001" or ctrl_rand="101" then
      onehot<=(others=>'0');
    end if;
  end if;
end process;

end x;
