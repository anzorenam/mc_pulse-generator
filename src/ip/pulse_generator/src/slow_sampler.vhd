library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity slow_sampler is
port (gclk,make_delay,local_rst: in std_logic;
ctrl_signal: in std_logic_vector (3 downto 0);
w_pattern: in std_logic_vector (23 downto 0);
c_pat0,c_pat1: in std_logic_vector (7 downto 0);
c_pat2,c_pat3: out std_logic;
pulse_out: out std_logic);
end entity;

architecture x of slow_sampler is
signal Tsync,Fsync,cpat0,cpat1: std_logic;
signal cpat2,cpat3,cpat4,cpat5: std_logic;
signal capture0,capture1: std_logic;
signal wp0: std_logic_vector (7 downto 0);
signal wmask1,wmask2,wp2: unsigned (7 downto 0);

begin

process(gclk)
begin
  if rising_edge(gclk) then
    if local_rst='1' then
      wmask1<="00000001";
      cpat0<='0';
      cpat1<='0';
    else
      if make_delay='1' then
        if wmask1="00010100"then
          wmask1<=wmask1-1;
          cpat0<='1';
          cpat1<='0';
        elsif wmask1="00001010" then
          wmask1<=wmask1-1;
          cpat0<='0';
          cpat1<='1';
        elsif wmask1="00000000" then
          wmask1<=wmask1;
          cpat0<='0';
          cpat1<='0';
        else
          wmask1<=wmask1-1;
          cpat0<='0';
          cpat1<='0';
        end if;
      else
        if ctrl_signal="0111" then
          wmask1<=wp2;
          cpat0<='0';
          cpat1<='0';
        else
          wmask1<=wmask1;
          cpat0<='0';
          cpat1<='0';
        end if;
      end if;
    end if;
  end if;
end process;

process(gclk)
begin
  if falling_edge(gclk) then
    if local_rst='1' then
      wmask2<="00000001";
      cpat2<='0';
      cpat3<='0';
    else
      if make_delay='1' then
        if wmask2="00010101"then
          wmask2<=wmask2-1;
          cpat2<='1';
          cpat3<='0';
        elsif wmask2="00001011" then
          wmask2<=wmask2-1;
          cpat2<='0';
          cpat3<='1';
        elsif wmask2="00000000" then
          wmask2<=wmask2;
          cpat2<='0';
          cpat3<='0';
        else
          wmask2<=wmask2-1;
          cpat2<='0';
          cpat3<='0';
        end if;
      else
        if ctrl_signal="0111" then
          wmask2<=wp2;
          cpat2<='0';
          cpat3<='0';
        else
          wmask2<=wmask2;
          cpat2<='0';
          cpat3<='0';
        end if;
      end if;
    end if;
  end if;
end process;

process(Tsync,local_rst)
begin
  if local_rst='1' then
    capture0<='0';
  else
    if rising_edge(Tsync) then
      capture0<='1';
    end if;
  end if;
end process;

process(Fsync,local_rst)
begin
  if local_rst='1' then
    capture1<='0';
  else
    if rising_edge(Fsync) then
      capture1<='1';
    end if;
  end if;
end process;

Tsync<='0' when (local_rst='1') else
       '0' when (make_delay='0') else
       '1' when (cpat4='1' and c_pat0/="00000000") else
       '0';

Fsync<='0' when (local_rst='1') else
       '0' when (make_delay='0') else
       '1' when (cpat5='1' and c_pat1/="00000000") else
       '0';

pulse_out<=capture0 and not(capture1);
wp2<=unsigned(w_pattern(23 downto 16));
wp0<=w_pattern(7 downto 0);
cpat4<=cpat0 or cpat2;
cpat5<=cpat1 or cpat3;
c_pat2<=cpat4;
c_pat3<=cpat5;

end x;
