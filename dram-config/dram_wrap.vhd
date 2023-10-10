library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;

entity dram_wrap is
generic(ddr3_dq_width: natural:= 16;
ddr3_dqs_width: natural:= 2;
ddr3_addr_width: natural:= 14;
ddr3_ba_width: natural:= 3;
ddr3_dm_width: natural:= 2;
app_addr_width: natural:= 28;
app_cmd_width: natural:= 3;
app_data_width: natural:= 128;
app_mask_width: natural:= 16);
port(sys_clk,ref_clk,gclk: in std_logic;
dram_rst,local_rst,init_done: in std_logic;
sitcp_rden,tcp_rx: in std_logic;
din_tcp: in std_logic_vector (7 downto 0);
mig_ui_clk,mig_ui_rst,tcp_tx,empty: out std_logic;
wr_data_count: out std_logic_vector (11 downto 0);
dout_tcp: out std_logic_vector (7 downto 0);
ddr3_dq: inout std_logic_vector (ddr3_dq_width-1 downto 0);
ddr3_dqs_n,ddr3_dqs_p: inout std_logic_vector (ddr3_dqs_width-1 downto 0);
ddr3_addr: out std_logic_vector (ddr3_addr_width-1 downto 0);
ddr3_ba: out std_logic_vector (ddr3_ba_width-1 downto 0);
ddr3_ras_n,ddr3_cas_n,ddr3_we_n,ddr3_reset_n: out std_logic;
ddr3_ck_p,ddr3_ck_n,ddr3_cke,ddr3_cs_n,ddr3_odt: out std_logic_vector (0 downto 0);
ddr3_dm: out std_logic_vector (ddr3_dm_width-1 downto 0));
end entity;

architecture x of dram_wrap is
constant A0: natural:= 4096;
constant T0: natural := 20;
constant T1: natural := 7;
signal dram_wen,dram_ren,reg_wen0,reg_wen1: std_logic;
signal ui_clk,ui_rst: std_logic;
signal tcp_send,full_tcp,almost_tcp,empty_tcp: std_logic;
signal write_ack,full_dram,almost_dram,empty_dram: std_logic;
signal full_sync,empty_sync: std_logic;
signal din_parallel,dout_parallel: std_logic_vector (102 downto 0);
signal din_stcp,dram_dout,dram_data: std_logic_vector (63 downto 0);
signal addr_reg0,addr_reg1: unsigned (app_addr_width-5 downto 0);
signal addr_reg2,addr_reg3: unsigned (app_addr_width-5 downto 0);
signal full_addr0,full_addr1: unsigned (app_addr_width-1 downto 0);
signal dram_addr: std_logic_vector (app_addr_width-1 downto 0);
signal dram_mask,data_mask: std_logic_vector (app_mask_width-1 downto 0);
signal dram_init_calib_complete,calib_complete: std_logic;
signal dram_ready,dram_wdf_ready: std_logic;
signal dram_wbusy,dram_rbusy: std_logic;
signal valid_dram: std_logic;
signal cross_trg0,cross_trg1,cross_ack0,cross_ack1: std_logic;
signal timer: natural range 0 to 31;

type state0 is (calib,init_start,tcp_write,wait_nempty,fifo_write,count_loop,end_transmission,u0);
signal presente,futuro: state0;
attribute fsm_encoding : string;
attribute fsm_encoding of presente: signal is "sequential";
attribute fsm_encoding of futuro: signal is "sequential";

type state1  is (calib,init_start,wait_ack,delay_read,dram_read,dram_busy,dram_finish,end_transmission);
signal pasado,actual: state1;
attribute fsm_encoding of pasado: signal is "sequential";
attribute fsm_encoding of actual: signal is "sequential";

component ila_0 is
port(clk: in std_logic;
trig_out: out std_logic;
trig_out_ack : in std_logic;
trig_in : in std_logic;
trig_in_ack : out std_logic;
probe0 : in std_logic_vector (25 downto 0);
probe1 : in std_logic_vector (0 to 0);
probe2 : in std_logic_vector (0 to 0);
probe3 : in std_logic_vector (0 to 0));

