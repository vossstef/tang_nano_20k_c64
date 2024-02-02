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
    leds_n      : out std_logic_vector(5 downto 0);
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
    joystick_cs   : out std_logic;
    -- spi flash interface
    mspi_cs       : out std_logic;
    mspi_clk      : out std_logic;
    mspi_di       : inout std_logic;
    mspi_hold     : inout std_logic;
    mspi_wp       : inout std_logic;
    mspi_do       : inout std_logic
    );
end;

architecture Behavioral_top of tang_nano_20k_c64_top is

signal clk_pixel_x5, clk64, clk32, pll_locked, pll2_locked : std_logic;

attribute syn_keep : integer;
attribute syn_keep of clk_pixel_x5 : signal is 1;
attribute syn_keep of clk64 : signal is 1;
attribute syn_keep of clk32 : signal is 1;

signal R_btn_joy     : std_logic_vector(4 downto 0);
signal audio_data_l  : std_logic_vector(17 downto 0);
signal audio_data_r  : std_logic_vector(17 downto 0);

-- external memory
signal c64_addr     : unsigned(15 downto 0);
signal c64_data_out : unsigned(7 downto 0);
signal sdram_data   : unsigned(7 downto 0);
signal dout         : std_logic_vector(15 downto 0);
signal idle         : std_logic;
signal dram_addr    : std_logic_vector(21 downto 0);
signal dram_addr_s  : std_logic_vector(21 downto 0);
signal ram_scramble : std_logic_vector(1 downto 0);
signal ram_ready    : std_logic;
signal cb_D         : std_logic;
signal addr         : std_logic_vector(21 downto 0);
signal cs           : std_logic;
signal we           : std_logic;
signal din          : std_logic_vector(15 downto 0);

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
signal joyNumpad    : std_logic_vector(6 downto 0);
signal joyMouse     : std_logic_vector(6 downto 0);
signal numpad       : std_logic_vector(7 downto 0);
-- CONTROLLER DUALSHOCK
signal joyDS2       : std_logic_vector(6 downto 0);
signal dsc_joy_rx0  : std_logic_vector(7 downto 0);
signal dsc_joy_rx1  : std_logic_vector(7 downto 0);
-- joystick interface
signal joyA        : std_logic_vector(6 downto 0) := (others => '1');
signal joyB        : std_logic_vector(6 downto 0) := (others => '1');
signal btn_debounce: std_logic_vector(6 downto 0);
signal user_deb    : std_logic;
signal port_1_sel  : std_logic_vector(2 downto 0);
signal port_2_sel  : std_logic_vector(2 downto 0);
-- mouse / paddle
signal pot1        : std_logic_vector(7 downto 0);
signal pot2        : std_logic_vector(7 downto 0);
signal mouse_x_pos : signed(10 downto 0);
signal mouse_y_pos : signed(10 downto 0);

