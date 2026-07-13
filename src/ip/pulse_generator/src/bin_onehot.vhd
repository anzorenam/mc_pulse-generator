library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bin_onehot is
port(gclk,gen_sel: std_logic;
ctrl_signal: std_logic_vector (3 downto 0);
binary: in unsigned (9 downto 0);
onehot: out std_logic_vector (23 downto 0));
end entity;

architecture x of bin_onehot is
signal local_rst,local_hab: std_logic;
signal decoder: std_logic_vector (23 downto 0);
signal bin_msb: unsigned (6 downto 0);
signal bin_lsb0: unsigned (2 downto 0);
signal bin_lsb1: unsigned (2 downto 0);

begin

process(bin_lsb1)
variable code: std_logic_vector(7 downto 0);
begin
  code:=(others=>'0');
  for j in 0 to 7 loop
    if to_integer(bin_lsb1)=j then
      code(j):='1';
    else
      code(j):='0';
    end if;
  end loop;
  decoder(15 downto 8)<=code;
end process;

process(bin_lsb0)
variable code: std_logic_vector(7 downto 0);
begin
  code:=(others=>'0');
  for j in 0 to 7 loop
    if to_integer(bin_lsb0)=j then
      code(j):='1';
    else
      code(j):='0';
    end if;
  end loop;
  decoder(7 downto 0)<=code;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if local_rst='1' then
      onehot<=(others=>'0');
    else
      if local_hab='1' then
        onehot<=decoder;
      end if;
    end if;
  end if;
end process;

decoder(23 downto 16)<=std_logic_vector(('0'&bin_msb)+"00010100");
bin_msb<=binary(9 downto 3);
bin_lsb1<=binary(2 downto 0)+"011";
bin_lsb0<=binary(2 downto 0)-"001";

local_rst<='1' when (ctrl_signal="0000" or ctrl_signal="1001") else
                 '0';

local_hab<='1' when (ctrl_signal="0110" and gen_sel='1') else
                  '0';

end x;
