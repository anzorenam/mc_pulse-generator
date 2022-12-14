library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;

entity hitsum_trg is
generic(gwidth: natural:= 52;
pwidth: natural:= 26;
daqtime: unsigned (31 downto 0):= to_unsigned(1000000000,32);
any: natural:= 4);
port(clk_p,grst: in std_logic;
make_event_p,make_event_n: in std_logic;
pulse_event_p: in std_logic_vector (7 downto 0);
pulse_event_n: in std_logic_vector (7 downto 0);
GMII_MDIO: inout std_logic;
phy2rmii_crs_dv,phy2rmii_rx_er: in std_logic;
phy2rmii_rxd : in std_logic_vector (1 downto 0);
GMII_RSTn,GMII_MDC: out std_logic;
rmii2phy_tx_en: out std_logic;
rmii2phy_txd : out std_logic_vector (1 downto 0));
end entity;

architecture x of hitsum_trg is
signal pulse_aux: std_logic_vector (7 downto 0);
signal h_aux: std_logic_vector (15 downto 0);
signal s_aux: std_logic_vector (3 downto 0);
signal trg_any: unsigned (3 downto 0);
signal wout,e_valid,t_valid,trg_signal: std_logic;
signal esync0,esync1,esync2,esync3: std_logic;
signal tsync0,tsync1,tsync2,tsync3: std_logic;
signal make_aux,gclk,srst_done,init_done: std_logic;
signal sitcp_rst,gmii_rst: std_logic;
signal tcp_open,wrenb,sitcp_rden: std_logic;
signal full,almost_full,empty: std_logic;
signal din: std_logic_vector (31 downto 0);
signal EXT_IP_ADDR: std_logic_vector (31 downto 0);
signal EXT_TCP_PORT,EXT_RBCP_PORT: std_logic_vector (15 downto 0);
signal PHY_ADDR: std_logic_vector (4 downto 0);
signal gtx_clk,GMII_MDIO_OE,GMII_MDIO_OUT: std_logic;
signal TCP_OPEN_REQ,TCP_OPEN_ACK,TCP_ERROR: std_logic;
signal GMII_TX_EN,GMII_TX_ER,MII_TX_CLK,MII_RX_CLK: std_logic;
signal GMII_RX_DV,GMII_RX_ER,GMII_CRS,GMII_COL: std_logic;
signal GMII_TXD,GMII_RXD: std_logic_vector (3 downto 0);
signal TCP_CLOSE: std_logic;
signal TCP_TX_FULL,TCP_TX_WR: std_logic;
signal TCP_RX_WC: std_logic_vector (15 downto 0);
signal TCP_TX_DATA: std_logic_vector (7 downto 0);
signal RBCP_ACT,RBCP_WE,RBCP_RE,RBCP_ACK: std_logic;
signal RBCP_RD,RBCP_WD: std_logic_vector (7 downto 0);
signal RBCP_ADDR: std_logic_vector (31 downto 0);
signal scaler0,scaler1: unsigned (15 downto 0);

component clkgen is
port(CLK_IN1: in std_logic;
CLK_OUT1: out std_logic);
end component;

component gate_generator is
generic(gwidth: natural;
any: natural);
port(gclk,grst: in std_logic;
trg_any: in unsigned (3 downto 0);
trg_gate: out std_logic);
end component;

component one_shot is
generic(pwidth: natural);
port(gclk,grst: in std_logic;
hit_async: in std_logic;
hit_wsync: out std_logic);
end component;

component lut_adder is
port(clka: in std_logic;
addra:in std_logic_vector (15 downto 0);
douta: out std_logic_vector (3 downto 0));
end component;

component event_scaler is
generic(daqtime: unsigned (31 downto 0));
port(gclk,grst: in std_logic;
init_done,tcp_open: in std_logic;
t_valid,e_valid: in std_logic;
wout: out std_logic;
scaler0,scaler1: out unsigned (15 downto 0));
end component;

component mii_to_rmii_0 is
port(rst_n,ref_clk: in std_logic;
mac2rmii_tx_en,mac2rmii_tx_er: in std_logic;
mac2rmii_txd : in std_logic_vector (3 downto 0);
rmii2mac_tx_clk,rmii2mac_rx_clk: out std_logic;
rmii2mac_col,rmii2mac_crs,rmii2mac_rx_dv: out std_logic;
rmii2mac_rx_er,rmii2phy_tx_en: out std_logic;
rmii2mac_rxd: out std_logic_vector (3 downto 0);
phy2rmii_crs_dv,phy2rmii_rx_er: in std_logic;
phy2rmii_rxd : in std_logic_vector (1 downto 0);
rmii2phy_txd : out std_logic_vector (1 downto 0));
end component;

component fifotcp is
port(wr_clk,rd_clk,rst,wr_en,rd_en: in std_logic;
din: in std_logic_vector (31 downto 0);
full,almost_full,empty,valid: out std_logic;
dout: out std_logic_vector (7 downto 0));
end component;

