library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pulse_delay is
port (p0,p1,p2,p3: in std_logic;
make_delay: in std_logic;
ctrl_rand: in std_logic_vector (3 downto 0);
w_pat0,w_pat1,w_pat2,w_pat3: in std_logic_vector (23 downto 0);
w_pat4,w_pat5,w_pat6,w_pat7: in std_logic_vector (23 downto 0);
w_pat8,w_pat9,w_patA,w_patB: in std_logic_vector (23 downto 0);
w_patC,w_patD,w_patE,w_patF: in std_logic_vector (23 downto 0);
pulse_out: out std_logic_vector (15 downto 0));
end entity;

architecture x of pulse_delay is
signal local_rst: std_logic;
signal sampling_regs,sampling_code,wmask0: std_logic_vector (7 downto 0);
signal sampling_reg0,sampling_reg1,sampling_reg2,sampling_reg3: std_logic;
signal sampling_reg4,sampling_reg5,sampling_reg6,sampling_reg7: std_logic;

type wpatterns is array (15 downto 0) of std_logic_vector (23 downto 0);
signal wpat: wpatterns;

component slow_sampler is
port (gclk,local_rst,make_delay: in std_logic;
ctrl_rand: in std_logic_vector (3 downto 0);
w_pattern: in std_logic_vector (23 downto 0);
wmask0: in std_logic_vector (7 downto 0);
pulse_out: out std_logic);
end component;

begin

gen_samplers:
for j in 0 to 15 generate
sampler: slow_sampler
port map(gclk=>p0,
               local_rst=>local_rst,
               make_delay=>make_delay,
               ctrl_rand=>ctrl_rand,
               w_pattern=>wpat(j),
               wmask0=>wmask0,
               pulse_out=>pulse_out(j)
);

end generate;

process(p0)
begin
  if rising_edge(p0) then
    if local_rst='1' then
      sampling_reg0<='1';
    else
      if make_delay='1' then
        sampling_reg0<=not(sampling_reg7);
      end if;
    end if;
  end if;
end process;

process(p1)
begin
  if rising_edge(p1) then
    if local_rst='1' then
      sampling_reg1<='0';
    else
      if make_delay='1' then
        sampling_reg1<=sampling_reg0;
      end if;
    end if;
  end if;
end process;

process(p2)
begin
  if rising_edge(p2) then
    if local_rst='1' then
      sampling_reg2<='0';
    else
      if make_delay='1' then
        sampling_reg2<=sampling_reg1;
      end if;
    end if;
  end if;
end process;

process(p3)
begin
  if rising_edge(p3) then
    if local_rst='1' then
      sampling_reg3<='0';
    else
      if make_delay='1' then
        sampling_reg3<=sampling_reg2;
      end if;
    end if;
  end if;
end process;

process(p0)
begin
  if falling_edge(p0) then
    if local_rst='1' then
      sampling_reg4<='0';
    else
      if make_delay='1' then
        sampling_reg4<=sampling_reg3;
      end if;
    end if;
  end if;
end process;

process(p1)
begin
  if falling_edge(p1) then
    if local_rst='1' then
      sampling_reg5<='0';
    else
      if make_delay='1' then
        sampling_reg5<=sampling_reg4;
      end if;
    end if;
  end if;
end process;

process(p2)
begin
  if falling_edge(p2) then
    if local_rst='1' then
      sampling_reg6<='0';
    else
      if make_delay='1' then
        sampling_reg6<=sampling_reg5;
      end if;
    end if;
  end if;
end process;

process(p3)
begin
  if falling_edge(p3) then
    if local_rst='1' then
      sampling_reg7<='0';
    else
      if make_delay='1' then
        sampling_reg7<=sampling_reg6;
      end if;
    end if;
  end if;
end process;

wmask0<=(sampling_reg7 & sampling_reg6 & sampling_reg5 & sampling_reg4 & sampling_reg3 & sampling_reg2 & sampling_reg1 & sampling_reg0);

local_rst<='1' when (ctrl_rand="0001" or ctrl_rand="1000") else
                 '0';

wpat(0)<=w_pat0;
wpat(1)<=w_pat1;
wpat(2)<=w_pat2;
wpat(3)<=w_pat3;
wpat(4)<=w_pat4;
wpat(5)<=w_pat5;
wpat(6)<=w_pat6;
wpat(7)<=w_pat7;
wpat(8)<=w_pat8;
wpat(9)<=w_pat9;
wpat(10)<=w_patA;
wpat(11)<=w_patB;
wpat(12)<=w_patC;
wpat(13)<=w_patD;
wpat(14)<=w_patE;
wpat(15)<=w_patF;

end x;
