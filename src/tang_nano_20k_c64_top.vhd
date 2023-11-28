-------------------------------------------------------------------------
--  C64 Top level for Tang Nano
--  2023 Stefan Voss
--  based on the work of many others
--
--  FPGA64 is Copyrighted 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
--  http://www.syntiac.com/fpga64.html
--
-------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.ALL;
library work;
use work.keyboard_matrix_pkg.all;

entity tang_nano_20k_c64_top is
  generic (
    resetCycles : integer := 4095;
    sysclk_frequency : integer := 315 -- Sysclk frequency * 10 (31.5Mhz)
  );
  port
  (
    clk_27mhz   : in std_logic;
    reset_btn   : in std_logic;
    s2_btn      : in std_logic;
    led         : out std_logic_vector(1 downto 0);
    btn         : in std_logic_vector(4 downto 0);

    -- Sipeed M0S Dock SPI interface
    mosi        : in std_logic; -- spi MOSI / ps2_data
    miso        : out std_logic;-- spi MISO / ps2_clk
    csn         : in std_logic; -- spi CSn
    sck         : in std_logic; -- spi CLK

    tmds_clk_n  : out std_logic;
    tmds_clk_p  : out std_logic;
    tmds_d_n    : out std_logic_vector( 2 downto 0);
    tmds_d_p    : out std_logic_vector( 2 downto 0);
    -- sd interface
    sd_clk      : out std_logic; -- SCLK
    sd_cmd      : out std_logic; -- MOSI
    sd_dat0     : in std_logic;  -- MISO
    sd_dat1     : in std_logic;  -- unused
    sd_dat2     : in std_logic;  -- unused
    sd_dat3     : out std_logic; -- CSn
--  debug       : out std_logic_vector(4 downto 0);
    ws2812      : out std_logic;
    -- reserved for onboard BL616 controller SPI interface
    spi_csn     : in std_logic;
    spi_sclk    : in std_logic;
    spi_dat     : in std_logic;
    spi_dir     : in std_logic;
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
end;

architecture Behavioral_top of tang_nano_20k_c64_top is

signal clk_pixel, clk_shift, shift_locked  : std_logic;
signal clk64, clk32, clk32_locked, clk16, clk8: std_logic;

attribute syn_keep : integer;
attribute syn_keep of clk32 : signal is 1;
attribute syn_keep of clk16 : signal is 1;

signal R_btn_joy: std_logic_vector(4 downto 0);

signal hsync_31k : std_logic;
signal vsync_31k : std_logic;
signal r_31k,g_31k,b_31k : std_logic_vector(7 downto 0);

signal spare        : std_logic_vector(5 downto 0);
signal reset        : std_logic := '1';
signal reset_cnt    : integer range 0 to resetCycles := 0;

signal audio_data_l  : std_logic_vector(17 downto 0);
signal audio_data_r  : std_logic_vector(17 downto 0);

signal enablePixel  : std_logic;

-- external memory
signal ramAddr     : unsigned(15 downto 0);
signal ramDataIn   : unsigned(7 downto 0);
signal ramDataOut  : unsigned(15 downto 0);
signal ramDataIn_vec : std_logic_vector(15 downto 0);

signal dram_addr    : std_logic_vector(21 downto 0);
signal ram_CE       : std_logic;
signal ram_We       : std_logic;

-- IEC
signal  iec_data_o  : std_logic;
signal  iec_data_i  : std_logic;
signal  iec_clk_o   : std_logic;
signal  iec_clk_i   : std_logic;
signal  iec_atn_o   : std_logic;
signal  iec_atn_i   : std_logic;

  -- keyboard
signal newScanCode  : std_logic;
signal recvByte     : std_logic_vector(10 downto 0);
signal disk_num     : std_logic_vector(7 downto 0) := (others => '0');
signal joyKeys      : std_logic_vector(6 downto 0);
signal reset_key    : std_logic := '0';
signal disk_reset   : std_logic;

signal idle   : std_logic;
-- CONTROLLER DUALSHOCK
signal dscjoyKeys   : std_logic_vector(6 downto 0);
signal dsc_joy_rx0  : std_logic_vector(7 downto 0);
signal dsc_joy_rx1  : std_logic_vector(7 downto 0);

-- joystick interface
signal  joyA        : std_logic_vector(6 downto 0) := (others => '1');
signal  joyB        : std_logic_vector(6 downto 0) := (others => '1');
signal  joy_sel     : std_logic := '0'; -- BTN2 toggles joy A/B
signal  btn_debounce: std_logic_vector(6 downto 0);
signal  btn_deb     : std_logic;

signal ramCE       :  std_logic;
signal ramWe       :  std_logic;
signal romCE       :  std_logic;

signal ntscMode:  std_logic := '0';
signal hsync       :  std_logic;
signal vsync       :  std_logic;
signal hblank      :  std_logic;
signal vblank      :  std_logic;
signal r           :  unsigned(7 downto 0);
signal g           :  unsigned(7 downto 0);
signal b           :  unsigned(7 downto 0);

signal pb_out      : std_logic_vector(7 downto 0);
signal pc2_n       : std_logic;
signal pb_in       : std_logic_vector(7 downto 0);
signal flag2_n     : std_logic;

signal ps2_key     : std_logic_vector(10 downto 0);

-- BL616 interfaces
signal mcu_start      : std_logic;
signal mcu_hid_strobe : std_logic;
signal data_in_start  : std_logic;
signal mcu_data_out   : std_logic_vector(7 downto 0);
signal hid_data_out   : std_logic_vector(7 downto 0);
signal mouse          : std_logic_vector(5 downto 0);
signal keyboard       : keyboard_t;

component CLKDIV
    generic (
        DIV_MODE : STRING := "2";
        GSREN: in string := "false"
    );
    port (
        CLKOUT: out std_logic;
        HCLKIN: in std_logic;
        RESETN: in std_logic;
        CALIB: in std_logic
    );
end component;

COMPONENT GSR
 PORT (
 GSRI:IN std_logic
 );
end component;

begin
  -- block interfaces and pins
  spare(0) <= sd_dat1;
  spare(1) <= sd_dat2;
  spare(2) <= spi_csn;
  spare(3) <= spi_sclk;
  spare(4) <= spi_dat;
  spare(5) <= spi_dir;

-- https://store.curiousinventor.com/guides/PS2/
--  Digital Button State Mapping (which bits of bytes 4 & 5 goes to which button):
--              dualshock buttons: 0:(Left Down Right Up Start Right3 Left3 Select)  
--                                 1:(Square X O Triangle Right1 Left1 Right2 Left2)
gamepad: entity work.dualshock_controller
generic map (
 FREQ => 32000000
)
port map (
 clk         => clk32,     -- Any main clock faster than 1Mhz 
 I_RSTn      => not reset, --  MAIN RESET

 O_psCLK => joystick_clk,  --  psCLK CLK OUT
 O_psSEL => joystick_cs,   --  psSEL OUT
 O_psTXD => joystick_mosi, --  psTXD OUT
 I_psRXD => joystick_miso, --  psRXD IN

 O_RXD_1 => dsc_joy_rx0,  --  RX DATA 1 (8bit)
 O_RXD_2 => dsc_joy_rx1,  --  RX DATA 2 (8bit)
 O_RXD_3 => open,         --  RX DATA 3 (8bit)
 O_RXD_4 => open,         --  RX DATA 4 (8bit)
 O_RXD_5 => open,         --  RX DATA 5 (8bit)
 O_RXD_6 => open,         --  RX DATA 6 (8bit) 

 I_CONF_SW => '0',        --  Dualshook Config  ACTIVE-HI
 I_MODE_SW => '1',        --  Dualshook Mode Set DIGITAL PAD 0, ANALOG PAD 1
 I_MODE_EN => '0',        --  Dualshook Mode Control  OFF 0, ON 1
 I_VIB_SW  => (others =>'0') --  Vibration SW  VIB_SW[0] Small Moter OFF 0, ON 1
                          --  VIB_SW[1] Bic Moter   OFF 0, ON 1 (Dualshook Only)
 );

led_ws2812: entity work.ws2812led
  port map
  (
   clk       => clk_27mhz,
   WS2812    => ws2812
  );

c1541_sd : entity work.c1541_sd
  port map
  (
    clk32         => clk32,
    clk_spi_ctrlr => clk16,
    reset         => disk_reset,
    
    disk_num      => ("00" & disk_num),

    iec_atn_i     => iec_atn_o,
    iec_data_i    => iec_data_o,
    iec_clk_i     => iec_clk_o,

    iec_atn_o     => iec_atn_i,
    iec_data_o    => iec_data_i,
    iec_clk_o     => iec_clk_i,

    sd_miso       => sd_dat0,
    sd_cs_n       => sd_dat3,
    sd_mosi       => sd_cmd,
    sd_sclk       => sd_clk,
   
    -- Userport parallel bus to 1541 disk
    par_data_i    => std_logic_vector(pb_out),
    par_stb_i     => pc2_n,
    par_data_o    => pb_in,
    par_stb_o     => flag2_n,

    dbg_act       => led(1)  -- LED floppy indicator
  );

  reset <= reset_btn;
  disk_reset <= reset or reset_key;

  rgb2vga: entity work.rgb2vga_scandoubler
  generic map (
      WIDTH => 24 )
  port map (
      clock     => clk32,
      clken     => enablepixel,
      clk_pixel => clk_pixel,
      --
      r_in      => std_logic_vector(r),
      g_in      => std_logic_vector(g),
      b_in      => std_logic_vector(b),
      hSync_in  => hsync,
      vSync_in  => vsync,
      --
      r_out     => r_31k,
      g_out     => g_31k,
      b_out     => b_31k,
      hSync_out => hsync_31k,
      vSync_out => vsync_31k
  );

  vga2hdmi_instance: entity work.C64_DBLSCAN 
  port map (
   CLK               => clk32,
   clk_5x_pixel      => clk_shift,
   clk_pixel         => clk_pixel,
   I_R               => r_31k,
   I_G               => g_31k,
   I_B               => b_31k,
   I_HSYNC           => hsync_31k,
   I_VSYNC           => vsync_31k,
   I_AUDIO_PCM_L     => audio_data_l(17 downto 2),
   I_AUDIO_PCM_R     => audio_data_r(17 downto 2),
   tmds_clk_n        => tmds_clk_n,
   tmds_clk_p        => tmds_clk_p,
   tmds_d_n          => tmds_d_n,
   tmds_d_p          => tmds_d_p
  );

  dram_addr(15 downto 0)  <= std_logic_vector(ramAddr);
  dram_addr(21 downto 16) <= (others => '0');
  
  ramDataOut(15 downto 8) <= (others => '0');

  dram_inst: entity work.sdram
   port map(
    -- SDRAM side interface
    sd_clk    => O_sdram_clk,   -- sd clock
    sd_cke    => O_sdram_cke,   -- clock enable
    sd_data   => IO_sdram_dq,   -- 32 bit bidirectional data bus
    sd_addr   => O_sdram_addr,  -- 11 bit multiplexed address bus
    sd_dqm    => O_sdram_dqm,   -- two byte masks
    sd_ba     => O_sdram_ba,    -- two banks
    sd_cs     => O_sdram_cs_n,  -- a single chip select
    sd_we     => O_sdram_wen_n, -- write enable
    sd_ras    => O_sdram_ras_n, -- row address select
    sd_cas    => O_sdram_cas_n, -- columns address select
    -- cpu/chipset interface
    clk       => clk64,         -- sdram is accessed at 64MHz
    reset_n   => clk32_locked,  -- init signal after FPGA config to initialize RAM
    ready     => open,          -- ram is ready and has been initialized
    refresh   => idle,          -- chipset requests a refresh cycle
    din       => std_logic_vector(ramDataOut), -- data input from chipset/cpu
    dout(7 downto 0)  => ramDataIn, --ramDataIn_vec,
    dout(15 downto 8) => open,
    addr      => dram_addr,      -- 22 bit word address
    ds        => (others => '0'),-- upper/lower data strobe R = low and W = low
    cs        => ramCE,        -- cpu/chipset requests read/wrie
    we        => ramWe         -- cpu/chipset requests write
  );

  gsr_inst: GSR
  PORT MAP(
  GSRI => not reset_btn
);

mainclock: entity work.Gowin_rPLL
    port map (
        clkout  => clk64,
        lock    => clk32_locked,
        reset   => reset_btn,
        clkoutd => clk32,
        clkin   => clk_27mhz
    );

clock16m: CLKDIV
    generic map (
        DIV_MODE => "2",
        GSREN  => "false"
    )
    port map (
        CALIB  => '0',
        clkout => clk16,
        hclkin => clk32,
        resetn => clk32_locked
        );

hdmi_clockgenerator: entity work.Gowin_rPLL_hdmi
port map (
      clkin  => clk_27mhz,
      clkout => clk_shift,
      reset  => not clk32_locked,
      lock   => shift_locked
    );

clock_divider2: CLKDIV
generic map (
    DIV_MODE => "5",
    GSREN  => "false"
)
port map (
    CALIB  => '0',
    clkout => clk_pixel,
    hclkin => clk_shift,
    resetn => shift_locked
  );

-- process to toggle joy A/B with BTN2
process(clk32)
begin
  if rising_edge(clk32) then
    if vsync = '1' then
      if s2_btn = '1' and btn_deb = '0' then  --rising edge of button
        joy_sel <= not joy_sel;
      end if;
      btn_deb <= s2_btn;
    end if;
  end if;
end process;

led(0) <= joy_sel;

process(clk32)
begin
  if rising_edge(clk32) then
     R_btn_joy(4 downto 0) <= btn(4 downto 0);
  end if;
end process;

-- 4 3 2 1 0 digital
-- F R L D U position
--    triangle (4)
-- square(7) circle (5)
--       X (6)
-- fire Left 1
dscjoyKeys <= not("11" & dsc_joy_rx1(2) & dsc_joy_rx1(5) & dsc_joy_rx1(7) & dsc_joy_rx1(6) & dsc_joy_rx1(4));
joyKeys <= not ("11" & R_btn_joy(4) & R_btn_joy(0) & R_btn_joy(1) & R_btn_joy(2) & R_btn_joy(3));
joyA <= joyKeys when joy_sel='0' else dscjoyKeys;
joyB <= joyKeys when joy_sel='1' else dscjoyKeys;

-- excess for now
ps2recv: entity work.ps2
  port map (
    clk      => clk32,
    ps2_clk  => miso, --ps2_clk,
    ps2_data => mosi, -- ps2_data,
    ps2_key  => ps2_key
  );

mcu_spi_inst: entity work.mcu_spi 
port map (
  clk => clk32,
  reset => not clk32_locked,

  -- SPI interface to Sipeed M0 Dock BL616 MCU
  spi_io_ss   => csn,      -- SPI CSn
  spi_io_clk  => sck,      -- SPI SCLK
  spi_io_din  => mosi,     -- SPI MOSI
  spi_io_dout => miso,     -- SPI MISO

  -- byte interface to the various core components
  mcu_hid_strobe => mcu_hid_strobe, -- byte strobe for HID target  
  mcu_osd_strobe => open, -- byte strobe for OSD target
  mcu_sdc_strobe => open, -- byte strobe for SD card target
  mcu_start => mcu_start,
  mcu_hid_din => hid_data_out,
  mcu_osd_din => (others => '0'),
  mcu_sdc_din => (others => '0'),
  mcu_dout => mcu_data_out
);

-- decode SPI/MCU data received for human input devices (HID) and
-- convert into ST compatible mouse and keyboard signals
hid_inst: entity work.hid
 port map 
 (
  clk => clk32,
  reset => not clk32_locked,

  -- interface to receive user data from MCU (mouse, kbd, ...)
  data_in_strobe =>mcu_hid_strobe,
  data_in_start => mcu_start,
  data_in => mcu_data_out,
  data_out => hid_data_out,
  mouse => mouse,
  keyboard => keyboard  -- atari st keyboard 2D matrix
 );

fpga64_sid_iec_inst: entity work.fpga64_sid_iec
  port map
  (
  epix         => enablepixel,
  clk32        => clk32,
  reset_n      => clk32_locked,
  bios         => (others => '0'),
  pause        => '0',
  pause_out    => open,
  -- keyboard interface
  keyboard     => keyboard,
  ps2_key      => ps2_key, -- excess for now
  kbd_reset    => '0',
  shift_mod    => (others => '0'),
  reset_key    => reset_key,
  disk_num     => disk_num,

  -- external memory
  ramAddr      => ramAddr,
  ramDin       => ramDataIn,
  ramDout      => ramDataOut(7 downto 0),
  ramCE        => ramCE,
  ramWE        => ramWe,
  io_cycle     => open,
  ext_cycle    => open,
  refresh      => idle,

  cia_mode     => '0',
  turbo_mode   => "00",
  turbo_speed  => "00",

  ntscMode     => '0',
  hsync        => hsync,
  vsync        => vsync,
  r            => r,
  g            => g,
  b            => b,

  game         => '1',
  exrom        => '1', -- set to 0 for cartridge demo
  io_rom       => '0',
  io_ext       => '0',
  io_data      => (others => '0'),
  irq_n        => '1',
  nmi_n        => '1',
  nmi_ack      => open,
  romL         => open,
  romH         => open,
  UMAXromH     => open,
  IOE          => open,
  IOF          => open,
  freeze_key   => open,
  mod_key      => open,
  tape_play    => open,

  -- dma access
  dma_req      => '0',
  dma_cycle    => open,
  dma_addr     => (others => '0'),
  dma_dout     => (others => '0'),
  dma_din      => open,
  dma_we       => '0',
  irq_ext_n    => '1',

  -- joystick interface
  joyA         => JoyA,
  joyB         => joyB,
  pot1         => (others => '0'),
  pot2         => (others => '0'),
  pot3         => (others => '0'),
  pot4         => (others => '0'),

  --SID
  audio_l      => audio_data_l,
  audio_r      => audio_data_r,
  sid_filter   => (others => '0'),
  sid_ver      => (others => '0'),
  sid_mode     => (others => '0'),
  sid_cfg      => (others => '0'),
  sid_fc_off_l => (others => '0'),
  sid_fc_off_r => (others => '0'),
  sid_ld_clk   => '0',
  sid_ld_addr  => (others => '0'),
  sid_ld_data  => (others => '0'),
  sid_ld_wr    => '0',

  -- USER
  pb_i         => unsigned(pb_in),
  std_logic_vector(pb_o) => pb_out,
  pa2_i        => '1',
  pa2_o        => open,
  pc2_n_o      => pc2_n,
  flag2_n_i    => flag2_n,
  sp2_i        => '1',
  sp2_o        => open,
  sp1_i        => '1',
  sp1_o        => open,
  cnt2_i       => '1',
  cnt2_o       => open,
  cnt1_i       => '1',
  cnt1_o       => open,

  -- IEC
  iec_data_o   => iec_data_o,
  iec_data_i   => iec_data_i,
  iec_clk_o    => iec_clk_o,
  iec_clk_i    => iec_clk_i,
  iec_atn_o    => iec_atn_o,

  c64rom_addr  => (others => '0'),
  c64rom_data  => (others => '0'),
  c64rom_wr    => '0',

  cass_motor   => open,
  cass_write   => open,
  cass_sense   => '0',
  cass_read    => '0'
  );

end Behavioral_top;
