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

component ds_top
  port
  (
    clk             : in std_logic;
    rst             : in std_logic;
    vsync           : in std_logic;
    ds2_dat         : in std_logic;
    ds2_cmd         : out std_logic;
    ds2_att         : out std_logic;
    ds2_clk         : out std_logic;
    ds2_ack         : in std_logic;
    analog          : in std_logic;

    stick_lx        : out std_logic_vector(7 downto 0);
    stick_ly        : out std_logic_vector(7 downto 0);
    stick_rx        : out std_logic_vector(7 downto 0);
    stick_ry        : out std_logic_vector(7 downto 0);
    key_r1          : out std_logic;
    key_r2          : out std_logic;
    key_l1          : out std_logic;
    key_l2          : out std_logic;
    key_triangle    : out std_logic;
    key_square      : out std_logic;
    key_circle      : out std_logic;
    key_cross       : out std_logic;
    key_up          : out std_logic;
    key_down        : out std_logic;
    key_left        : out std_logic;
    key_right       : out std_logic;
    key_start       : out std_logic;
    key_select      : out std_logic;
    key_lstick      : out std_logic;
    key_rstick      : out std_logic;
    debug1          : out std_logic_vector(7 downto 0);
    debug2          : out std_logic_vector(7 downto 0)
    );
end component;

  constant CLKPERIOD_clk   : time := 31.74 ns;
  constant CLKPERIOD_vsync : time := 20000000 ns;
  constant CLKPERIOD_dat   : time := 16000 ns;
  --
  signal clk              : std_logic;
  signal reset            : std_logic;
  signal vsync            : std_logic;

  signal ds2_cmd          : std_logic;
  signal ds2_dat          : std_logic;
  signal ds2_att          : std_logic;
  signal ds2_clk          : std_logic;
  signal analog           : std_logic;

  signal key_up           : std_logic;

begin
 	-- Instantiate the Unit Under Test (UUT)
  u0 : entity work.dualshock2
    port map (
    clk         => clk,
    rst         => reset,
    vsync       => vsync,
    ds2_dat     => ds2_dat,
    ds2_cmd     => ds2_cmd,
    ds2_att     => ds2_att,
    ds2_clk     => ds2_clk,
    ds2_ack     => '0',
    analog      => analog,
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
    wait for 1 ms;
    reset <= '0';
    wait;
  end process;

  p_dat : process
  begin
    ds2_dat <= '0';
    wait for CLKPERIOD_dat / 2;
    ds2_dat <= '1';
    wait for CLKPERIOD_dat - (CLKPERIOD_dat / 2);
  end process;

  p_mode_sw : process
  begin
    analog <= '0';
    wait for 30 ms;
    analog <= '1';
    wait;
  end process;

end behavior;

