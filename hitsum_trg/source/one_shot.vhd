library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity one_shot is
generic(pwidth: natural:= 20);
port(gclk,grst: in std_logic;
hit_async: in std_logic;
hit_wsync: out std_logic);
end entity;

architecture x of one_shot is
type state is (init,wait_hit,wait_timer,u0);
signal presente,futuro: state;
signal local_rst,hsync0,hsync1: std_logic;
signal dff0,dff1,dff2,dff3: std_logic;
constant T0: natural:= pwidth-1;
signal timer: natural range 0 to T0;
begin

process(gclk)
begin
  if rising_edge(gclk) then
    if grst='1' then
      presente<=init;
    else
      presente<=futuro;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if grst='1' then
      timer<=0;
    else
      if presente/=futuro then
        timer<=0;
      elsif timer/=T0 then
        timer<=timer+1;
      end if;
    end if;
  end if;
end process;

process(presente,hsync0,timer)
begin
  hsync1<='0';
  case presente is
    when init=>
      futuro<=wait_hit;
    when wait_hit=>
      if hsync0='1' then
        futuro<=wait_timer;
      else
        futuro<=wait_hit;
      end if;
    when wait_timer=>
      hsync1<='1';
      if timer>=T0 then
        futuro<=wait_hit;
      else
        futuro<=wait_timer;
      end if;
    when others=>
      futuro<=init;
  end case;
end process;

process(hit_async,local_rst)
begin
  if local_rst='1' then
    dff0<='0';
  else
    if rising_edge(hit_async) then
      dff0<='1';
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    dff1<=dff0;
    dff2<=dff1;
    dff3<=dff2;
  end if;
end process;

hit_wsync<=hsync1;
hsync0<=dff2 and not(dff3);
local_rst<=grst or dff2;

end x;