signal ram_ce      :  std_logic;
signal ram_we      :  std_logic;
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
signal mouse_x        : signed(7 downto 0);
signal mouse_y        : signed(7 downto 0);
signal mouse_strobe   : std_logic;
signal freeze         : std_logic;
signal freeze_sync    : std_logic;
signal c64_pause      : std_logic;
signal old_sync       : std_logic;
signal osd_status     : std_logic;
signal ws2812_color   : std_logic_vector(23 downto 0);
signal system_reset   : std_logic_vector(1 downto 0);
signal disk_reset     : std_logic;
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
signal c1541_osd_reset : std_logic;
signal system_wide_screen : std_logic;
signal system_floppy_wprot : std_logic_vector(1 downto 0);
signal leds           : std_logic_vector(5 downto 0);
signal system_leds    : std_logic_vector(1 downto 0);
signal led1541        : std_logic;
signal reu_cfg        : std_logic:= '1'; 
signal dma_req        : std_logic;
signal dma_cycle      : std_logic;
signal dma_addr       : std_logic_vector(15 downto 0);
signal dma_dout       : std_logic_vector(7 downto 0);
signal dma_din        : unsigned(7 downto 0);
signal dma_we         : std_logic;
signal io_cycle       : std_logic;
signal ext_cycle      : std_logic;
signal ext_cycle_d    : std_logic;
signal reu_ram_addr   : std_logic_vector(24 downto 0);
signal reu_ram_dout   : std_logic_vector(7 downto 0);
signal reu_ram_we     : std_logic;
signal reu_irq        : std_logic;
signal IOE            : std_logic;
signal IOF            : std_logic;
signal reu_dout       : std_logic_vector(7 downto 0);
signal reu_oe         : std_logic;
signal reu_ram_ce     : std_logic;
signal cart_ce        : std_logic;
signal cart_we        : std_logic;
signal cart_data      : std_logic_vector(7 downto 0);
signal cart_addr      : std_logic_vector(24 downto 0);
signal exrom          : std_logic;
signal game           : std_logic;
signal romL           : std_logic;
signal romH           : std_logic;
signal UMAXromH       : std_logic;
signal io_rom         : std_logic;
signal cart_oe        : std_logic;
signal io_data        : unsigned(7 downto 0);
signal db9_joy        : std_logic_vector(5 downto 0);
signal sid_filter     : std_logic_vector(1 downto 0) := "11";
signal turbo_mode     : std_logic_vector(1 downto 0) := (others => '0');
signal turbo_speed    : std_logic_vector(1 downto 0) := (others => '0');
signal flash_ready    : std_logic;
signal dos_sel        : std_logic_vector(1 downto 0);
signal c1541rom_cs    : std_logic;
signal c1541rom_addr  : std_logic_vector(14 downto 0);
signal c1541rom_data  : std_logic_vector(7 downto 0);
signal ext_en         : std_logic;

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
      else
        disk_g64 <= '0';
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
    reset         => (not flash_ready) or c1541_osd_reset,

    disk_num      => (others =>'0'),
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

    led           => led1541,
    ext_en        => ext_en,
    c1541rom_cs   => c1541rom_cs,
    c1541rom_addr => c1541rom_addr,
    c1541rom_data => c1541rom_data
);
ext_en <= '1' when dos_sel(0) = '0' else '0'; -- dolphin, speed

sd_rd(3 downto 1) <= "000";
sd_wr(3 downto 1) <= "000";
sdc_iack <= int_ack(3);

sd_card_inst: entity work.sd_card
generic map (
    CLK_DIV  => 1
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
      clk_pixel_x5  => clk_pixel_x5,
      mspi_clk  => mspi_clk,
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

  dram_addr(21 downto 0) <= B"000000" & std_logic_vector(c64_addr);
  c64_data_out <= unsigned(dout(7 downto 0));

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

-- A(0) workaround till sdram ctrl properly adjusted
addr <= ((B"100000_00000000_0000000" or reu_ram_addr(20 downto 0)) & '0') when ext_cycle = '1' else dram_addr_s(20 downto 0) & '0';
cs <= reu_ram_ce when ext_cycle = '1' else ram_ce;
we <= reu_ram_we when ext_cycle = '1' else ram_we;
din <= ("00000000" & reu_ram_dout) when ext_cycle = '1' else ("00000000" & std_logic_vector(sdram_data));

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
    din       => din,           -- data input from chipset/cpu
    dout      => dout,
    addr      => addr,          -- 22 bit word address
    ds        => (others => '0'),-- upper/lower data strobe R = low and W = low
    cs        => cs,            -- cpu/chipset requests read/wrie
    we        => we             -- cpu/chipset requests write
  );

mainclock: entity work.Gowin_rPLL
    port map (
        clkout  => clk64,
        lock    => pll_locked,
        clkoutp => open, -- mspi_clk, -- shifted 63Mhz clock
        clkoutd => clk32,
        clkin   => clk_27mhz
    );

leds_n <=  not leds;
leds(0) <= led1541;
leds(2 downto 1) <= "00";
leds(3) <= spi_ext;
leds(5 downto 4) <= system_leds;

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
joyDigital <= not("11" &   R_btn_joy(4) &   R_btn_joy(0) &   R_btn_joy(1) & R_btn_joy(2)   & (R_btn_joy(3)));
joyUsb     <=    ("00" & joystick(4) & joystick(0) & joystick(1) & joystick(2) & joystick(3));
joyNumpad  <=     "00" & numpad(4) & numpad(0) & numpad(1) & numpad(2) & numpad(3);
joyMouse   <=     "00" & mouse_btns(0) & "000" & mouse_btns(1);

