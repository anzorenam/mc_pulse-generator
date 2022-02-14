library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pulse_delay is
generic(onehot_width: natural:= 1024);
port (p0,p1,p2,p3: in std_logic;
make_delay: in std_logic;
ctrl_rand: in std_logic_vector (2 downto 0);
w_pattern: in std_logic_vector (onehot_width-1 downto 0);
pulse_out: out std_logic);
end entity;

architecture x of pulse_delay is
signal Tsync, capture,local_rst: std_logic;
signal sampling_reg0,sampling_reg1,sampling_reg2,sampling_reg3: std_logic_vector (onehot_width/8-1 downto 0);
signal sampling_reg4,sampling_reg5,sampling_reg6,sampling_reg7: std_logic_vector (onehot_width/8-1 downto 0);
signal c_pattern,wmask: std_logic_vector(onehot_width-1 downto 0);

begin

process(p0,local_rst)
begin
  if local_rst='1' then
    for j in 0 to onehot_width/8-1 loop
      sampling_reg0(j)<='0';
    end loop;
  else
    if rising_edge(p0) then
      sampling_reg0(0)<='1';
      for j in 1 to onehot_width/8-1 loop
        sampling_reg0(j)<=sampling_reg7(j-1);
      end loop;
    end if;
  end if;
end process;

process(p1,local_rst)
begin
  if local_rst='1' then
    for j in 0 to onehot_width/8-1 loop
      sampling_reg1(j)<='0';
    end loop;
  else
    if rising_edge(p1) then
      for j in 0 to onehot_width/8-1 loop
        sampling_reg1(j)<=sampling_reg0(j);
      end loop;
    end if;
  end if;
end process;

process(p2,local_rst)
begin
  if local_rst='1' then
    for j in 0 to onehot_width/8-1 loop
      sampling_reg2(j)<='0';
    end loop;
  else
    if rising_edge(p2) then
      for j in 0 to onehot_width/8-1 loop
        sampling_reg2(j)<=sampling_reg1(j);
      end loop;
    end if;
  end if;
end process;

process(p3,local_rst)
begin
  if local_rst='1' then
    for j in 0 to onehot_width/8-1 loop
      sampling_reg3(j)<='0';
    end loop;
  else
    if rising_edge(p3) then
      for j in 0 to onehot_width/8-1 loop
        sampling_reg3(j)<=sampling_reg2(j);
      end loop;
    end if;
  end if;
end process;

process(p0,local_rst)
begin
  if local_rst='1' then
    for j in 0 to onehot_width/8-1 loop
      sampling_reg4(j)<='0';
    end loop;
  else
    if falling_edge(p0) then
      for j in 0 to onehot_width/8-1 loop
        sampling_reg4(j)<=sampling_reg3(j);
      end loop;
    end if;
  end if;
end process;

process(p1,local_rst)
begin
  if local_rst='1' then
    for j in 0 to onehot_width/8-1 loop
      sampling_reg5(j)<='0';
    end loop;
  else
    if falling_edge(p1) then
      for j in 0 to onehot_width/8-1 loop
        sampling_reg5(j)<=sampling_reg4(j);
      end loop;
    end if;
  end if;
end process;

process(p2,local_rst)
begin
  if local_rst='1' then
    for j in 0 to onehot_width/8-1 loop
      sampling_reg6(j)<='0';
    end loop;
  else
    if falling_edge(p2) then
      for j in 0 to onehot_width/8-1 loop
        sampling_reg6(j)<=sampling_reg5(j);
      end loop;
    end if;
  end if;
end process;

process(p3,local_rst)
begin
  if local_rst='1' then
    for j in 0 to onehot_width/8-1 loop
      sampling_reg7(j)<='0';
    end loop;
  else
    if falling_edge(p3) then
      for j in 0 to onehot_width/8-1 loop
        sampling_reg7(j)<=sampling_reg6(j);
      end loop;
    end if;
  end if;
end process;

process(local_rst,Tsync)
begin
  if local_rst='1' then
    capture<='0';
  else
    if rising_edge(Tsync) then
      capture<='1';
    end if;
  end if;
end process;

gen_connection:
for j in 0 to onehot_width/8-1 generate
  wmask(8*(j+1)-1 downto 8*j)<=(sampling_reg7(j) & sampling_reg6(j) & sampling_reg5(j) & sampling_reg4(j) & sampling_reg3(j) & sampling_reg2(j) & sampling_reg1(j) & sampling_reg0(j));
end generate;

c_pattern<=w_pattern and wmask when (local_rst='0' and make_delay='1') else
           (others=>'0');

Tsync<='0' when (local_rst='1') else
       '0' when (make_delay='0') else
       '1' when (c_pattern/=(c_pattern'range=>'0')) else
       '0';

local_rst<='1' when (ctrl_rand="001" or ctrl_rand="101") else
           '0';

pulse_out<=capture;

end x;
