library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity poisson_generator is
port(gclk,srst_done: in std_logic;
mode: in std_logic_vector (7 downto 0);
seed: in unsigned (7 downto 0);
hab_count: in std_logic_vector (1 downto 0);
rate_mask: in unsigned (31 downto 0);
event_flag: out std_logic);
end entity;
architecture x of poisson_generator is
signal pvalue,fix_rate: unsigned (31 downto 0);
signal lfsr,init_seed: unsigned(95 downto 0);
signal urnd: unsigned(31 downto 0);
signal evt0,evt1: std_logic;
signal timer: unsigned (31 downto 0);

begin

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      lfsr<=init_seed;
    else
      if hab_count="01" then
        lfsr(95 downto 32)<=lfsr(63 downto 0);
        for j in 0 to 31 loop
          lfsr(31-j)<=lfsr(95-j) xor lfsr(93-j) xor lfsr(48-j) xor lfsr(46-j);
        end loop;
      end if;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
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
    if srst_done='1' then
      timer<=(others=>'0');
      evt1<='0';
    else
      if hab_count="10" then
        if timer=fix_rate then
          evt1<='1';
          timer<=(others=>'0');
        else
          evt1<='0';
          timer<=timer+1;
        end if;
      end if;
    end if;
  end if;
end process;

event_flag<=evt0 when (mode="10000111") else
                    evt1 when (mode="10010101") else
                    '0';

pvalue(31 downto 18)<=(others=>'0');
pvalue(17 downto 0)<=rate_mask(17 downto 0);
fix_rate<=rate_mask;
urnd<=lfsr(31 downto 0);
init_seed(95 downto 8)<=(others=>'0');
init_seed(7 downto 0)<=seed;

end x;