-- send external DB9 joystick port to µC
db9_joy <= "000000";

process(clk32)
begin
	if rising_edge(clk32) then
    case port_1_sel is
      when "000"  => joyA <= joyDigital;
      when "001"  => joyA <= joyUsb;
      when "010"  => joyA <= joyNumpad;
      when "011"  => joyA <= joyDS2;
      when "100"  => joyA <= joyMouse;
      when "101"  => joyA <= (others => '0');
      when others => null;
    end case;
  end if;
end process;

process(clk32)
begin
	if rising_edge(clk32) then
    case port_2_sel is
      when "000"  => joyB <= joyDigital;
      when "001"  => joyB <= joyUsb;
      when "010"  => joyB <= joyNumpad;
      when "011"  => joyB <= joyDS2;
      when "100"  => joyB <= joyMouse;
      when "101"  => joyB <= (others => '0');
      when others => null;
      end case;
  end if;
end process;

-- paddle pins - mouse 
pot1 <= '0' & std_logic_vector(mouse_x_pos(6 downto 1)) & '0';
pot2 <= '0' & std_logic_vector(mouse_y_pos(6 downto 1)) & '0';

process(clk32, pll_locked)
 variable mov_x: signed(6 downto 0);
 variable mov_y: signed(6 downto 0);
begin
  if pll_locked = '0' then
    mouse_x_pos <= (others => '0');
    mouse_y_pos <= (others => '0');
  elsif rising_edge(clk32) then
    if mouse_strobe = '1' then
     -- due to limited resolution on the c64 side, limit the mouse movement speed
     if mouse_x > 40 then mov_x:="0101000"; elsif mouse_x < -40 then mov_x:= "1011000"; else mov_x := mouse_x(6 downto 0); end if;
     if mouse_y > 40 then mov_y:="0101000"; elsif mouse_y < -40 then mov_y:= "1011000"; else mov_y := mouse_y(6 downto 0); end if;
     mouse_x_pos <= mouse_x_pos - mov_x;
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

