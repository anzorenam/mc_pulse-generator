library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity event_generator is
generic(Nch: natural:= 16;
rate_mask: natural:= 25770;  -- default rate = 1.5 kHz at 250 MHz clk
init_seed0: natural:= 100;
bin_width: natural:= 10;
urnd_width: natural:= 14;
onehot_width: natural:= 128;
rom_init: string:= "inverse_sample.mem");
port(gclk_in0,grst: in std_logic;
pulse_event: out std_logic_vector (Nch-1 downto 0));
end entity;

architecture x of event_generator is
signal p0,p1,p2,p3: std_logic;
signal trigger_aux: std_logic;
signal hit_init,hit_aux,pulse_aux: std_logic_vector (Nch-1 downto 0);

component clkgen is
port(clk_in1: in std_logic;
clk_out1,clk_out2,clk_out3,clk_out4: out std_logic);
end component;

component main_control is
generic(Nch: natural);
port(gclk,grst: in std_logic;
trigger_signal: in std_logic;
hit_pattern:in std_logic_vector (Nch-1 downto 0);
hit_signal: out std_logic_vector (Nch-1 downto 0));
end component;

component poisson_generator is
generic(rate_mask: natural;
init_seed: natural);
port(gclk,grst: in std_logic;
trigger_signal: out std_logic);
end component;

component single_generator is
generic(init_seed: natural;
bin_width: natural;
urnd_width: natural;
onehot_width: natural;
rom_init: string);
port(p0,p1,p2,p3: in std_logic;
grst,make_event: in std_logic;
pulse_event: out std_logic);
end component;

begin

clkgen0: clkgen
port map(clk_in1=>gclk_in0,
         clk_out1=>p0,
         clk_out2=>p1,
         clk_out3=>p2,
         clk_out4=>p3
);

main_fsm: main_control
generic map(Nch=>Nch)
port map(gclk=>p0,
         grst=>grst,
         trigger_signal=>trigger_aux,
         hit_pattern=>hit_init,
         hit_signal=>hit_aux
);

poisson: poisson_generator
generic map(rate_mask=>rate_mask,
init_seed=>init_seed0)
port map(gclk=>p0,
         grst=>grst,
         trigger_signal=>trigger_aux
);

gen_channels:
for j in 0 to Nch-1 generate
  gen_channel: single_generator
  generic map(init_seed=>init_seed0+j,
  bin_width=>bin_width,
  urnd_width=>urnd_width,
  onehot_width=>onehot_width,
  rom_init=>rom_init)
  port map(p0=>p0,
           p1=>p1,
           p2=>p2,
           p3=>p3,
           grst=>grst,
           make_event=>hit_aux(j),
           pulse_event=>pulse_aux(j)
  );
end generate;

hit_init<=(others=>'1');
pulse_event<=pulse_aux;

end x;
