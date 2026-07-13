library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity urnd_generator is
port(gclk,full_urnd: in std_logic;
seed: in std_logic_vector (23 downto 0);
ctrl_signal: in std_logic_vector (3 downto 0);
wren_urnd: out std_logic;
urnd: out std_logic_vector (15 downto 0));
end entity;

architecture x of urnd_generator is
signal local_hab: std_logic;
signal lfsr,init_seed: unsigned (79 downto 0);

begin

process(gclk)
begin
  if rising_edge(gclk) then
    if ctrl_signal="0000" then
      lfsr<=init_seed;
    else
      if local_hab='1' then
        lfsr(79 downto 16)<=lfsr(63 downto 0);
        for j in 0 to 15 loop
          lfsr(15-j)<=lfsr(79-j) xor lfsr(78-j) xor lfsr(42-j) xor lfsr(41-j);
        end loop;
      end if;
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    if ctrl_signal="0001" then
      if full_urnd='0' then
        local_hab<='1';
      else
        local_hab<='0';
      end if;
    else
      local_hab<='0';
    end if;
  end if;
end process;

process(gclk)
begin
  if rising_edge(gclk) then
    wren_urnd<=local_hab;
  end if;
end process;

init_seed(79 downto 24)<=(others=>'0');
init_seed(23 downto 0)<=unsigned(seed);
urnd<=std_logic_vector(lfsr(15 downto 0));

end x;
