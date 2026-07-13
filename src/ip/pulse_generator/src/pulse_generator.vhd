library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;

entity pulse_generator is
port(gclk,grst: in std_logic;
srst_done,init_done,evt_flag: in std_logic;
rden_urnd,wren_drnd,wren_nhits: in std_logic;
seed: in std_logic_vector (23 downto 0);
time_drnd,hitp_drnd: in std_logic_vector (31 downto 0);
busy_done,empty_flag,empty_urnd,full_drnd,full_nhits: out std_logic;
address_urnd: out std_logic_vector (31 downto 0);
pulse_signal: out std_logic_vector (63 downto 0));
end entity;

architecture x of pulse_generator is
signal gclk_aux0,p0,p1,p2,p3: std_logic;
signal wren_urnd,rden_drnd,rden_nhits: std_logic;
signal full_urnd,empty_faux,empty_drnd,empty_nhits: std_logic;
signal urnd_addr: std_logic_vector (15 downto 0);
signal timing_dist,timing_aux0: std_logic_vector (31 downto 0);
signal hit_pattern: std_logic_vector (63 downto 0);
signal ctrl_signal: std_logic_vector (3 downto 0);
signal data_ch0,data_ch1: unsigned (9 downto 0);
signal chid0,chid1: unsigned (5 downto 0);

type timing_array is array (63 downto 0) of unsigned (9 downto 0);
signal time_aux0,time_aux1,time_bin: timing_array;
type onehot_array is array (63 downto 0) of std_logic_vector (23 downto 0);
signal time_onehot: onehot_array;

component clkgen is
port(clk_in1: in std_logic;
clk_out1,clk_out2,clk_out3,clk_out4: out std_logic);
end component;

component control_generator is
port(gclk,srst_done,init_done: in std_logic;
event_flag,empty_flag: in std_logic;
hit_pattern: in std_logic_vector (63 downto 0);
rden_drnd,rden_nhits,busy_done: out std_logic;
ctrl_signal: out std_logic_vector (3 downto 0));
end component;

component urnd_generator is
port(gclk,full_urnd: in std_logic;
seed: in std_logic_vector (23 downto 0);
ctrl_signal: in std_logic_vector (3 downto 0);
wren_urnd: out std_logic;
urnd: out std_logic_vector (15 downto 0));
end component;

component fifo_urnd is
port(clk,srst,wr_en,rd_en: in std_logic;
din: in std_logic_vector (15 downto 0);
full,empty: out std_logic;
wr_rst_busy,rd_rst_busy: out std_logic;
dout: out std_logic_vector (31 downto 0));
end component;

component fifo_drnd is
port(clk,srst,wr_en,rd_en: in std_logic;
din: in std_logic_vector (31 downto 0);
full,empty: out std_logic;
wr_rst_busy,rd_rst_busy: out std_logic;
dout: out std_logic_vector (31 downto 0));
end component;

component fifo_nhits is
port(clk,srst,wr_en,rd_en: in std_logic;
din: in std_logic_vector (31 downto 0);
full,empty: out std_logic;
wr_rst_busy,rd_rst_busy: out std_logic;
dout: out std_logic_vector (63 downto 0));
end component;

component bin_onehot is
port(gclk,gen_sel: std_logic;
ctrl_signal: std_logic_vector (3 downto 0);
binary: in unsigned (9 downto 0);
onehot: out std_logic_vector (23 downto 0));
end component;

component pulse_delay is
port (p0,p1,p2,p3: in std_logic;
ctrl_signal: in std_logic_vector (3 downto 0);
w_pat: in std_logic_vector (23 downto 0);
pulse_out: out std_logic);
end component;

begin

clk_gen: clkgen
port map(clk_in1=>gclk_aux0,
         clk_out1=>p0,
         clk_out2=>p1,
         clk_out3=>p2,
         clk_out4=>p3
);

