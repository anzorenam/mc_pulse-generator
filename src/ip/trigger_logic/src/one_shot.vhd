library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity one_shot is
port(gclk,srst_done: in std_logic;
evt_signal: in std_logic;
gwidth: in std_logic_vector (15 downto 0);
gate_signal: out std_logic);
end entity;

architecture x of one_shot is
signal evt_sync0,evt_sync1,evt_sync2: std_logic;
signal evt_sync3,evt_sync4,evt_sync5: std_logic;
signal timer,gate_width: unsigned (15 downto 0);
begin

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      timer<=(others=>'0');
    else
      if evt_sync2='1' then
        timer<=timer+1;
      else
        timer<=(others=>'0');
      end if;
    end if;
  end if;
end process;

process(evt_signal,evt_sync3)
begin
  if evt_sync3='1' then
    evt_sync0<='0';
  else
    if rising_edge(evt_signal) then
      evt_sync0<='1';
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      evt_sync1<='0';
      evt_sync2<='0';
      evt_sync4<='0';
      evt_sync5<='0';
    else
      evt_sync1<=evt_sync0;
      evt_sync2<=evt_sync1;
      evt_sync4<=evt_sync3;
      evt_sync5<=evt_sync4;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      evt_sync3<='0';
    else
      if timer=gate_width then
        evt_sync3<='1';
      else
        evt_sync3<='0';
      end if;
    end if;
  end if;
end process;

gate_signal<=evt_sync2 and not(evt_sync5);
gate_width<=unsigned(gwidth);

end x;
