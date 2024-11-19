--
-- dualshock tb
--
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.ALL;
use std.textio.ALL;

entity ds_tb is
end ds_tb;

architecture behavior of ds_tb is

  constant CLKPERIOD_clk   : time := 31.74 ns;
  constant CLKPERIOD_vsync : time := 10000 ns;  --  20000000 ns;
  --
  signal clk              : std_logic;
  signal reset            : std_logic;
  signal vsync            : std_logic;

  signal ds2_cmd          : std_logic;
  signal ds2_att          : std_logic;
  signal ds2_clk          : std_logic;

  signal key_up           : std_logic;

begin
 	-- Instantiate the Unit Under Test (UUT)
  u0 : entity work.dualshock2
    port map (
    clk         => clk,
    rst         => reset,
    vsync       => vsync,
    ds2_dat     => '1', -- MOSI
    ds2_cmd     => ds2_cmd,
    ds2_att     => ds2_att,
    ds2_clk     => ds2_clk,
    ds2_ack     => '0',
    stick_lx    => open,
    stick_ly    => open,
    stick_rx    => open,
    stick_ry    => open,
    key_up      => key_up,
    key_down    => open,
    key_left    => open,
    key_right   => open,
    key_l1      => open,
    key_l2      => open,
    key_r1      => open,
    key_r2      => open,
    key_triangle => open, 
    key_square  => open,
    key_circle  => open,
    key_cross   => open,
    key_start   => open,
    key_select  => open,
    key_lstick  => open,
    key_rstick  => open,
    debug1      => open,
    debug2      => open
      );

   -- Clock process definitions
  p_clk : process
  begin
    clk <= '0';
    wait for CLKPERIOD_clk / 2;
    clk <= '1';
    wait for CLKPERIOD_clk - (CLKPERIOD_clk / 2);
  end process;

  p_vsync  : process
  begin
    vsync <= '0';
    wait for CLKPERIOD_vsync / 2;
    vsync <= '1';
    wait for CLKPERIOD_vsync - (CLKPERIOD_vsync / 2);
  end process;

  p_rst : process
  begin
    reset <= '1';
    wait for 100 ns;
    reset <= '0';
    wait;
  end process;

end behavior;