end component;

component ila_1 is
port(clk: in std_logic;
trig_out: out std_logic;
trig_out_ack: in std_logic;
trig_in : in std_logic;
trig_in_ack : out std_logic;
probe0 : in std_logic_vector (25 downto 0);
probe1 : in std_logic_vector (0 to 0);
probe2 : in std_logic_vector (0 to 0);
probe3 : in std_logic_vector (0 to 0);
probe4 : in std_logic_vector (0 to 0));
end component;

component fifosync is
port(clk,srst,wr_en,rd_en: in std_logic;
din: in std_logic_vector (7 downto 0);
full,empty: out std_logic;
wr_data_count: out std_logic_vector (11 downto 0);
dout: out std_logic_vector (63 downto 0));
end component;

component fifotcp is
port(wr_clk,rd_clk,rst,wr_en,rd_en: in std_logic;
din: in std_logic_vector (102 downto 0);
full,almost_full,empty,valid: out std_logic;
dout: out std_logic_vector (102 downto 0));
end component;

component fifodram is
port(wr_clk,rd_clk,rst,wr_en,rd_en: in std_logic;
din: in std_logic_vector (63 downto 0);
full,almost_full,empty,valid: out std_logic;
dout: out std_logic_vector (7 downto 0));
end component;

component dram_controller is
generic(ddr3_dq_width: natural;
ddr3_dqs_width: natural;
ddr3_addr_width: natural;
ddr3_ba_width: natural;
ddr3_dm_width: natural;
app_addr_width: natural;
app_cmd_width: natural;
app_data_width: natural;
app_mask_width: natural);
port(sys_clk,ref_clk,sys_rst: in std_logic;
ddr3_dq: inout std_logic_vector (ddr3_dq_width-1 downto 0);
ddr3_dqs_n,ddr3_dqs_p: inout std_logic_vector (ddr3_dqs_width-1 downto 0);
ddr3_addr: out std_logic_vector (ddr3_addr_width-1 downto 0);
ddr3_ba: out std_logic_vector (ddr3_ba_width-1 downto 0);
ddr3_ras_n,ddr3_cas_n,ddr3_we_n,ddr3_reset_n: out std_logic;
ddr3_ck_p,ddr3_ck_n,ddr3_cke,ddr3_cs_n,ddr3_odt: out std_logic_vector (0 downto 0);
ddr3_dm: out std_logic_vector (ddr3_dm_width-1 downto 0);
o_clk,o_rst: out std_logic;
i_rd_en,i_wr_en: in std_logic;
i_addr: in std_logic_vector (app_addr_width-1 downto 0);
i_data: in std_logic_vector (app_data_width-1 downto 0);
i_mask: in std_logic_vector (app_mask_width-1 downto 0);
o_init_calib_complete: out std_logic;
o_data: out std_logic_vector (app_data_width-1 downto 0);
o_data_valid,o_ready,o_wdf_ready: out std_logic);
end component;

begin

u_ila_0: ila_0
port map(clk=>gclk,
         trig_out=>cross_trg0,
         trig_out_ack=>cross_ack1,
         trig_in=>cross_trg1,
         trig_in_ack=>cross_ack0,
         probe0=>std_logic_vector(addr_reg1),
         probe1=>(0=>empty_dram),
         probe2=>(0=>tcp_send),
         probe3=>(0=>write_ack)
);

u_ila_1: ila_1
port map(clk=>ui_clk,
         trig_out=>cross_trg1,
         trig_out_ack=>cross_ack0,
         trig_in=>cross_trg0,
         trig_in_ack=>cross_ack1,
         probe0=>std_logic_vector(addr_reg3),
         probe1=>(0=>valid_dram),
         probe2=>(0=>dram_rbusy),
         probe3=>(0=>full_dram),
         probe4=>(0=>dram_ren)
);