control: control_generator
port map(gclk=>gclk,
         srst_done=>srst_done,
         init_done=>init_done,
         event_flag=>evt_flag,
         empty_flag=>empty_faux,
         hit_pattern=>hit_pattern,
         rden_drnd=>rden_drnd,
         rden_nhits=>rden_nhits,
         busy_done=>busy_done,
         ctrl_signal=>ctrl_signal
);

urand: urnd_generator
port map(gclk=>gclk,
         full_urnd=>full_urnd,
         seed=>seed,
         ctrl_signal=>ctrl_signal,
         wren_urnd=>wren_urnd,
         urnd=>urnd_addr
);

urnd_m: fifo_urnd
port map(clk=>gclk,
         srst=>grst,
         din=>urnd_addr,
         wr_en=>wren_urnd,
         rd_en=>rden_urnd,
         full=>full_urnd,
         empty=>empty_urnd,
         wr_rst_busy=>open,
         rd_rst_busy=>open,
         dout=>address_urnd
);

drnd_m: fifo_drnd
port map(clk=>gclk,
         srst=>grst,
         din=>time_drnd,
         wr_en=>wren_drnd,
         rd_en=>rden_drnd,
         full=>full_drnd,
         empty=>empty_drnd,
         wr_rst_busy=>open,
         rd_rst_busy=>open,
         dout=>timing_dist
);

nhits_m: fifo_nhits
port map(clk=>gclk,
         srst=>grst,
         din=>hitp_drnd,
         wr_en=>wren_nhits,
         rd_en=>rden_nhits,
         full=>full_nhits,
         empty=>empty_nhits,
         wr_rst_busy=>open,
         rd_rst_busy=>open,
         dout=>hit_pattern
);

gen_channels:
for j in 0 to 63 generate
  gen_deco: bin_onehot
    port map(gclk=>gclk,
             gen_sel=>hit_pattern(j),
             ctrl_signal=>ctrl_signal,
             binary=>time_bin(j),
             onehot=>time_onehot(j)
  );

  gen_delay: pulse_delay
  port map(p0=>p0,
           p1=>p1,
           p2=>p2,
           p3=>p3,
           ctrl_signal=>ctrl_signal,
           w_pat=>time_onehot(j),
           pulse_out=>pulse_signal(j)
);

end generate;

clkbuf: BUFGCE
generic map(CE_TYPE=>"SYNC")
port map(O=>gclk_aux0,CE=>'1',I=>gclk);

process(gclk)
begin
  if rising_edge(gclk) then
    if ctrl_signal="0100" then
      for j in 0 to 63 loop
        if j=chid0 then
          time_aux0(j)<=data_ch0;
        else
          time_aux0(j)<=time_aux0(j);
        end if;
      end loop;
    else
      if ctrl_signal="0000" or ctrl_signal="1001" then
        for j in 0 to 63 loop
          time_aux0(j)<=(others=>'0');
        end loop;
      end if;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if ctrl_signal="0100" then
      for k in 0 to 63 loop
        if k=chid1 then
          time_aux1(k)<=data_ch1;
        else
          time_aux1(k)<=time_aux1(k);
        end if;
      end loop;
    else
      if ctrl_signal="0000" or ctrl_signal="1001" then
        for k in 0 to 63 loop
          time_aux1(k)<=(others=>'0');
        end loop;
      end if;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if ctrl_signal="0101" then
      for m in 0 to 63 loop
        time_bin(m)<=time_aux0(m) or time_aux1(m);
      end loop;
    else
      if ctrl_signal="0000" or ctrl_signal="1001" then
        for m in 0 to 63 loop
          time_bin(m)<=(others=>'0');
        end loop;
      end if;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    empty_faux<=not(empty_nhits) and not(empty_drnd);
  end if;
end process;

empty_flag<=empty_faux;
data_ch1<=unsigned(timing_dist(25 downto 16));
data_ch0<=unsigned(timing_dist(9 downto 0));
chid1<=unsigned(timing_dist(31 downto 26));
chid0<=unsigned(timing_dist(15 downto 10));

end x;