component WRAP_SiTCP_GMII_XC7S_32K is
generic(TIM_PERIOD: integer);
port(CLK,RST,FORCE_DEFAULTn: in std_logic;
GMII_1000M,GMII_TX_CLK,GMII_RX_CLK,GMII_CRS: in std_logic;
GMII_RX_DV,GMII_RX_ER,GMII_COL,GMII_MDIO_IN: in std_logic;
TCP_OPEN_REQ,TCP_CLOSE_ACK,TCP_TX_WR,RBCP_ACK: in std_logic;
EEPROM_DO: in std_logic;
EXT_IP_ADDR: in std_logic_vector (31 downto 0);
EXT_TCP_PORT,EXT_RBCP_PORT: in std_logic_vector (15 downto 0);
TCP_RX_WC: in std_logic_vector (15 downto 0);
TCP_TX_DATA,RBCP_RD: in std_logic_vector (7 downto 0);
PHY_ADDR: in std_logic_vector (4 downto 0);
GMII_RXD: in std_logic_vector (7 downto 0);
SiTCP_RST: out std_logic;
EEPROM_CS,EEPROM_SK,EEPROM_DI: out std_logic;
GMII_RSTn,GMII_MDC,GMII_MDIO_OUT,GMII_MDIO_OE: out std_logic;
GMII_TX_EN,GMII_TX_ER: out std_logic;
TCP_RX_WR,TCP_TX_FULL,TCP_OPEN_ACK,TCP_ERROR,TCP_CLOSE_REQ: out std_logic;
RBCP_ACT,RBCP_WE,RBCP_RE: out std_logic;
GMII_TXD: out std_logic_vector (7 downto 0);
TCP_RX_DATA,RBCP_WD: out std_logic_vector (7 downto 0);
RBCP_ADDR: out std_logic_vector (31 downto 0));
end component;

component rbcp_control is
port(CLK,RST: in std_logic;
RBCP_ACT,RBCP_WE,RBCP_RE: in std_logic;
RBCP_WD: in std_logic_vector (7 downto 0);
RBCP_ADDR: in std_logic_vector (31 downto 0);
RBCP_ACK: out std_logic;
RBCP_RD: out std_logic_vector (7 downto 0);
srst_done,init_done: out std_logic);
end component;

begin

clkgen0: clkgen
port map(CLK_IN1=>clk_p,
              CLK_OUT1=>gclk
);

gate_gen: gate_generator
generic map(gwidth=>gwidth,
any=>any)
port map(gclk=>gclk,
               grst=>srst_done,
               trg_any=>trg_any,
               trg_gate=>trg_signal
);

gen_syncs:
for j in 0 to 7 generate
  diffbuff: IBUFDS
  generic map(DIFF_TERM=>TRUE,
                      IOSTANDARD=>"LVDS_25")
  port map(I=>pulse_event_p(j),IB=>pulse_event_n(j),O=>pulse_aux(j));
  gen_sync: one_shot
  generic map(pwidth=>pwidth)
  port map(gclk=>gclk,
                 grst=>srst_done,
                 hit_async=>pulse_aux(j),
                 hit_wsync=>h_aux(j)
  );
end generate;

adder0: lut_adder
port map(clka=>gclk,
               addra=>h_aux,
               douta=>s_aux
);

scaler: event_scaler
generic map(daqtime=>daqtime)
port map(gclk=>gclk,
               grst=>srst_done,
               init_done=>init_done,
               tcp_open=>tcp_open,
               t_valid=>t_valid,
               e_valid=>e_valid,
               wout=>wout,
               scaler0=>scaler0,
               scaler1=>scaler1
);

mii2rmii: mii_to_rmii_0
port map(rst_n=>gmii_rst,
               ref_clk=>gclk,
               mac2rmii_tx_en=>GMII_TX_EN,
               mac2rmii_tx_er=>GMII_TX_ER,
               mac2rmii_txd=>GMII_TXD,
               rmii2mac_tx_clk=>MII_TX_CLK,
               rmii2mac_rx_clk=>MII_RX_CLK,
               rmii2mac_col=>GMII_COL,
               rmii2mac_crs=>GMII_CRS,
               rmii2mac_rx_dv=>GMII_RX_DV,
               rmii2mac_rx_er=>GMII_RX_ER,
               rmii2mac_rxd=>GMII_RXD,
               rmii2phy_tx_en=>rmii2phy_tx_en,
               rmii2phy_txd=>rmii2phy_txd,
               phy2rmii_crs_dv=>phy2rmii_crs_dv,
               phy2rmii_rx_er=>phy2rmii_rx_er,
               phy2rmii_rxd=>phy2rmii_rxd
);

fifo_tcp: fifotcp
port map(wr_clk=>gclk,
               rd_clk=>gclk,
               rst=>srst_done,
               din=>din,
               wr_en=>wrenb,
               rd_en=>sitcp_rden,
               dout=>TCP_TX_DATA,
               full=>open,
               almost_full=>almost_full,
               empty=>empty,
               valid=>TCP_TX_WR
);