fifo_sync: fifosync
port map(clk=>gclk,
         srst=>local_rst,
         din=>din_tcp,
         wr_en=>tcp_rx,
         rd_en=>reg_wen1,
         dout=>din_stcp,
         full=>full_sync,
         empty=>empty_sync,
         wr_data_count=>wr_data_count
);

fifo_tcp: fifotcp
port map(wr_clk=>gclk,
         rd_clk=>ui_clk,
         rst=>local_rst,
         din=>din_parallel,
         wr_en=>reg_wen1,
         rd_en=>dram_wen,
         dout=>dout_parallel,
         full=>full_tcp,
         almost_full=>almost_tcp,
         empty=>empty_tcp,
         valid=>open
);

fifo_dram: fifodram
port map(wr_clk=>ui_clk,
         rd_clk=>gclk,
         rst=>local_rst,
         din=>dram_dout,
         wr_en=>valid_dram,
         rd_en=>sitcp_rden,
         dout=>dout_tcp,
         full=>full_dram,
         almost_full=>almost_dram,
         empty=>empty_dram,
         valid=>tcp_tx
);

dram_control: dram_controller
generic map(ddr3_dq_width=>ddr3_dq_width,
ddr3_dqs_width=>ddr3_dqs_width,
ddr3_addr_width=>ddr3_addr_width,
ddr3_ba_width=>ddr3_ba_width,
ddr3_dm_width=>ddr3_dm_width,
app_addr_width=>app_addr_width,
app_cmd_width=>app_cmd_width,
app_data_width=>app_data_width,
app_mask_width=>app_mask_width)
port map(sys_clk=>sys_clk,
         ref_clk=>ref_clk,
         sys_rst=>dram_rst,
         ddr3_dq=>ddr3_dq,
         ddr3_dqs_n=>ddr3_dqs_n,
         ddr3_dqs_p=>ddr3_dqs_p,
         ddr3_addr=>ddr3_addr,
         ddr3_ba=>ddr3_ba,
         ddr3_ras_n=>ddr3_ras_n,
         ddr3_cas_n=>ddr3_cas_n,
         ddr3_we_n=>ddr3_we_n,
         ddr3_reset_n=>ddr3_reset_n,
         ddr3_ck_p=>ddr3_ck_p,
         ddr3_ck_n=>ddr3_ck_n,
         ddr3_cke=>ddr3_cke,
         ddr3_cs_n=>ddr3_cs_n,
         ddr3_odt=>ddr3_odt,
         ddr3_dm=>ddr3_dm,
         o_clk=>ui_clk,
         o_rst=>ui_rst,
         i_rd_en=>dram_ren,
         i_wr_en=>dram_wen,
         i_addr=>dram_addr,
         i_data=>dram_data,
         i_mask=>dram_mask,
         o_init_calib_complete=>dram_init_calib_complete,
         o_data=>dram_dout,
         o_data_valid=>valid_dram,
         o_ready=>dram_ready,
         o_wdf_ready=>dram_wdf_ready
);

process(gclk)
begin
  if rising_edge(gclk) then
    if local_rst='1' then
      presente<=calib;
    else
      presente<=futuro;
    end if;
  end if;
end process;

process(ui_clk)
begin
  if rising_edge(ui_clk) then
    if ui_rst='1' then
      pasado<=calib;
    else
      pasado<=actual;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if local_rst='1' then
      din_parallel<=(others=>'0');
    else
      if reg_wen0='1' then
        din_parallel(102)<='1';
        din_parallel(101 downto 72)<=std_logic_vector(full_addr0);
        din_parallel(71 downto 8)<=din_stcp;
        din_parallel(7 downto 0)<=data_mask;
      end if;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if local_rst='1' then
      addr_reg0<=(others=>'0');
    else
      addr_reg0<=addr_reg1;
    end if;
  end if;
end process;

