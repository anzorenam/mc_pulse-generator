library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity main_control is
generic(Nch: natural:= 1);
port(gclk,grst: in std_logic;
trigger_signal: in std_logic;
hit_pattern:in std_logic_vector (Nch-1 downto 0);
hit_signal: out std_logic_vector (Nch-1 downto 0));
end main_control;

architecture x of main_control is
type state is (init,wait_trigger,dead_time,done);
signal presente,futuro: state;
constant T0: natural := 128;
constant T1: natural := 10;
constant tmax: natural := T0-1;
signal timer: natural range 0 to tmax;

begin

process(gclk)
begin
  if rising_edge(gclk) then
    if grst='0' then
      presente<=init;
    else
      presente<=futuro;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if grst='0' then
      timer<=0;
    else
      if presente/=futuro then
        timer<=0;
      elsif timer/=tmax then
        timer<=timer+1;
      end if;
    end if;
  end if;
end process;

process(presente,trigger_signal,hit_pattern,timer)
begin
  hit_signal<=(others=>'0');
  case presente is
    when init=>
      futuro<=wait_trigger;
    when wait_trigger=>
      if trigger_signal='1' then
        futuro<=dead_time;
      else
        futuro<=wait_trigger;
      end if;
    when dead_time=>
      hit_signal<=hit_pattern;
      if timer>=T0-1 then
        futuro<=done;
      else
        futuro<=dead_time;
      end if;
    when done=>
      hit_signal<=hit_pattern;
      if timer>=T1-1 then
        futuro<=wait_trigger;
      else
        futuro<=done;
      end if;
  end case;
end process;

end x;
