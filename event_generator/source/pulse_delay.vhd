library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pulse_delay is
generic(onehot_width: natural:= 8);
port (p0,p1,p2,p3: in std_logic;
make_delay: in std_logic;
ctrl_rand: in std_logic_vector (2 downto 0);
w_pattern: in std_logic_vector (onehot_width-1+16 downto 0);
pulse_out: out std_logic);
end entity;

architecture x of pulse_delay is
signal Tsync,c_pat2,capture,local_rst: std_logic;
signal wmask1,wp2: unsigned (onehot_width-1 downto 0);
signal delay: std_logic_vector (1 downto 0);
signal sampling_regs,sampling_code,wmask0,wp0,wp1,c_pat1,c_pat0: std_logic_vector (7 downto 0);
signal sampling_reg0,sampling_reg1,sampling_reg2,sampling_reg3: std_logic;
signal sampling_reg4,sampling_reg5,sampling_reg6,sampling_reg7: std_logic;
begin

process(p0)
begin
  if rising_edge(p0) then
    if local_rst='1' then
      wmask1(onehot_width-1 downto 1)<=(others=>'0');
      wmask1(0)<='1';
    else
      if make_delay='1' then
        wmask1<=wmask1-1;
      else
        if ctrl_rand="101" then
          wmask1<=wp2;
        end if;
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

process(Tsync,local_rst)
begin
  if local_rst='1' then
    capture<='0';
  else
    if rising_edge(Tsync) then
      capture<='1';
    end if;
  end if;
end process;

process(p0)
begin
  if rising_edge(p0) then
    if local_rst='1' then
      delay<="00";
    else
      delay(0)<=capture;
      delay(1)<=delay(0);
    end if;
  end if;
end process;

wmask0<=(sampling_reg7 & sampling_reg6 & sampling_reg5 & sampling_reg4 & sampling_reg3 & sampling_reg2 & sampling_reg1 & sampling_reg0);

c_pat2<='1' when (local_rst='0' and make_delay='1' and wmask1="0000000") else
              '0';

c_pat1<=wp1 and wmask0 when (local_rst='0' and make_delay='1') else
              (others=>'0');

c_pat0<=wp0 and wmask0 when (local_rst='0' and make_delay='1') else
              (others=>'0');

Tsync<='0' when (local_rst='1') else
             '0' when (make_delay='0') else
             '1' when (c_pat2='1' and (c_pat1/="00000000" or c_pat0/="00000000")) else
             '0';

local_rst<='1' when (ctrl_rand="001" or ctrl_rand="110") else
                 '0';

pulse_out<=capture and not(delay(1));
wp2<=unsigned(w_pattern(onehot_width-1+16 downto 16));
wp1<=w_pattern(15 downto 8);
wp0<=w_pattern(7 downto 0);

end x;
