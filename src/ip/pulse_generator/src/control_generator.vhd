library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_generator is
port(gclk,srst_done,init_done: in std_logic;
event_flag,empty_flag: in std_logic;
hit_pattern: in std_logic_vector (63 downto 0);
rden_drnd,rden_nhits,busy_done: out std_logic;
ctrl_signal: out std_logic_vector (3 downto 0));
end entity;

architecture x of control_generator is
signal nhit_reg0,nhit_reg1,nhits: unsigned (5 downto 0);
constant T0: natural:= 60;
constant T1: natural:= 2;
constant tmax: natural := T0-1;
signal timer: natural range 0 to tmax;

type unsigned_array is array (0 to 64) of unsigned (5 downto 0);
signal nhits_aux: unsigned_array;

type state is (s0,wait_config,start_event,read_fifo0,read_fifo1,read_fifo2,read_nhits,copy_data0,copy_data1,copy_data2,load_sample,dead_time,event_done,clear_register,u0,u1);
signal presente,futuro: state;

begin

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

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      nhit_reg1<=(others=>'0');
    else
      nhit_reg1<=nhit_reg0;
    end if;
  end if;
end process;

process(presente,init_done,event_flag,empty_flag,nhit_reg0,nhit_reg1,nhits,timer)
begin
  rden_nhits<='0';
  rden_drnd<='0';
  busy_done<='0';
  ctrl_signal<="0000";
  nhit_reg0<=(others=>'0');
  case presente is
    when s0=>
      if init_done='1' then
        futuro<=wait_config;
      else
        futuro<=s0;
      end if;
    when wait_config=>
      ctrl_signal<="0001";
      if empty_flag='1' then
        futuro<=start_event;
      else
        futuro<=wait_config;
      end if;
    when start_event=>
      ctrl_signal<="0001";
      if event_flag='1' then
        futuro<=read_fifo0;
      else
        futuro<=start_event;
      end if;
    when read_fifo0=>
      rden_nhits<='1';
      ctrl_signal<="0010";
      futuro<=read_fifo1;
    when read_fifo1=>
      rden_drnd<='1';
      ctrl_signal<="0011";
      nhit_reg0<=nhit_reg1+2;
      futuro<=read_fifo2;
    when read_fifo2=>
      ctrl_signal<="0011";
      nhit_reg0<=nhit_reg1;
      futuro<=read_nhits;
    when read_nhits=>
      ctrl_signal<="0100";
      nhit_reg0<=nhit_reg1;
      if nhit_reg0>=nhits then
        futuro<=copy_data0;
      else
        futuro<=read_fifo1;
      end if;
    when copy_data0=>
      ctrl_signal<="0101";
      futuro<=copy_data1;
    when copy_data1=>
      ctrl_signal<="0101";
      futuro<=copy_data2;
    when copy_data2=>
      ctrl_signal<="0110";
      futuro<=load_sample;
    when load_sample=>
      ctrl_signal<="0111";
      futuro<=dead_time;
    when dead_time=>
      ctrl_signal<="1000";
      if timer>=T0-1 then
        futuro<=event_done;
      else
        futuro<=dead_time;
      end if;
    when event_done=>
      ctrl_signal<="1001";
      futuro<=clear_register;
    when clear_register=>
      busy_done<='1';
      ctrl_signal<="0001";
      if timer>=T1-1 then
        futuro<=wait_config;
      else
        futuro<=clear_register;
      end if;
    when others=>
      futuro<=s0;
  end case;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if srst_done='1' then
      nhits<=(others=>'0');
    else
      nhits<=nhits_aux(64);
    end if;
  end if;
end process;

gen: for j in 1 to 64 generate
  nhits_aux(j)<=nhits_aux(j-1)+1 when (hit_pattern(j-1)='1') else nhits_aux(j-1);
end generate;

nhits_aux(0)<="000000";

end x;
