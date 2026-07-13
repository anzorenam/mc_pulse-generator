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
signal wmask0: std_logic_vector (7 downto 0);
signal sampling_reg0,sampling_reg1,sampling_reg2,sampling_reg3: std_logic;
signal sampling_reg4,sampling_reg5,sampling_reg6,sampling_reg7: std_logic;

component slow_sampler is
port (gclk,local_rst: in std_logic;
ctrl_signal: in std_logic_vector (3 downto 0);
w_pattern: in std_logic_vector (23 downto 0);
wmask0: in std_logic_vector (7 downto 0);
pulse_out: out std_logic);
end component;

begin

sampler: slow_sampler
port map(gclk=>p0,
         local_rst=>local_rst,
         ctrl_signal=>ctrl_s,
         w_pattern=>w_pat,
         wmask0=>wmask0,
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

process(p0)
begin
  if rising_edge(p0) then
    if ctrl_s="0000" or ctrl_s="1001" then
      local_rst<='1';
    else
      local_rst<='0';
    end if;
  end if;
end process;

process(p0)
begin
  if rising_edge(p0) then
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

wmask0<=(sampling_reg7 & sampling_reg6 & sampling_reg5 & sampling_reg4 & sampling_reg3 & sampling_reg2 & sampling_reg1 & sampling_reg0);

end x;
