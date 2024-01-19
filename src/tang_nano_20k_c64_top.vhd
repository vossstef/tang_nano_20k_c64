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

entity tang_nano_20k_c64_top is
  generic (
    sysclk_frequency : integer := 315 -- Sysclk frequency * 10 (31.5Mhz)
    );
  port
  (
    clk_27mhz   : in std_logic;
    reset       : in std_logic; -- S2 button
    user        : in std_logic; -- S1 button
    led         : out std_logic_vector(5 downto 0);
    btn         : in std_logic_vector(4 downto 0);

    -- SPI interface Sipeed M0S Dock external BL616 uC
    m0s         : inout std_logic_vector(5 downto 0);
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
end;

architecture Behavioral_top of tang_nano_20k_c64_top is

signal clk64, clk32, pll_locked, pll2_locked : std_logic;

attribute syn_keep : integer;
attribute syn_keep of clk64 : signal is 1;
attribute syn_keep of clk32 : signal is 1;

signal R_btn_joy     : std_logic_vector(4 downto 0);
signal audio_data_l  : std_logic_vector(17 downto 0);
signal audio_data_r  : std_logic_vector(17 downto 0);

-- external memory
signal ramAddr      : unsigned(15 downto 0);
signal ramDataIn    : unsigned(7 downto 0);
signal ramDataOut   : unsigned(15 downto 0);
signal ramDataIn_v  : std_logic_vector(15 downto 0);
signal idle         : std_logic;
signal dram_addr    : std_logic_vector(21 downto 0);
signal dram_addr_s  : std_logic_vector(21 downto 0);
signal ram_scramble : std_logic_vector(1 downto 0);
signal ram_ready    : std_logic;
signal cb_D         : std_logic;

-- IEC
signal iec_data_o  : std_logic;
signal iec_data_i  : std_logic;
signal iec_clk_o   : std_logic;
signal iec_clk_i   : std_logic;
signal iec_atn_o   : std_logic;
signal iec_atn_i   : std_logic;

  -- keyboard
signal keyboard_matrix_out : std_logic_vector(7 downto 0);
signal keyboard_matrix_in  : std_logic_vector(7 downto 0);
signal joyUsb       : std_logic_vector(6 downto 0);
signal joyDigital   : std_logic_vector(6 downto 0);
signal disk_reset   : std_logic;
-- CONTROLLER DUALSHOCK
signal joyDS2       : std_logic_vector(6 downto 0);
signal dsc_joy_rx0  : std_logic_vector(7 downto 0);
signal dsc_joy_rx1  : std_logic_vector(7 downto 0);
-- joystick interface
signal  joyA        : std_logic_vector(6 downto 0) := (others => '1');
signal  joyB        : std_logic_vector(6 downto 0) := (others => '1');
signal  joy_sel     : std_logic := '0'; -- toggles joy A/B
signal  btn_debounce: std_logic_vector(6 downto 0);
signal  user_deb    : std_logic;
-- mouse / paddle
signal pot1         : std_logic_vector(7 downto 0);
signal pot2         : std_logic_vector(7 downto 0);
signal mouse_x_pos  : signed(10 downto 0);
signal mouse_y_pos  : signed(10 downto 0);
signal mouse1_en    : std_logic := '0';

signal ramCE       :  std_logic;
signal ramWe       :  std_logic;
signal romCE       :  std_logic;

signal ntscMode    :  std_logic := '0';
signal hsync       :  std_logic;
signal vsync       :  std_logic;
signal r           :  unsigned(7 downto 0);
signal g           :  unsigned(7 downto 0);
signal b           :  unsigned(7 downto 0);

signal pb_out      : std_logic_vector(7 downto 0);
signal pc2_n       : std_logic;
signal pb_in       : std_logic_vector(7 downto 0);
signal flag2_n     : std_logic;

-- BL616 interfaces
signal mcu_start      : std_logic;
signal mcu_sys_strobe : std_logic;
signal mcu_hid_strobe : std_logic;
signal mcu_osd_strobe : std_logic;
signal mcu_sdc_strobe : std_logic;
signal data_in_start  : std_logic;
signal mcu_data_out   : std_logic_vector(7 downto 0);
signal hid_data_out   : std_logic_vector(7 downto 0);
signal osd_data_out   : std_logic_vector(7 downto 0) :=  X"55";
signal sys_data_out   : std_logic_vector(7 downto 0);
signal sdc_data_out   : std_logic_vector(7 downto 0);
signal hid_int        : std_logic;
signal system_scanlines : std_logic_vector(1 downto 0);
signal system_volume  : std_logic_vector(1 downto 0);
signal joystick       : std_logic_vector(7 downto 0);
signal mouse_btns     : std_logic_vector(1 downto 0);
signal mouse_x_cnt    : signed(7 downto 0); -- signed( 8 downto 0);
signal mouse_y_cnt    : signed(7 downto 0); -- signed( 8 downto 0);
signal mouse_strobe   : std_logic;
signal freeze         : std_logic;
signal freeze_sync    : std_logic;
signal c64_pause      : std_logic;
signal old_sync       : std_logic;
signal osd_status     : std_logic;
signal ws2812_color   : std_logic_vector(23 downto 0);
signal system_reset   : std_logic_vector(1 downto 0);
signal disk_chg_trg   : std_logic;
signal disk_chg_trg_d : std_logic;
signal sd_img_size    : std_logic_vector(31 downto 0);
signal sd_img_size_d  : std_logic_vector(31 downto 0);
signal sd_img_mounted : std_logic_vector(3 downto 0);
signal sd_img_mounted_d : std_logic;
signal sd_rd          : std_logic_vector(3 downto 0);
signal sd_wr          : std_logic_vector(3 downto 0);
signal sd_lba         : std_logic_vector(31 downto 0);
signal sd_busy        : std_logic;
signal sd_done        : std_logic;
signal sd_rd_byte_strobe : std_logic;
signal sd_byte_index  : std_logic_vector(8 downto 0);
signal sd_rd_data     : std_logic_vector(7 downto 0);
signal sd_wr_data     : std_logic_vector(7 downto 0);
signal sd_change      : std_logic;
signal sdc_int        : std_logic;
signal sdc_iack       : std_logic;
signal int_ack        : std_logic_vector(7 downto 0);
signal spi_ext        : std_logic;
signal spi_io_din     : std_logic;
signal spi_io_ss      : std_logic;
signal spi_io_clk     : std_logic;
signal spi_io_dout    : std_logic;
signal disk_g64       : std_logic;
signal disk_g64_d     : std_logic;
signal c1541_reset    : std_logic;
signal system_wide_screen : std_logic;
signal system_floppy_wprot : std_logic_vector(1 downto 0);
signal system_port_mouse  : std_logic_vector(1 downto 0);

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

begin
-- ----------------- SPI input parser ----------------------
-- map output data onto both spi outputs
  spi_io_din  <= m0s(1) when spi_ext = '1' else spi_dat;
  spi_io_ss   <= m0s(2) when spi_ext = '1' else spi_csn;
  spi_io_clk  <= m0s(3) when spi_ext = '1' else spi_sclk;
  jtag_tck    <= spi_io_dout; -- onboad bl616 back-up miso signal
  m0s(0)      <= spi_io_dout; -- M0 Dock
  spi_dir     <= spi_io_dout; -- unusable due to hw bug
  m0s(5)      <= 'Z';

-- by default the internal SPI is being used. Once there is
-- a select from the external spi (M0S Dock) , then the connection is being switched
process (clk32, pll_locked)
begin
  if rising_edge(clk32) then
    if pll_locked = '0' then
        spi_ext <= '0';
    elsif m0s(2) = '0' then
        spi_ext <= '1';
    else 
        spi_ext <= spi_ext;
    end if;
  end if;
end process;

-- https://store.curiousinventor.com/guides/PS2/
--  Digital Button State Mapping (which bits of bytes 4 & 5 goes to which button):
--              dualshock buttons: 0:(Left Down Right Up Start Right3 Left3 Select)  
--                                 1:(Square X O Triangle Right1 Left1 Right2 Left2)
gamepad: entity work.dualshock_controller
generic map (
 FREQ => 31500000
)
port map (
 clk         => clk32,     -- Any main clock faster than 1Mhz 
 I_RSTn      => not system_reset(0),   -- MAIN RESET

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

led_ws2812: entity work.ws2812
  port map
  (
   clk    => clk32,
   color  => ws2812_color,
   data   => ws2812
  );

	process(clk32, disk_reset)
    variable reset_cnt : integer range 0 to 2147483647;
    begin
		if disk_reset = '1' then
      disk_chg_trg <= '0';
			reset_cnt := 64000000;
      elsif rising_edge(clk32) then
			if reset_cnt /= 0 then
				reset_cnt := reset_cnt - 1;
			end if;
		end if;

  if reset_cnt = 0 then
    disk_chg_trg <= '1';
  else 
    disk_chg_trg <= '0';
  end if;
end process;

disk_reset <= system_reset(0) or not pll_locked or c1541_reset;

-- rising edge sd_change triggers detection of new disk
process(clk32, pll_locked)
  begin
  if pll_locked = '0' then
    sd_change <= '0';
    disk_g64 <= '0';
    disk_g64_d <= '0';
    sd_img_size_d <= (others => '0');
    sd_img_mounted_d <= '0';
    disk_chg_trg_d <= '0';
    elsif rising_edge(clk32) then
      sd_img_size_d <= sd_img_size;
      sd_img_mounted_d <= sd_img_mounted(0);
      disk_chg_trg_d <= disk_chg_trg;
      disk_g64_d <= disk_g64;
      if (sd_img_size /= sd_img_size_d) or (disk_chg_trg_d = '0' and disk_chg_trg = '1') then
          sd_change  <= '1';
          else
          sd_change  <= '0';
      if sd_img_size >= 333744 then  -- g64 disk selected
        disk_g64 <= '1';
        led(4) <= '0'; -- g64 indicator
      else
        disk_g64 <= '0';
        led(4) <= '1';
      end if;
      if (disk_g64 /= disk_g64_d) then
        c1541_reset  <= '1'; -- reset needed after G64 change
        else
        c1541_reset  <= '0';
        end if;
      end if;
  end if;
end process;

c1541_sd_inst : entity work.c1541_sd
port map
 (
    clk32         => clk32,
    reset         => disk_reset,

    disk_num      =>(others =>'0'),
    disk_change   => sd_change, 
    disk_mount    => '1',
    disk_readonly => system_floppy_wprot(0),
    disk_g64      => disk_g64,

    iec_atn_i     => iec_atn_o,
    iec_data_i    => iec_data_o,
    iec_clk_i     => iec_clk_o,

    iec_atn_o     => iec_atn_i,
    iec_data_o    => iec_data_i,
    iec_clk_o     => iec_clk_i,

    -- Userport parallel bus to 1541 disk
    par_data_i    => pb_out,
    par_stb_i     => pc2_n,
    par_data_o    => pb_in,
    par_stb_o     => flag2_n,

    sd_lba        => sd_lba,
    sd_rd         => sd_rd(0),
    sd_wr         => sd_wr(0),
    sd_ack        => sd_busy,

    sd_buff_addr  => sd_byte_index,
    sd_buff_dout  => sd_rd_data,
    sd_buff_din   => sd_wr_data,
    sd_buff_wr    => sd_rd_byte_strobe,

    led           => led(0),  -- LED floppy indicator

    c1541rom_clk  => '0',
    c1541rom_wr   => '0',
    c1541rom_addr => (others =>'0'),
    c1541rom_data => (others =>'0')
);

sd_rd(3 downto 1) <= "000";
sd_wr(3 downto 1) <= "000";
sdc_iack <= int_ack(3);

sd_card_inst: entity work.sd_card
generic map (
    CLK_DIV  => 1  -- for 32 Mhz clock
  )
    port map (
    rstn            => pll_locked, 
    clk             => clk32,
  
    -- SD card signals
    sdclk           => sd_clk,
    sdcmd           => sd_cmd,
    sddat           => sd_dat,

    -- mcu interface
    data_strobe     => mcu_sdc_strobe,
    data_start      => mcu_start,
    data_in         => mcu_data_out,
    data_out        => sdc_data_out,

    -- interrupt to signal communication request
    irq             => sdc_int,
    iack            => sdc_iack,

    -- output file/image information. Image size is e.g. used by fdc to 
    -- translate between sector/track/side and lba sector
    image_size      => sd_img_size,           -- length of image file
    image_mounted   => sd_img_mounted,

    -- user read sector command interface (sync with clk)
    rstart          => sd_rd,
    wstart          => sd_wr, 
    rsector         => sd_lba,
    rbusy           => sd_busy,
    rdone           => sd_done,           --  done from sd reader acknowledges/clears start

    -- sector data output interface (sync with clk)
    inbyte          => sd_wr_data,        -- sector data output interface (sync with clk)
    outen           => sd_rd_byte_strobe, -- when outen=1, a byte of sector content is read out from outbyte
    outaddr         => sd_byte_index,     -- outaddr from 0 to 511, because the sector size is 512
    outbyte         => sd_rd_data         -- a byte of sector content
);

process(clk32)
begin
  if rising_edge(clk32) then
    old_sync <= freeze_sync;
      if old_sync xor freeze_sync then
        freeze <= osd_status;
      end if;
  end if;
end process;

video_inst: entity work.video 
port map(
      clk       => clk_27mhz, -- XO
      clk32_i   => clk32, -- core clock for sync purposes
      hdmi_pll_reset  => not pll_locked,
      clk_32    => open,  -- 27Mhz pixel clock 720x576@50
      pll_lock  => pll2_locked, -- hdmi pll lock

      hs_in_n   => hsync,
      vs_in_n   => vsync,
      de_in     => '0',

      r_in      => std_logic_vector(r(7 downto 4)),
      g_in      => std_logic_vector(g(7 downto 4)),
      b_in      => std_logic_vector(b(7 downto 4)),

      audio_l => audio_data_l,  -- interface C64 core specific
      audio_r => audio_data_r,
      enabled => osd_status,

      mcu_start => mcu_start,
      mcu_osd_strobe => mcu_osd_strobe,
      mcu_data  => mcu_data_out,

      -- values that can be configure by the user via osd
      system_wide_screen => system_wide_screen,
      system_scanlines => system_scanlines,
      system_volume => system_volume,

      tmds_clk_n => tmds_clk_n,
      tmds_clk_p => tmds_clk_p,
      tmds_d_n   => tmds_d_n,
      tmds_d_p   => tmds_d_p
      );

  dram_addr(15 downto 0)  <= std_logic_vector(ramAddr);
  dram_addr(21 downto 16) <= (others => '0');
  ramDataOut(15 downto 8) <= (others => '0');
  ramDataIn <= unsigned(ramDataIn_v(7 downto 0));

-- system_reset[0] indicates whether a reset is requested. This
-- can either be triggered implicitely by the user changing hardware
-- specs or explicitely via an OSD menu entry.
-- A cold boot means that the ram contents becomes invalid. We achieve this
-- by scrambling the RAM address space a little bit on every rising edge
-- of system_reset[0] 
process(clk32)
begin
  if rising_edge(clk32) then
    cb_D <= system_reset(0);
      if system_reset(0) = '1' and cb_D = '0' then  --rising edge of reset trigger
        ram_scramble <= ram_scramble + 1;
      end if;
    end if;
end process;

-- RAM is scrambled by xor'ing adress lines 2 and 3 with the scramble bits
  dram_addr_s <= dram_addr(21 downto 4) & (dram_addr(3 downto 2) xor ram_scramble) & dram_addr(1 downto 0);

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
    reset_n   => pll_locked,    -- init signal after FPGA config to initialize RAM
    ready     => ram_ready,     -- ram is ready and has been initialized
    refresh   => idle,          -- chipset requests a refresh cycle
    din       => std_logic_vector(ramDataOut), -- data input from chipset/cpu
    dout      => ramDataIn_v,
    addr      => dram_addr_s,      -- 22 bit word address
    ds        => (others => '0'),-- upper/lower data strobe R = low and W = low
    cs        => ramCE,        -- cpu/chipset requests read/wrie
    we        => ramWe         -- cpu/chipset requests write
  );

mainclock: entity work.Gowin_rPLL
    port map (
        clkout  => clk64,
        lock    => pll_locked,
        clkoutd => clk32,
        clkin   => clk_27mhz
    );

-- led(0)  c1541 activity
led(1) <= joy_sel;
led(2) <= sd_rd(0);
led(3) <= sd_wr(0);
-- led(4) G64 indicator
led(5) <= spi_ext;

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
joyDS2     <= not("11" & dsc_joy_rx1(2) & dsc_joy_rx1(5) & dsc_joy_rx1(7) & dsc_joy_rx1(6) & dsc_joy_rx1(4));
joyDigital <= not("11" & (R_btn_joy(4) or (mouse1_en and mouse_btns(0))) & R_btn_joy(0) & R_btn_joy(1) & R_btn_joy(2) & (R_btn_joy(3)or (mouse1_en and mouse_btns(1))));
joyUsb     <=    ("00" & joystick(4) & joystick(0) & joystick(1) & joystick(2) & joystick(3));
joyA       <= (joyUsb or joyDigital) when joy_sel='0' else joyDS2;
joyB       <= (joyUsb or joyDigital) when joy_sel='1' else joyDS2;

-- paddle pins - mouse 
pot1 <= '0' & std_logic_vector(mouse_x_pos(6 downto 1)) & '0';
pot2 <= '0' & std_logic_vector(mouse_y_pos(6 downto 1)) & '0';

process(clk32)
  variable mov_x: signed(6 downto 0);
  variable mov_y: signed(6 downto 0);
begin
  if rising_edge(clk32) then
    if mouse_strobe = '1' then
      -- due to limited resolution on the c64 side, limit the mouse movement speed
      if mouse_x_cnt > 40 then mov_x:="0101000"; elsif mouse_x_cnt < -40 then mov_x:= "1011000"; else mov_x := mouse_x_cnt(6 downto 0); end if;
      if mouse_y_cnt > 40 then mov_y:="0101000"; elsif mouse_y_cnt < -40 then mov_y:= "1011000"; else mov_y := mouse_y_cnt(6 downto 0); end if;
      mouse_x_pos <= mouse_x_pos + mov_x;
      mouse_y_pos <= mouse_y_pos + mov_y;
    end if;
  end if;
end process;

mcu_spi_inst: entity work.mcu_spi 
port map (
  clk            => clk32,
  reset          => not pll_locked,
  -- SPI interface to BL616 MCU
  spi_io_ss      => spi_io_ss,      -- SPI CSn
  spi_io_clk     => spi_io_clk,     -- SPI SCLK
  spi_io_din     => spi_io_din,     -- SPI MOSI
  spi_io_dout    => spi_io_dout,    -- SPI MISO
  -- byte interface to the various core components
  mcu_sys_strobe => mcu_sys_strobe, -- byte strobe for system control target
  mcu_hid_strobe => mcu_hid_strobe, -- byte strobe for HID target  
  mcu_osd_strobe => mcu_osd_strobe, -- byte strobe for OSD target
  mcu_sdc_strobe => mcu_sdc_strobe, -- byte strobe for SD card target
  mcu_start      => mcu_start,
  mcu_sys_din    => sys_data_out,
  mcu_hid_din    => hid_data_out,
  mcu_osd_din    => osd_data_out,
  mcu_sdc_din    => sdc_data_out,
  mcu_dout       => mcu_data_out
);

-- decode SPI/MCU data received for human input devices (HID) and
-- convert into ST compatible mouse and keyboard signals
hid_inst: entity work.hid
 port map 
 (
  clk             => clk32,
  reset           => not pll_locked,
  -- interface to receive user data from MCU (mouse, kbd, ...)
  data_in_strobe  => mcu_hid_strobe,
  data_in_start   => mcu_start,
  data_in         => mcu_data_out,
  data_out        => hid_data_out,

  -- input local db9 port events to be sent to MCU
  db9_port        => (others => '0'),
  irq             => hid_int,
  iack            => int_ack(1),
  -- output HID data received from USB
  joystick0       => joystick,
  joystick1       => open,
  keyboard_matrix_out => keyboard_matrix_out,
  keyboard_matrix_in  => keyboard_matrix_in,
  mouse_btns      => mouse_btns,
  mouse_x_cnt     => mouse_x_cnt,
  mouse_y_cnt     => mouse_y_cnt,
  mouse_strobe    => mouse_strobe
 );

mouse1_en <= system_port_mouse(0);

module_inst: entity work.sysctrl 
 port map 
 (
  clk               => clk32,
  reset             => not pll_locked,
--
  data_in_strobe    => mcu_sys_strobe,
  data_in_start     => mcu_start,
  data_in           => mcu_data_out,
  data_out          => sys_data_out,

  -- values that can be configured by the user
  system_chipset    => open,
  system_memory     => open,
  system_video      => joy_sel,            -- D9 or Dualshock 2
  system_reset      => system_reset,
  system_scanlines  => system_scanlines,
  system_volume     => system_volume,
  system_wide_screen  => system_wide_screen,
  system_floppy_wprot => system_floppy_wprot,
  system_cubase_en  => open,               -- Numpad Joyport
  system_port_mouse => system_port_mouse,  -- Mouse emulation

  int_out_n         => m0s(4),
  int_in            => std_logic_vector(unsigned'("0000" & sdc_int & '0' & hid_int & '0')),
  int_ack           => int_ack,

  buttons           => std_logic_vector(unsigned'(reset & user)), -- S0 and S1 buttons on Tang Nano 20k
  leds              => open,         -- two leds can be controlled from the MCU
  color             => ws2812_color -- a 24bit color to e.g. be used to drive the ws2812
);

fpga64_sid_iec_inst: entity work.fpga64_sid_iec
  port map
  (
  clk32        => clk32,
  reset_n      => not system_reset(0) and pll_locked and ram_ready,
  bios         => (others => '0'),
  pause        => freeze,
  pause_out    => c64_pause,
  -- keyboard interface
  keyboard_matrix_out => keyboard_matrix_out,
  keyboard_matrix_in => keyboard_matrix_in,
  kbd_reset    => '0',
  shift_mod    => (others => '0'),

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

  ntscMode     => ntscMode,
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
  freeze_key   => open,  -- Keyboard Restore (NMI Interrupt)
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
  pot1         => pot1,
  pot2         => pot2,
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
