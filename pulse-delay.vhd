library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pulse_delay is
generic(onehot_width: natural:= 128);
port (p0,p1,p2,p3: in std_logic;
make_delay: in std_logic;
ctrl_rand: in std_logic_vector (2 downto 0);
w_pattern: in std_logic_vector (onehot_width-1+8 downto 0);
pulse_out: out std_logic);
end entity;

architecture x of pulse_delay is
signal Tsync,main_capture,local_rst: std_logic;
signal capture0,capture1,capture2,capture3: std_logic;
signal capture4,capture5,capture6,capture7: std_logic;
signal slow_sampling,wmask1,wp1,c_pat1: std_logic_vector (onehot_width-1 downto 0);
signal delay: std_logic_vector (4 downto 0);
signal sampling_regs,sampling_code,wmask0,wp0,c_pat0: std_logic_vector (7 downto 0);
signal sampling_reg0,sampling_reg1,sampling_reg2,sampling_reg3: std_logic;
signal sampling_reg4,sampling_reg5,sampling_reg6,sampling_reg7: std_logic;
begin

process(p0,local_rst)
begin
  if rising_edge(p0) then
    if local_rst='1' then
      slow_sampling(onehot_width-1 downto 1)<=(others=>'0');
      slow_sampling(0)<='1';
    else
      if make_delay='1' then
        slow_sampling(0)<=slow_sampling(onehot_width-1);
        for j in 1 to onehot_width-1 loop
          slow_sampling(j)<=slow_sampling(j-1);
        end loop;
      end if;
    end if;
  end if;
end process;

process(p0)
begin
  if rising_edge(p0) then
    if local_rst='1' then
      sampling_reg0<='1';
    else
      if make_delay='1' then
        sampling_reg0<=not(sampling_reg7);
      end if;
    end if;
  end if;
end process;

process(p1)
begin
  if rising_edge(p1) then
    if local_rst='1' then
      sampling_reg1<='0';
    else
      if make_delay='1' then
        sampling_reg1<=sampling_reg0;
      end if;
    end if;
  end if;
end process;

process(p2)
begin
  if rising_edge(p2) then
    if local_rst='1' then
      sampling_reg2<='0';
    else
      if make_delay='1' then
        sampling_reg2<=sampling_reg1;
      end if;
    end if;
  end if;
end process;

process(p3)
begin
  if rising_edge(p3) then
    if local_rst='1' then
      sampling_reg3<='0';
    else
      if make_delay='1' then
        sampling_reg3<=sampling_reg2;
      end if;
    end if;
  end if;
end process;

process(p0)
begin
  if falling_edge(p0) then
    if local_rst='1' then
      sampling_reg4<='0';
    else
      if make_delay='1' then
        sampling_reg4<=sampling_reg3;
      end if;
    end if;
  end if;
end process;

process(p1)
begin
  if falling_edge(p1) then
    if local_rst='1' then
      sampling_reg5<='0';
    else
      if make_delay='1' then
        sampling_reg5<=sampling_reg4;
      end if;
    end if;
  end if;
end process;

process(p2)
begin
  if falling_edge(p2) then
    if local_rst='1' then
      sampling_reg6<='0';
    else
      if make_delay='1' then
        sampling_reg6<=sampling_reg5;
      end if;
    end if;
  end if;
end process;

process(p3)
begin
  if falling_edge(p3) then
    if local_rst='1' then
      sampling_reg7<='0';
    else
      if make_delay='1' then
        sampling_reg7<=sampling_reg6;
      end if;
    end if;
  end if;
end process;

process(p0)
begin
  if rising_edge(p0) then
    if local_rst='1' then
      capture0<='0';
    else
      if Tsync='1' then
        capture0<='1';
      end if;
    end if;
  end if;
end process;

process(p1)
begin
  if rising_edge(p1) then
    if local_rst='1' then
      capture1<='0';
    else
      if Tsync='1' then
        capture1<='1';
      end if;
    end if;
  end if;
end process;

process(p2)
begin
  if rising_edge(p2) then
    if local_rst='1' then
      capture2<='0';
    else
      if Tsync='1' then
        capture2<='1';
      end if;
    end if;
  end if;
end process;

process(p3)
begin
  if rising_edge(p3) then
    if local_rst='1' then
      capture3<='0';
    else
      if Tsync='1' then
        capture3<='1';
      end if;
    end if;
  end if;
end process;

process(p0)
begin
  if falling_edge(p0) then
    if local_rst='1' then
      capture4<='0';
    else
      if Tsync='1' then
        capture4<='1';
      end if;
    end if;
  end if;
end process;

process(p1)
begin
  if falling_edge(p1) then
    if local_rst='1' then
      capture5<='0';
    else
      if Tsync='1' then
        capture5<='1';
      end if;
    end if;
  end if;
end process;

process(p2)
begin
  if falling_edge(p2) then
    if local_rst='1' then
      capture6<='0';
    else
      if Tsync='1' then
        capture6<='1';
      end if;
    end if;
  end if;
end process;

process(p3)
begin
  if falling_edge(p3) then
    if local_rst='1' then
      capture7<='0';
    else
      if Tsync='1' then
        capture7<='1';
      end if;
    end if;
  end if;
end process;

process(p0)
begin
  if rising_edge(p0) then
    if local_rst='1' then
      delay<="00000";
    else
      delay(0)<=main_capture;
      delay(1)<=delay(0);
      delay(2)<=delay(1);
      delay(3)<=delay(2);
      delay(4)<=delay(3);
    end if;
  end if;
end process;


with sampling_regs select
  sampling_code<="00000001" when "00000001",
                 "00000010" when "00000011",
                 "00000100" when "00000111",
                 "00001000" when "00001111",
                 "00010000" when "00011111",
                 "00100000" when "00111111",
                 "01000000" when "01111111",
                 "10000000" when "11111111",
                 "00000001" when "11111110",
                 "00000010" when "11111100",
                 "00000100" when "11111000",
                 "00001000" when "11110000",
                 "00010000" when "11100000",
                 "00100000" when "11000000",
                 "01000000" when "10000000",
                 "10000000" when "00000000",
                 "00000000" when others;

sampling_regs<=(sampling_reg7 & sampling_reg6 & sampling_reg5 & sampling_reg4 & sampling_reg3 & sampling_reg2 & sampling_reg1 & sampling_reg0);
wmask0<=sampling_code;
wmask1<=slow_sampling;

c_pat1<=wp1 and wmask1 when (local_rst='0' and make_delay='1') else
           (others=>'0');

c_pat0<=wp0 and wmask0 when (local_rst='0' and make_delay='1') else
           (others=>'0');

Tsync<='0' when (local_rst='1') else
       '0' when (make_delay='0') else
       '1' when (c_pat1/=(c_pat1'range=>'0') and c_pat0/="00000000") else
       '0';

local_rst<='1' when (ctrl_rand="001" or ctrl_rand="101") else
           '0';

main_capture<=capture0 or capture1 or capture2 or capture3 or capture4 or capture5 or capture6 or capture7;
pulse_out<=main_capture and not(delay(4));
wp1<=w_pattern(onehot_width-1+8 downto 8);
wp0<=w_pattern(7 downto 0);

end x;