sitcp: WRAP_SiTCP_GMII_XC7S_32K
generic map(TIM_PERIOD=>50)
port map(CLK=>gclk,
               RST=>not(grst),
               FORCE_DEFAULTn=>'0',
               EXT_IP_ADDR=>EXT_IP_ADDR,
               EXT_TCP_PORT=>EXT_TCP_PORT,
               EXT_RBCP_PORT=>EXT_RBCP_PORT,
               PHY_ADDR=>PHY_ADDR,
               EEPROM_CS=>open,
               EEPROM_SK=>open,
               EEPROM_DI=>open,
               EEPROM_DO=>'0',
               GMII_RSTn=>gmii_rst,
               GMII_1000M=>'0',
               GMII_TX_CLK=>MII_TX_CLK,
               GMII_TX_EN=>GMII_TX_EN,
               GMII_TXD(7 downto 4)=>open,
               GMII_TXD(3 downto 0)=>GMII_TXD,
               GMII_TX_ER=>GMII_TX_ER,
               GMII_RX_CLK=>MII_RX_CLK,
               GMII_RX_DV=>GMII_RX_DV,
               GMII_RXD(7 downto 4)=>"0000",
               GMII_RXD(3 downto 0)=>GMII_RXD,
               GMII_RX_ER=>GMII_RX_ER,
               GMII_CRS=>GMII_CRS,
               GMII_COL=>GMII_COL,
               GMII_MDC=>GMII_MDC,
               GMII_MDIO_IN=>GMII_MDIO,
               GMII_MDIO_OUT=>GMII_MDIO_OUT,
               GMII_MDIO_OE=>GMII_MDIO_OE,
               SiTCP_RST=>sitcp_rst,
               TCP_OPEN_REQ=>TCP_OPEN_REQ,
               TCP_OPEN_ACK=>TCP_OPEN_ACK,
               TCP_ERROR=>open,
               TCP_CLOSE_REQ=>TCP_CLOSE,
               TCP_CLOSE_ACK=>TCP_CLOSE,
               TCP_RX_WC=>TCP_RX_WC,
               TCP_RX_WR=>open,
               TCP_RX_DATA=>open,
               TCP_TX_FULL=>TCP_TX_FULL,
               TCP_TX_WR=>TCP_TX_WR,
               TCP_TX_DATA=>TCP_TX_DATA,
               RBCP_ACT=>RBCP_ACT,
               RBCP_ADDR=>RBCP_ADDR,
               RBCP_WD=>RBCP_WD,
               RBCP_WE=>RBCP_WE,
               RBCP_RE=>RBCP_RE,
               RBCP_ACK=>RBCP_ACK,
               RBCP_RD=>RBCP_RD
);

rbcp: rbcp_control
port map(CLK=>gclk,
               RST=>sitcp_rst,
               RBCP_ACT=>RBCP_ACT,
               RBCP_ADDR=>RBCP_ADDR,
               RBCP_WE=>RBCP_WE,
               RBCP_WD=>RBCP_WD,
               RBCP_RE=>RBCP_RE,
               RBCP_RD=>RBCP_RD,
               RBCP_ACK=>RBCP_ACK,
               srst_done=>srst_done,
               init_done=>init_done
);

diffbuff: IBUFDS
generic map(DIFF_TERM=>TRUE,
                    IOSTANDARD=>"LVDS_25")
port map(I=>make_event_p,IB=>make_event_n,O=>make_aux);


process(make_aux,esync2)
begin
  if esync2='1' then
    esync0<='0';
  else
    if rising_edge(make_aux) then
      esync0<='1';
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    esync1<=esync0;
    esync2<=esync1;
    esync3<=esync2;
  end if;
end process;

process(trg_signal,tsync2)
begin
  if tsync2='1' then
    tsync0<='0';
  else
    if rising_edge(trg_signal) then
      tsync0<='1';
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    tsync1<=tsync0;
    tsync2<=tsync1;
    tsync3<=tsync2;
  end if;
end process;

process(GMII_MDIO_OE,GMII_MDIO_OUT)
begin
  if GMII_MDIO_OE='1' then
    GMII_MDIO<=GMII_MDIO_OUT;
  else
    GMII_MDIO<='Z';
  end if;
end process;

din(31 downto 16)<=std_logic_vector(scaler0);
din(15 downto 0)<=std_logic_vector(scaler1);
e_valid<=esync2 and not(esync3);
t_valid<=tsync2 and not(tsync3);
trg_any<=unsigned(s_aux);
wrenb<=wout and not(almost_full);
tcp_open<=not(TCP_OPEN_ACK);
sitcp_rden<=not(empty) and not(TCP_TX_FULL);
GMII_RSTn<=gmii_rst;
EXT_IP_ADDR<="00000000000000000000000000000000";
EXT_TCP_PORT<="0000000000000000";
EXT_RBCP_PORT<="0000000000000000";
PHY_ADDR<="00000";
TCP_OPEN_REQ<='0';
TCP_RX_WC<="0000000000000000";
h_aux(15 downto 8)<="00000000";

end x;
