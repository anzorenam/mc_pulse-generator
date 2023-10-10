library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;

entity event_generator is
generic(ddr3_dq_width: natural:= 8;
ddr3_dqs_width: natural:= 1;
ddr3_addr_width: natural:= 16;
ddr3_ba_width: natural:= 3;
ddr3_dm_width: natural:= 1;
app_addr_width: natural:= 30;
app_cmd_width: natural:= 3;
app_data_width: natural:= 64;
app_mask_width: natural:= 8);
port(clk_p,grst: in std_logic;
GMII_MDIO: inout std_logic;
phy2rmii_crs_dv,phy2rmii_rx_er: in std_logic;
phy2rmii_rxd : in std_logic_vector (1 downto 0);
GMII_RSTn,GMII_MDC: out std_logic;
rmii2phy_tx_en: out std_logic;
rmii2phy_txd : out std_logic_vector (1 downto 0);
ddr3_dq: inout std_logic_vector (ddr3_dq_width-1 downto 0);
ddr3_dqs_n,ddr3_dqs_p: inout std_logic_vector (ddr3_dqs_width-1 downto 0);
ddr3_addr: out std_logic_vector (ddr3_addr_width-1 downto 0);
ddr3_ba: out std_logic_vector (ddr3_ba_width-1 downto 0);
ddr3_ras_n,ddr3_cas_n,ddr3_we_n,ddr3_reset_n: out std_logic;
ddr3_ck_p,ddr3_ck_n,ddr3_cke,ddr3_cs_n,ddr3_odt: out std_logic_vector (0 downto 0);
ddr3_dm: out std_logic_vector (ddr3_dm_width-1 downto 0));
end entity;

architecture x of event_generator is
signal clk_200,clk_400,gclk: std_logic;
signal mig_ui_clk,clk_aux0: std_logic;
signal rst_tcp,rst_tcp0,rst_tcp1: std_logic;
signal sitcp_rst,mig_ui_rst,gmii_rst: std_logic;
signal dram_rst,empty_flag,tcp_open,sitcp_rden: std_logic;
signal dram_din,dram_dout: std_logic_vector (63 downto 0);
signal dram_rstx_async,dram_rst_sync1,dram_rst_sync2: std_logic;
signal rst_async,rst_sync1,rst_sync2: std_logic;
signal wr_data_count: std_logic_vector (11 downto 0);
signal EXT_IP_ADDR: std_logic_vector (31 downto 0);
signal EXT_TCP_PORT,EXT_RBCP_PORT: std_logic_vector (15 downto 0);
signal PHY_ADDR: std_logic_vector (4 downto 0);
signal gtx_clk,GMII_MDIO_OE,GMII_MDIO_OUT: std_logic;
signal TCP_OPEN_REQ,TCP_OPEN_ACK,TCP_ERROR: std_logic;
signal GMII_TX_EN,GMII_TX_ER,MII_TX_CLK,MII_RX_CLK: std_logic;
signal GMII_RX_DV,GMII_RX_ER,GMII_CRS,GMII_COL: std_logic;
signal GMII_TXD,GMII_RXD: std_logic_vector (3 downto 0);
signal TCP_CLOSE: std_logic;
signal TCP_TX_FULL,TCP_TX_WR,TCP_RX_WR: std_logic;
signal TCP_RX_WC: std_logic_vector (15 downto 0);
signal TCP_TX_DATA,TCP_RX_DATA: std_logic_vector (7 downto 0);
signal RBCP_ACT,RBCP_WE,RBCP_RE,RBCP_ACK: std_logic;
signal RBCP_RD,RBCP_WD: std_logic_vector (7 downto 0);
signal RBCP_ADDR: std_logic_vector (31 downto 0);
signal local_rst,srst_done,init_done: std_logic;

component clkgen0 is
port(clk_in1: in std_logic;
clk_out1,clk_out2: out std_logic);
end component;

component clkgen1 is
port(clk_in1: in std_logic;
clk_out1: out std_logic);
end component;

component dram_wrap is
generic(ddr3_dq_width: natural;
ddr3_dqs_width: natural;
ddr3_addr_width: natural;
ddr3_ba_width: natural;
ddr3_dm_width: natural;
app_addr_width: natural;
app_cmd_width: natural;
app_data_width: natural;
app_mask_width: natural);
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

clk_dram: clkgen0
port map(clk_in1=>clk_p,
         clk_out1=>clk_400,
         clk_out2=>clk_200

);

clk_sitcp: clkgen1
port map(clk_in1=>clk_aux0,
         clk_out1=>gclk
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

dram_interface: dram_wrap
generic map(ddr3_dq_width=>ddr3_dq_width,
ddr3_dqs_width=>ddr3_dqs_width,
ddr3_addr_width=>ddr3_addr_width,
ddr3_ba_width=>ddr3_ba_width,
ddr3_dm_width=>ddr3_dm_width,
app_addr_width=>app_addr_width,
app_cmd_width=>app_cmd_width,
app_data_width=>app_data_width,
app_mask_width=>app_mask_width)
port map(sys_clk=>clk_400,
         ref_clk=>clk_200,
         gclk=>gclk,
         dram_rst=>dram_rst,
         local_rst=>local_rst,
         init_done=>init_done,
         sitcp_rden=>sitcp_rden,
         tcp_rx=>TCP_RX_WR,
         din_tcp=>TCP_RX_DATA,
         mig_ui_clk=>mig_ui_clk,
         mig_ui_rst=>mig_ui_rst,
         tcp_tx=>TCP_TX_WR,
         empty=>empty_flag,
         wr_data_count=>wr_data_count,
         dout_tcp=>TCP_TX_DATA,
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
	 ddr3_dm=>ddr3_dm
);

sitcp: WRAP_SiTCP_GMII_XC7S_32K
generic map(TIM_PERIOD=>50)
port map(CLK=>gclk,
         RST=>rst_tcp,
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
         GMII_TXD(7 downto 4)=>"0000",
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
         TCP_RX_WR=>TCP_RX_WR,
         TCP_RX_DATA=>TCP_RX_DATA,
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

clkbuf: BUFGCE
generic map(CE_TYPE=>"SYNC")
port map(O=>clk_aux0,CE=>'1',I=>mig_ui_clk);

process(clk_400)
begin
  if rising_edge(clk_400) then
    if dram_rstx_async='0' then
      dram_rst_sync1<='0';
      dram_rst_sync2<='0';
    else
      dram_rst_sync1<='1';
      dram_rst_sync2<=dram_rst_sync1;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if rst_async='0' then
      rst_tcp0<='0';
      rst_tcp1<='0';
    else
      rst_tcp0<='1';
      rst_tcp1<=rst_tcp0;
    end if;
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

tcp_open<=not(TCP_OPEN_ACK);
GMII_RSTn<=gmii_rst;
EXT_IP_ADDR<="00000000000000000000000000000000";
EXT_TCP_PORT<="0000000000000000";
EXT_RBCP_PORT<="0000000000000000";
PHY_ADDR<="00000";
TCP_OPEN_REQ<='0';
sitcp_rden<=not(empty_flag) and not(TCP_TX_FULL);
TCP_RX_WC(15 downto 12)<="1111";
TCP_RX_WC(11 downto 0)<=wr_data_count;
dram_rstx_async<=not(grst);
dram_rst<=dram_rst_sync2;
rst_async<=mig_ui_rst;
rst_tcp<=rst_tcp1;
local_rst<=srst_done or rst_tcp;

end x;
