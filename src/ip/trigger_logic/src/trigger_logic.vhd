library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity trigger_logic is
port(gclk,srst_done: in std_logic;
clear_reg0,clear_reg1,event_flag:in std_logic;
any_thrs: in std_logic_vector (7 downto 0);
gwidth: in std_logic_vector (15 downto 0);
pulse_signal: in std_logic_vector (63 downto 0);
event_rate,trigger_rate: out std_logic_vector (31 downto 0));
end entity;

architecture x of trigger_logic is
signal evt_sync0,evt_sync1,evt_sync2,evt_sync3: std_logic;
signal trg_sync0,trg_sync1,trg_sync2: std_logic;
signal trg_sync3,trg_sync4,trg_sync5: std_logic;
signal evt_valid,trg_valid,any_trigger: std_logic;
signal usum0,usum1,usum2,usum3: unsigned (4 downto 0);
signal total_sum,sum_threshold: unsigned (7 downto 0);
signal counts0,counts1: unsigned (31 downto 0);
signal pulse_sync,sd_oneshot: std_logic_vector (63 downto 0);
signal timer,gate_width: unsigned (16 downto 0);

type pwidth_array is array (0 to 63) of std_logic_vector (15 downto 0);
signal pwidth: pwidth_array;

type partsum_array is array (0 to 16) of unsigned (4 downto 0);
signal part_sum0,part_sum1,part_sum2,part_sum3: partsum_array;

component one_shot is
port(gclk,srst_done: in std_logic;
evt_signal: in std_logic;
gwidth: in std_logic_vector (15 downto 0);
gate_signal: out std_logic);
end component;

begin

gen_syncs:
for j in 0 to 63 generate
  gate_sync: one_shot
  port map(gclk=>gclk,
           srst_done=>sd_oneshot(j),
           evt_signal=>pulse_signal(j),
           gwidth=>pwidth(j),
           gate_signal=>pulse_sync(j)
  );
end generate;

process(gclk)
begin
  if rising_edge(gclk) then
    for j in 0 to 63 loop
      sd_oneshot(j)<=srst_done;
      pwidth(j)<=gwidth;
    end loop;
  end if;
end process;

gensum0:
for j in 1 to 16 generate
  part_sum0(j)<=part_sum0(j-1)+1 when (pulse_sync(j-1)='1') else part_sum0(j-1);
end generate;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      usum0<=(others=>'0');
    else
      usum0<=part_sum0(16);
    end if;
  end if;
end process;

gensum1:
for j in 1 to 16 generate
  part_sum1(j)<=part_sum1(j-1)+1 when (pulse_sync(j+15)='1') else part_sum1(j-1);
end generate;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      usum1<=(others=>'0');
    else
      usum1<=part_sum1(16);
    end if;
  end if;
end process;

gensum2:
for j in 1 to 16 generate
  part_sum2(j)<=part_sum2(j-1)+1 when (pulse_sync(j+31)='1') else part_sum2(j-1);
end generate;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      usum2<=(others=>'0');
    else
      usum2<=part_sum2(16);
    end if;
  end if;
end process;

gensum3:
for j in 1 to 16 generate
  part_sum3(j)<=part_sum3(j-1)+1 when (pulse_sync(j+47)='1') else part_sum3(j-1);
end generate;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      usum3<=(others=>'0');
    else
      usum3<=part_sum3(16);
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      counts0<=(others=>'0');
    else
      if clear_reg0='0' then
        if evt_valid='1' then
          counts0<=counts0+1;
        else
          counts0<=counts0;
        end if;
      else
        counts0<=(others=>'0');
      end if;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      counts1<=(others=>'0');
    else
      if clear_reg1='0' then
        if trg_valid='1' then
          counts1<=counts1+1;
        else
          counts1<=counts1;
        end if;
      else
        counts1<=(others=>'0');
      end if;
    end if;
  end if;
end process;

process(event_flag,evt_sync2)
begin
  if evt_sync2='1' then
    evt_sync0<='0';
  else
    if rising_edge(event_flag) then
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
      evt_sync3<='0';
    else
      evt_sync1<=evt_sync0;
      evt_sync2<=evt_sync1;
      evt_sync3<=evt_sync2;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      timer<=(others=>'0');
    else
      if trg_sync2='1' then
        timer<=timer+1;
      else
        timer<=(others=>'0');
      end if;
    end if;
  end if;
end process;

process(any_trigger,trg_sync3)
begin
  if trg_sync3='1' then
    trg_sync0<='0';
  else
    if rising_edge(any_trigger) then
      trg_sync0<='1';
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      trg_sync1<='0';
      trg_sync2<='0';
      trg_sync4<='0';
      trg_sync5<='0';
    else
      trg_sync1<=trg_sync0;
      trg_sync2<=trg_sync1;
      trg_sync4<=trg_sync3;
      trg_sync5<=trg_sync4;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      trg_sync3<='0';
    else
      if timer=gate_width then
        trg_sync3<='1';
      else
        trg_sync3<='0';
      end if;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      any_trigger<='0';
    else
      if total_sum>sum_threshold then
        any_trigger<='1';
      else
        any_trigger<='0';
      end if;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      total_sum<=(others=>'0');
    else
      total_sum<=resize(usum3,8)+resize(usum2,8)+resize(usum1,8)+resize(usum0,8);
    end if;
  end if;
end process;

evt_valid<=evt_sync2 and not(evt_sync3);
trg_valid<=trg_sync4 and not(trg_sync5);
part_sum0(0)<=(others=>'0');
part_sum1(0)<=(others=>'0');
part_sum2(0)<=(others=>'0');
part_sum3(0)<=(others=>'0');

sum_threshold<=unsigned(any_thrs);
event_rate<=std_logic_vector(counts0);
trigger_rate<=std_logic_vector(counts1);
gate_width<=unsigned(gwidth) & '0';

end x;