-- decode SPI/MCU data received for human input devices (HID) 
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
  db9_port        => db9_joy,
  irq             => hid_int,
  iack            => int_ack(1),
  -- output HID data received from USB
  joystick0       => joystick,
  joystick1       => open,
  numpad          => numpad,
  keyboard_matrix_out => keyboard_matrix_out,
  keyboard_matrix_in  => keyboard_matrix_in,
  key_restore     => open,
  mouse_btns      => mouse_btns,
  mouse_x         => mouse_x,
  mouse_y         => mouse_y,
  mouse_strobe    => mouse_strobe
 );

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
  system_reu_cfg    => reu_cfg,
  system_reset      => system_reset,
  system_scanlines  => system_scanlines,
  system_volume     => system_volume,
  system_wide_screen  => system_wide_screen,
  system_floppy_wprot => system_floppy_wprot,
  system_port_1     => port_1_sel,  -- Joystick port 1 input device selection 
  system_port_2     => port_2_sel,  -- Joystick port 2 input device selection 
  system_dos_sel    => dos_sel,
  system_1541_reset => c1541_osd_reset,
  system_audio_filter => sid_filter(0),
  system_turbo_mode   => turbo_mode,
  system_turbo_speed  => turbo_speed,

  int_out_n         => m0s(4),
  int_in            => std_logic_vector(unsigned'("0000" & sdc_int & '0' & hid_int & '0')),
  int_ack           => int_ack,

  buttons           => std_logic_vector(unsigned'(reset & user)), -- S0 and S1 buttons on Tang Nano 20k
  leds              => system_leds,         -- two leds can be controlled from the MCU
  color             => ws2812_color -- a 24bit color to e.g. be used to drive the ws2812
);

io_data <=  unsigned(cart_data) when cart_oe  = '1' else unsigned(reu_dout);

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
  keyboard_matrix_in  => keyboard_matrix_in,
  kbd_reset    => '0',
  shift_mod    => (others => '0'),

  -- external memory
  ramAddr      => c64_addr,
  ramDin       => c64_data_out,
  ramDout      => sdram_data,
  ramCE        => ram_ce,
  ramWE        => ram_we,
  io_cycle     => io_cycle,
  ext_cycle    => ext_cycle,
  refresh      => idle,

  cia_mode     => '0',
  turbo_mode   => turbo_mode,
  turbo_speed  => turbo_speed,

  vic_variant  => "00",
  ntscMode     => ntscMode,
  hsync        => hsync,
  vsync        => vsync,
  r            => r,
  g            => g,
  b            => b,

  game         => game,
  exrom        => exrom,
  io_rom       => io_rom,
  io_ext       => (reu_oe or cart_oe),
  io_data      => io_data,
  irq_n        => '1',
  nmi_n        => '1',
  nmi_ack      => open,
  romL         => romL,
  romH         => romH,
  UMAXromH     => UMAXromH,
  IOE          => IOE,
  IOF          => IOF,
  freeze_key   => open,
  mod_key      => open,
  tape_play    => open,

  -- dma access
  dma_req      => dma_req,
  dma_cycle    => dma_cycle,
  dma_addr     => unsigned(dma_addr),
  dma_dout     => unsigned(dma_dout),
  dma_din      => dma_din,
  dma_we       => dma_we,
  irq_ext_n    => not reu_irq,

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
  sid_filter   => sid_filter,
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

process(clk32)
begin
  if rising_edge(clk32) then
    ext_cycle_d <= ext_cycle;
  end if;
end process;

reu_oe  <= IOF and reu_cfg;
reu_ram_ce <= not ext_cycle_d and ext_cycle and dma_req;

reu_inst: entity work.reu
port map(
    clk       => clk32,
    reset     => system_reset(0),
    cfg       => std_logic_vector(unsigned'( '0' & reu_cfg) ), -- limit to 512k REU 1750 
  
    dma_req   => dma_req,
    dma_cycle => dma_cycle,
    dma_addr  => dma_addr,
    dma_dout  => dma_dout,
    dma_din   => dma_din,
    dma_we    => dma_we,
  
    ram_cycle => ext_cycle,
    ram_addr  => reu_ram_addr,
    ram_dout  => reu_ram_dout,
    ram_din   => c64_data_out,
    ram_we    => reu_ram_we,
    
    cpu_addr  => c64_addr, 
    cpu_dout  => sdram_data,
    cpu_din   => reu_dout,
    cpu_we    => ram_we,
    cpu_cs    => IOF,
    
    irq       => reu_irq
  ); 

-- c1541 ROM's SPI Flash, offset in spi flash $100000
flash_inst: entity work.flash 
port map(
    clk       => clk_pixel_x5,  -- clk64 + shifted clk64
    resetn    => pll2_locked,
    ready     => flash_ready,
    busy      => open,
    address   => ("0001" & "000" & dos_sel & c1541rom_addr),
    cs        => c1541rom_cs,
    dout      => c1541rom_data,
    mspi_cs   => mspi_cs,
    mspi_di   => mspi_di,
    mspi_hold => mspi_hold,
    mspi_wp   => mspi_wp,
    mspi_do   => mspi_do
);

-- work in progress....
cartridge_inst: entity work.cartridge
port map
  (
    clk32       => clk32,
    reset_n     => not system_reset(0),
  
    cart_loading    => '0',
    cart_id         => (others => '0'),
    cart_exrom      => (others => '0'),
    cart_game       => (others => '0'),
    cart_bank_laddr => (others => '0'),
    cart_bank_size  => (others => '0'),
    cart_bank_num   => (others => '0'),
    cart_bank_type  => (others => '0'),
    cart_bank_raddr => (others => '0'),
    cart_bank_wr    => '0',
  
    exrom       => exrom,
    game        => game,
  
    romL        => romL,
    romH        => romH,
    UMAXromH    => UMAXromH,
    IOE         => IOE,
    IOF         => IOF,
    mem_write   => ram_we,
    mem_ce      => ram_ce,
    mem_ce_out  => cart_ce,
    mem_write_out => cart_we,
    IO_rom      => io_rom,
    IO_rd       => cart_oe,
    IO_data     => cart_data,
    addr_in     => c64_addr,
    data_in     => c64_data_out(7 downto 0),
    addr_out    => cart_addr,
  
    freeze_key  => '0', -- freeze_key,
    mod_key     => '0', -- mod_key,
    nmi         => open,
    nmi_ack     => '0'
  );
end Behavioral_top;
