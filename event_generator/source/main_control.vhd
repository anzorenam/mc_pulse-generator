library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity main_control is
generic(Nch: natural:= 1);
port(gclk,grst: in std_logic;
event_signal: in std_logic;
hit_pattern:in std_logic_vector (Nch-1 downto 0);
e_valid: out std_logic;
hit_signal: out std_logic_vector (Nch-1 downto 0));
end main_control;

architecture x of main_control is
type state is (init,wait_event,valid_event,delay_pulse,dead_time,u0,u1,u2);
signal presente,futuro: state;
constant T0: natural:= 2;
constant T1: natural:= 123;
constant T2: natural:= 900;
constant tmax: natural := T2-1;
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

process(presente,event_signal,hit_pattern,timer)
begin
  hit_signal<=(others=>'0');
  e_valid<='0';
  case presente is
    when init=>
      futuro<=wait_event;
    when wait_event=>
      if event_signal='1' then
        futuro<=valid_event;
      else
        futuro<=wait_event;
      end if;
    when valid_event=>
      hit_signal<=hit_pattern;
      e_valid<='1';
      if timer>=T0-1 then
        futuro<=delay_pulse;
      else
        futuro<=valid_event;
      end if;
    when delay_pulse=>
      hit_signal<=hit_pattern;
      if timer>=T1-1 then
        futuro<=dead_time;
      else
        futuro<=delay_pulse;
      end if;
    when dead_time=>
      if timer>=T2-1 then
        futuro<=wait_event;
      else
        futuro<=dead_time;
      end if;
    when others=>
      futuro<=init;
  end case;
end process;

end x;
