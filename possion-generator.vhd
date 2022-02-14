library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity poisson_generator is
generic(rate_mask: natural:= 25770;  -- default rate = 1.5 kHz at 250 MHz clk
init_seed: natural:= 100);
port(gclk,grst: in std_logic;
make_event: out std_logic);
end entity;
architecture x of poisson_generator is
constant pvalue: unsigned:= to_unsigned(rate_mask,96);
constant seed: natural:= init_seed;
signal lfsr: unsigned(95 downto 0);
signal urnd: unsigned(31 downto 0);
signal event_aux: std_logic;
begin

process(gclk,grst)
begin
  if grst='0' then
    lfsr<=to_unsigned(seed,96);
  else
    if rising_edge(gclk) then
      lfsr(95 downto 32)<=lfsr(63 downto 0);
      for j in 0 to 31 loop
        lfsr(31-j)<=lfsr(95-j) xor lfsr(93-j) xor lfsr(48-j) xor lfsr(46-j);
      end loop;
    end if;
  end if;
end process;

process(gclk,grst)
begin
  if grst='0' then
    event_aux<='0';
  else
    if rising_edge(gclk) then
      if urnd<=pvalue then
        event_aux<='1';
      else
        event_aux<='0';
      end if;
    end if;
  end if;
end process;

make_event<=event_aux;
urnd<=lfsr(31 downto 0);

end x;
