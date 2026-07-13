library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity poisson_generator is
port(gclk,srst_done,init_done,busy_done,empty_flag: in std_logic;
mode: in std_logic_vector (7 downto 0);
seed: in std_logic_vector (23 downto 0);
rate_mask: in std_logic_vector (31 downto 0);
event_flag: out std_logic);
end entity;

architecture x of poisson_generator is
signal hab_count: std_logic_vector (1 downto 0);
signal pvalue,fix_rate: unsigned (31 downto 0);
signal lfsr,init_seed: unsigned(95 downto 0);
signal urnd: unsigned(31 downto 0);
signal evt0,evt1: std_logic;
constant T0: natural:= 2;
constant tmax: natural := T0-1;
signal time0: natural range 0 to tmax;
signal time1: unsigned (31 downto 0);

type state is (s0,config_done,sel_mode,wevt0,wevt1,start_event,wait_sync,u0);
signal presente,futuro: state;

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
      if hab_count="01" then
        if urnd<=pvalue then
          evt0<='1';
        else
          evt0<='0';
        end if;
      end if;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      time1<=(others=>'0');
      evt1<='0';
    else
      if hab_count="10" then
        if time1=fix_rate then
          evt1<='1';
          time1<=(others=>'0');
        else
          evt1<='0';
          time1<=time1+1;
        end if;
      end if;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      presente<=s0;
    else
      presente<=futuro;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      time0<=0;
    else
      if presente/=futuro then
        time0<=0;
      elsif time0/=tmax then
        time0<=time0+1;
      end if;
    end if;
  end if;
end process;

process(presente,init_done,empty_flag,mode,evt0,evt1,time0,busy_done)
begin
  hab_count<="00";
  event_flag<='0';
  case presente is
    when s0=>
      if init_done='1' then
        futuro<=config_done;
      else
        futuro<=s0;
      end if;
    when config_done=>
      if empty_flag='1' then
        futuro<=sel_mode;
      else
        futuro<=config_done;
      end if;
    when sel_mode=>
      if mode="10000111" then
        futuro<=wevt0;
      elsif mode="10010101" then
        futuro<=wevt1;
      else
        futuro<=sel_mode;
      end if;
    when wevt0=>
      hab_count<="01";
      if evt0='1' then
        futuro<=start_event;
      else
        futuro<=wevt0;
      end if;
    when wevt1=>
      hab_count<="10";
      if evt1='1' then
        futuro<=start_event;
      else
        futuro<=wevt1;
      end if;
    when start_event=>
      event_flag<='1';
      if time0>=T0-1 then
        futuro<=wait_sync;
      else
        futuro<=start_event;
      end if;
    when wait_sync=>
      if busy_done='1' then
        futuro<=sel_mode;
      else
        futuro<=wait_sync;
      end if;
    when others=>
      futuro<=s0;
  end case;
end process;

pvalue(31 downto 24)<=(others=>'0');
pvalue(23 downto 0)<=unsigned(rate_mask(23 downto 0));
fix_rate<=unsigned(rate_mask);
urnd<=lfsr(31 downto 0);
init_seed(95 downto 24)<=(others=>'0');
init_seed(23 downto 0)<=unsigned(seed);

end x;
