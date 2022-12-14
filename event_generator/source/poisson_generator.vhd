library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity poisson_generator is
generic(rate_mask: natural:= 25770;  -- default rate = 1.5 kHz at 250 MHz clk
init_seed: natural:= 100);
port(gclk,grst: in std_logic;
event_signal: out std_logic);
end entity;
architecture x of poisson_generator is
constant pvalue: unsigned:= to_unsigned(rate_mask,96);
constant seed: natural:= init_seed;
signal lfsr: unsigned(95 downto 0);
signal urnd: unsigned(31 downto 0);
signal evt0,evt1,sel_mode: std_logic;
signal timer: integer range 0 to 4194303;

begin

process(gclk)
begin
  if rising_edge(gclk) then
    if grst='0' then
      lfsr<=to_unsigned(seed,96);
    else
      lfsr(95 downto 32)<=lfsr(63 downto 0);
      for j in 0 to 31 loop
        lfsr(31-j)<=lfsr(95-j) xor lfsr(93-j) xor lfsr(48-j) xor lfsr(46-j);
      end loop;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if grst='0' then
      evt0<='0';
    else
      if urnd<=pvalue then
        evt0<='1';
      else
        evt0<='0';
      end if;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if grst='0' then
      timer<=0;
      evt1<='0';
    else
      if timer=2499999 then
        evt1<='1';
        timer<=0;
      else
        evt1<='0';
        timer<=timer+1;
      end if;
    end if;
  end if;
end process;

sel_mode<='1';
event_signal<=evt0 when (sel_mode='0') else
                       evt1;

urnd<=lfsr(31 downto 0);

end x;
