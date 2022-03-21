library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bin_onehot is
generic(bin_width: natural:= 10;
onehot_width: natural:= 128);
port(gclk: std_logic;
ctrl_rand: std_logic_vector (2 downto 0);
binary: in unsigned (bin_width-1 downto 0);
onehot: out std_logic_vector (onehot_width-1+8 downto 0));
end entity;

architecture x of bin_onehot is
signal decoder: std_logic_vector (onehot_width-1+8 downto 0);
signal bin_msb: unsigned (bin_width-1-3 downto 0);
signal bin_lsb: unsigned (bin_width-1-7 downto 0);

begin

process(bin_msb)
variable code0: std_logic_vector (onehot_width-1 downto 0);
begin
  code0:=(others=>'0');
  for j in 0 to onehot_width-1 loop
    if to_integer(bin_msb)=j then
      code0(j):='1';
    else
      code0(j):='0';
    end if;
  end loop;
  decoder(onehot_width-1+8 downto 8)<=code0;
end process;

process(bin_lsb)
variable code1: std_logic_vector (7 downto 0);
begin
  code1:=(others=>'0');
  for j in 0 to 7 loop
    if to_integer(bin_lsb)=j then
      code1(j):='1';
    else
      code1(j):='0';
    end if;
  end loop;
  decoder(7 downto 0)<=code1;
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

bin_msb<=binary(bin_width-1 downto 3);
bin_lsb<=binary(2 downto 0);

end x;