process(presente,calib_complete,init_done,tcp_send,empty_sync,addr_reg0,addr_reg1)
begin
  reg_wen0<='0';
  reg_wen1<='0';
  write_ack<='0';
  addr_reg1<=addr_reg0;
  case presente is
    when calib=>
      addr_reg1<=(others=>'0');
      if calib_complete='1' then
        futuro<=init_start;
      else
        futuro<=calib;
      end if;
    when init_start=>
      if init_done='1' then
        futuro<=tcp_write;
      else
        futuro<=init_start;
      end if;
    when tcp_write=>
      if tcp_send='0' then
        futuro<=wait_nempty;
      else
        futuro<=tcp_write;
      end if;
    when wait_nempty=>
      if empty_sync='0' then
        futuro<=fifo_write;
      else
        futuro<=wait_nempty;
      end if;
    when fifo_write=>
      reg_wen0<='1';
      futuro<=count_loop;
    when count_loop=>
      reg_wen1<='1';
      addr_reg1<=addr_reg0+1;
      if tcp_send='0' then
        if addr_reg1=A0 then
          futuro<=end_transmission;
        else
          futuro<=tcp_write;
        end if;
      else
        futuro<=wait_nempty;
      end if;
    when end_transmission=>
      write_ack<='1';
      futuro<=end_transmission;
    when others=>
      futuro<=calib;
  end case;
end process;

process(ui_clk)
begin
  if rising_edge(ui_clk) then
    if ui_rst='1' then
      addr_reg2<=(others=>'0');
    else
      addr_reg2<=addr_reg3;
    end if;
  end if;
end process;

process(ui_clk,ui_rst)
begin
  if ui_rst='1' then
    timer<=0;
  else
    if rising_edge(ui_clk) then
      if pasado/=actual then
        timer<=0;
      else
        timer<=timer+1;
      end if;
    end if;
  end if;
end process;

process(pasado,calib_complete,init_done,write_ack,full_dram,dram_rbusy,valid_dram,addr_reg2,addr_reg3)
begin
  dram_ren<='0';
  addr_reg3<=addr_reg2;
  case pasado is
    when calib=>
      if calib_complete='1' then
        actual<=init_start;
      else
        addr_reg3<=(others=>'0');
        actual<=calib;
      end if;
    when init_start=>
      if init_done='1' then
        actual<=wait_ack;
      else
        actual<=init_start;
      end if;
    when wait_ack=>
      if write_ack='1' then
        actual<=delay_read;
      else
        actual<=wait_ack;
      end if;
    when delay_read=>
      if timer>=T0-1 then
        actual<=dram_read;
      else
        actual<=delay_read;
      end if;
    when dram_read=>
      if full_dram='1' or dram_rbusy='0' then
        actual<=dram_read;
      else
        dram_ren<='1';
        addr_reg3<=addr_reg2+1;
        actual<=dram_busy;
      end if;
    when dram_busy=>
      if valid_dram='1' then
        actual<=dram_finish;
      else
        actual<=dram_busy;
      end if;
    when dram_finish=>
      if addr_reg3=A0 then
        actual<=end_transmission;
      else
        if timer>=T1-1 then
          actual<=dram_read;
        else
          actual<=dram_finish;
        end if;
      end if;
    when end_transmission=>
      actual<=end_transmission;
    when others=>
      actual<=calib;
  end case;
end process;

tcp_send<=init_done and tcp_rx;
dram_wbusy<=dram_ready and dram_wdf_ready;
dram_rbusy<=dram_ready;
calib_complete<=dram_init_calib_complete;
data_mask<=(others=>'0');
full_addr0(app_addr_width-1)<='0';
full_addr0(app_addr_width-2 downto 3)<=addr_reg1;
full_addr0(2 downto 0)<="000";
full_addr1(app_addr_width-1)<='0';
full_addr1(app_addr_width-2 downto 3)<=addr_reg3;
full_addr1(2 downto 0)<="000";
dram_wen<=dout_parallel(102) and dram_wbusy and not(empty_tcp);
dram_data<=dout_parallel(71 downto 8);
dram_mask<=dout_parallel(7 downto 0);
dram_addr<=std_logic_vector(full_addr1) when (write_ack='1') else
           dout_parallel(101 downto 72);

empty<=empty_dram;
mig_ui_clk<=ui_clk;
mig_ui_rst<=ui_rst;

end x;
