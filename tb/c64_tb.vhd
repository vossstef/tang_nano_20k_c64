--
-- c64 tb
--

use std.textio.ALL;
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity c64_tb is
end;

architecture c64_tb of c64_tb is

  constant CLKPERIOD_27MHz : time := 37.037 ns;

  --
  signal tmds_clk_n       : std_logic;
  signal tmds_clk_p       : std_logic;
  signal tmds_d_n         : std_logic_vector(2 downto 0);
  signal tmds_d_p         : std_logic_vector(2 downto 0);
  --
  signal O_AUDIO          :  std_logic;
  --
  signal I_CLK_REF        :  std_logic;
 --
  signal IEC_ATN          :  std_logic;
  signal IEC_CLOCK        :  std_logic;
  signal IEC_DATA         :  std_logic;
 
  signal push_reset_n     : std_logic;
  signal User_Button_n    : std_logic;

  signal joy             : std_logic_vector(3 downto 0);
  signal joy_fire        : std_logic;
 
  component tang_nano_20k_c64_top
  generic (
    sysclk_frequency : integer := 315; -- Sysclk frequency * 10 (31.5Mhz)
    mister           : integer := 0    -- 0:no, 1:yes
    );
  port
  (
    clk_27mhz   : in std_logic;
    reset       : in std_logic; -- S2 button
    user        : in std_logic; -- S1 button
    led         : out std_logic_vector(5 downto 0);
    btn         : in std_logic_vector(4 downto 0);

    -- SPI interface Sipeed M0S Dock external BL616 uC
    mosi        : in std_logic; -- spi MOSI / ps2_data
    miso        : out std_logic;-- spi MISO / ps2_clk
    csn         : in std_logic; -- spi CSn
    sck         : in std_logic; -- spi CLK
    irq_n       : out std_logic; -- spi irq

    -- SPI interface onboard BL616 uC
    spi_csn     : in std_logic;
    spi_sclk    : in std_logic;
    spi_dat     : in std_logic;
    spi_dir     : out std_logic; -- unusable due to hw bug / capacitor
    jtag_tck    : out std_logic; -- replacement spi_dir
    --
    tmds_clk_n  : out std_logic;
    tmds_clk_p  : out std_logic;
    tmds_d_n    : out std_logic_vector( 2 downto 0);
    tmds_d_p    : out std_logic_vector( 2 downto 0);
    -- sd interface
    sd_clk      : out std_logic;
    sd_cmd      : inout std_logic;
    sd_dat      : inout std_logic_vector(3 downto 0);
    --  debug       : out std_logic_vector(4 downto 0);
    ws2812      : out std_logic;
    -- "Magic" port names that the gowin compiler connects to the on-chip SDRAM
    O_sdram_clk  : out std_logic;
    O_sdram_cke  : out std_logic;
    O_sdram_cs_n : out std_logic;            -- chip select
    O_sdram_cas_n : out std_logic;           -- columns address select
    O_sdram_ras_n : out std_logic;           -- row address select
    O_sdram_wen_n : out std_logic;           -- write enable
    IO_sdram_dq  : inout std_logic_vector(31 downto 0); -- 32 bit bidirectional data bus
    O_sdram_addr : out std_logic_vector(10 downto 0);  -- 11 bit multiplexed address bus
    O_sdram_ba   : out std_logic_vector(1 downto 0);     -- two banks
    O_sdram_dqm  : out std_logic_vector(3 downto 0);     -- 32/4
    -- Gamepad
    joystick_clk  : out std_logic;
    joystick_mosi : out std_logic;
    joystick_miso : in std_logic;
    joystick_cs   : out std_logic
    );
  end component;

begin
  u0 : tang_nano_20k_c64_top
    port map (
      tmds_clk_n      => tmds_clk_n,
      tmds_clk_p      => tmds_clk_p,
      tmds_d_n        => tmds_d_n,
      tmds_d_p        => tmds_d_p, 
      --
      clk_27mhz       => I_CLK_REF,
      reset           => reset,
      user            => user
    );

  p_clk_27mhz  : process
  begin
    I_CLK_REF <= '0';
    wait for CLKPERIOD_27MHz / 2;
    I_CLK_REF <= '1';
    wait for CLKPERIOD_27MHz - (CLKPERIOD_27MHz / 2);
  end process;

  p_rst : process
  begin
    reset <= '0';
    wait for 100 ns;
    reset <= '1';
    wait;
  end process;

  user <= '1';
  btn  <= b"11111";

end c64_tb;

