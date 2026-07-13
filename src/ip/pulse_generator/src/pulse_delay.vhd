library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pulse_delay is
port (p0,p1,p2,p3: in std_logic;
ctrl_signal: in std_logic_vector (3 downto 0);
w_pat: in std_logic_vector (23 downto 0);
pulse_out: out std_logic);
end entity;

architecture x of pulse_delay is
signal local_rst,make_delay: std_logic;
signal ctrl_s: std_logic_vector (3 downto 0);
signal wmask0,wmask1: std_logic_vector (7 downto 0);
signal c_pat1,c_pat0: std_logic_vector (7 downto 0);
signal c_pat2,c_pat3: std_logic;
signal sampling_reg0,sampling_reg1,sampling_reg2,sampling_reg3: std_logic;
signal sampling_reg4,sampling_reg5,sampling_reg6,sampling_reg7: std_logic;

component slow_sampler is
port (gclk,make_delay,local_rst: in std_logic;
ctrl_signal: in std_logic_vector (3 downto 0);
w_pattern: in std_logic_vector (23 downto 0);
c_pat0,c_pat1: in std_logic_vector (7 downto 0);
c_pat2,c_pat3: out std_logic;
pulse_out: out std_logic);
end component;

begin

sampler: slow_sampler
port map(gclk=>p0,
         make_delay=>make_delay,
         local_rst=>local_rst,
         ctrl_signal=>ctrl_s,
         w_pattern=>w_pat,
         c_pat0=>c_pat0,
         c_pat1=>c_pat1,
         c_pat2=>c_pat2,
         c_pat3=>c_pat3,
         pulse_out=>pulse_out
);

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

process(p1)
begin
  if rising_edge(p1) then
    if local_rst='0' and make_delay='1' and c_pat2='1' then
      c_pat0(0)<=wmask0(0) and w_pat(0);
    else
      c_pat0(0)<='0';
    end if;
  end if;
end process;

process(p2)
begin
  if rising_edge(p2) then
    if local_rst='0' and make_delay='1' and c_pat2='1' then
      c_pat0(1)<=wmask0(1) and w_pat(1);
    else
      c_pat0(1)<='0';
    end if;
  end if;
end process;

process(p3)
begin
  if rising_edge(p3) then
    if local_rst='0' and make_delay='1' and c_pat2='1' then
      c_pat0(2)<=wmask0(2) and w_pat(2);
    else
      c_pat0(2)<='0';
    end if;
  end if;
end process;

process(p0)
begin
  if falling_edge(p0) then
    if local_rst='0' and make_delay='1' and c_pat2='1' then
      c_pat0(3)<=wmask0(3) and w_pat(3);
    else
      c_pat0(3)<='0';
    end if;
  end if;
end process;

process(p1)
begin
  if falling_edge(p1) then
    if local_rst='0' and make_delay='1' and c_pat2='1' then
      c_pat0(4)<=wmask0(4) and w_pat(4);
    else
      c_pat0(4)<='0';
    end if;
  end if;
end process;

process(p2)
begin
  if falling_edge(p2) then
    if local_rst='0' and make_delay='1' and c_pat2='1' then
      c_pat0(5)<=wmask0(5) and w_pat(5);
    else
      c_pat0(5)<='0';
    end if;
  end if;
end process;

process(p3)
begin
  if falling_edge(p3) then
    if local_rst='0' and make_delay='1' and c_pat2='1' then
      c_pat0(6)<=wmask0(6) and w_pat(6);
    else
      c_pat0(6)<='0';
    end if;
  end if;
end process;

process(p0)
begin
  if rising_edge(p0) then
    if local_rst='0' and make_delay='1' and c_pat2='1' then
      c_pat0(7)<=wmask0(7) and w_pat(7);
    else
      c_pat0(7)<='0';
    end if;
  end if;
end process;

process(p1)
begin
  if rising_edge(p1) then
    if local_rst='0' and make_delay='1' and c_pat3='1' then
      c_pat1(0)<=wmask0(0) and w_pat(8);
    else
      c_pat1(0)<='0';
    end if;
  end if;
end process;

process(p2)
begin
  if rising_edge(p2) then
    if local_rst='0' and make_delay='1' and c_pat3='1' then
      c_pat1(1)<=wmask0(1) and w_pat(9);
    else
      c_pat1(1)<='0';
    end if;
  end if;
end process;

process(p3)
begin
  if rising_edge(p3) then
    if local_rst='0' and make_delay='1' and c_pat3='1' then
      c_pat1(2)<=wmask0(2) and w_pat(10);
    else
      c_pat1(2)<='0';
    end if;
  end if;
end process;

process(p0)
begin
  if falling_edge(p0) then
    if local_rst='0' and make_delay='1' and c_pat3='1' then
      c_pat1(3)<=wmask0(3) and w_pat(11);
    else
      c_pat1(3)<='0';
    end if;
  end if;
end process;

process(p1)
begin
  if falling_edge(p1) then
    if local_rst='0' and make_delay='1' and c_pat3='1' then
      c_pat1(4)<=wmask0(4) and w_pat(12);
    else
      c_pat1(4)<='0';
    end if;
  end if;
end process;

process(p2)
begin
  if falling_edge(p2) then
    if local_rst='0' and make_delay='1' and c_pat3='1' then
      c_pat1(5)<=wmask0(5) and w_pat(13);
    else
      c_pat1(5)<='0';
    end if;
  end if;
end process;

process(p3)
begin
  if falling_edge(p3) then
    if local_rst='0' and make_delay='1' and c_pat3='1' then
      c_pat1(6)<=wmask0(6) and w_pat(14);
    else
      c_pat1(6)<='0';
    end if;
  end if;
end process;

process(p0)
begin
  if rising_edge(p0) then
    if local_rst='0' and make_delay='1' and c_pat3='1' then
      c_pat1(7)<=wmask0(7) and w_pat(15);
    else
      c_pat1(7)<='0';
    end if;
  end if;
end process;

process(p3)
begin
  if falling_edge(p3) then
    if ctrl_s="0000" or ctrl_s="1001" then
      local_rst<='1';
    else
      local_rst<='0';
    end if;
  end if;
end process;

process(p3)
begin
  if falling_edge(p3) then
    if ctrl_s="1000" then
      make_delay<='1';
    else
      make_delay<='0';
    end if;
  end if;
end process;

process(p0)
begin
  if rising_edge(p0) then
    ctrl_s<=ctrl_signal;
  end if;
end process;

wmask1<=(sampling_reg7 & sampling_reg6 & sampling_reg5 & sampling_reg4 & sampling_reg3 & sampling_reg2 & sampling_reg1 & sampling_reg0);

with wmask1 select
  wmask0<="00000001" when "00000001",
          "00000010" when "00000011",
          "00000100" when "00000111",
          "00001000" when "00001111",
          "00010000" when "00011111",
          "00100000" when "00111111",
          "01000000" when "01111111",
          "10000000" when "11111111",
          "00000001" when "11111110",
          "00000010" when "11111100",
          "00000100" when "11111000",
          "00001000" when "11110000",
          "00010000" when "11100000",
          "00100000" when "11000000",
          "01000000" when "10000000",
          "10000000" when "00000000",
          "00000000" when others;


end x;
