library ieee;
library unisim;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use unisim.vcomponents.all;

entity address_gen is
generic(addr_width: natural:= 27);
port(clk,i_rst: in std_logic;
i_wen,i_ren: in std_logic;
waddr,raddr: out unsigned (addr_width-1 downto 0));
end entity;

architecture x of address_gen is
signal write_add,read_add: unsigned (addr_width-4 downto 0);
begin

process(clk)
begin
  if rising_edge(clk) then
    if i_rst='1' then
      write_add<=(others=>'0');
    else
      if i_wen='1' then
        write_add<=write_add+1;
      end if;
    end if;
  end if;
end process;

process(clk)
begin
  if rising_edge(clk) then
    if i_rst='1' then
      read_add<=(others=>'0');
    else
      if i_ren='1' then
        read_add<=read_add+1;
      end if;
    end if;
  end if;
end process;

waddr(addr_width-1 downto 3)<=write_add;
raddr(addr_width-1 downto 3)<=read_add;
waddr(2 downto 0)<="000";
raddr(2 downto 0)<="000";

end x;
