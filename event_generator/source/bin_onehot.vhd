library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bin_onehot is
generic(bin_width: natural:= 10;
onehot_width: natural:= 8);
port(gclk: std_logic;
ctrl_rand: std_logic_vector (2 downto 0);
binary: in unsigned (bin_width-1 downto 0);
onehot: out std_logic_vector (onehot_width-1+16 downto 0));
end entity;

architecture x of bin_onehot is
signal decoder: std_logic_vector (onehot_width-1+16 downto 0);
signal bin_msb: unsigned (bin_width-1-3 downto 0);
signal bin_lsb0: unsigned (bin_width-1-7 downto 0);
signal bin_lsb1: unsigned (bin_width-1-7 downto 0);

begin

with bin_lsb1 select
  decoder(15 downto 8)<="10000000" when "000",
                                       "00000001" when "001",
                                       "00000011" when "010",
                                       "00000111" when "011",
                                       "00001111" when "100",
                                       "00011111" when "101",
                                       "00111111" when "110",
                                       "01111111" when "111";

with bin_lsb0 select
  decoder(7 downto 0)<="11111111" when "000",
                                     "11111110" when "001",
                                     "11111100" when "010",
                                     "11111000" when "011",
                                     "11110000" when "100",
                                     "11100000" when "101",
                                     "11000000" when "110",
                                     "10000000" when "111";

process(gclk)
begin
  if rising_edge(gclk) then
    if ctrl_rand="100" then
      onehot<=decoder;
    elsif ctrl_rand="001" or ctrl_rand="110" then
      onehot<=(others=>'0');
    end if;
  end if;
end process;

decoder(onehot_width-1+16 downto 16)<=std_logic_vector(('0'&bin_msb)+"00000001");
bin_msb<=binary(bin_width-1 downto bin_width-7);
bin_lsb1<=binary(bin_width-1-7 downto 0);
bin_lsb0<=binary(bin_width-1-7 downto 0);

end x;
