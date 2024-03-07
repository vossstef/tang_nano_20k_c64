-------------------------------------------------------------------------
--  C64 Top level for Tang Nano
--  2023 / 2024 Stefan Voss
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

entity tang_nano_20k_c64_top_138k is
  port
  (
    clk         : in std_logic;
    reset       : in std_logic; -- S2 button
    user        : in std_logic; -- S1 button
    leds_n      : out std_logic_vector(5 downto 0);
    io          : in std_logic_vector(4 downto 0);

    -- SPI interface Sipeed M0S Dock external BL616 uC
    m0s         : inout std_logic_vector(5 downto 0);

    tmds_clk_n  : out std_logic;
    tmds_clk_p  : out std_logic;
    tmds_d_n    : out std_logic_vector( 2 downto 0);
    tmds_d_p    : out std_logic_vector( 2 downto 0);
    -- sd interface
    sd_clk      : out std_logic;
    sd_cmd      : inout std_logic;
    sd_dat      : inout std_logic_vector(3 downto 0);
    ws2812      : out std_logic;
    -- MiSTer SDRAM module
    O_sdram_clk     : out std_logic;
    O_sdram_cs_n    : out std_logic; -- chip select
    O_sdram_cas_n   : out std_logic;
    O_sdram_ras_n   : out std_logic; -- row address select
    O_sdram_wen_n   : out std_logic; -- write enable
    IO_sdram_dq     : inout std_logic_vector(15 downto 0); -- 16 bit bidirectional data bus
    O_sdram_addr    : out std_logic_vector(12 downto 0); -- 13 bit multiplexed address bus
    O_sdram_ba      : out std_logic_vector(1 downto 0); -- two banks
    O_sdram_dqm     : out std_logic_vector(1 downto 0); -- 16/2
    -- Gamepad
    joystick_clk  : out std_logic;
    joystick_mosi : out std_logic;
    joystick_miso : inout std_logic; -- midi_out
    joystick_cs   : inout std_logic; -- midi_in
    -- spi flash interface
    mspi_cs       : out std_logic;
    mspi_clk      : out std_logic;
    mspi_di       : inout std_logic;
    mspi_hold     : inout std_logic;
    mspi_wp       : inout std_logic;
    mspi_do       : inout std_logic
    );
end;

architecture Behavioral_top of tang_nano_20k_c64_top_138k is

signal clk64          : std_logic;
signal clk32          : std_logic;
signal pll_locked     : std_logic;
signal clk_pixel_x5   : std_logic;
signal mspi_clk_x5    : std_logic;
signal clk64_ntsc     : std_logic;
signal clk32_ntsc     : std_logic;
signal pll_locked_ntsc: std_logic;
signal clk_pixel_x5_ntsc  : std_logic;
signal clk64_pal      : std_logic;
signal clk32_pal      : std_logic;
signal pll_locked_pal : std_logic;
signal clk_pixel_x5_pal   : std_logic;
attribute syn_keep : integer;
attribute syn_keep of clk64             : signal is 1;
attribute syn_keep of clk32             : signal is 1;
attribute syn_keep of clk_pixel_x5      : signal is 1;
attribute syn_keep of clk64_pal         : signal is 1;
attribute syn_keep of clk32_ntsc        : signal is 1;
attribute syn_keep of clk32_pal         : signal is 1;
attribute syn_keep of clk_pixel_x5_pal  : signal is 1;
attribute syn_keep of mspi_clk_x5       : signal is 1;

signal audio_data_l  : std_logic_vector(17 downto 0);
signal audio_data_r  : std_logic_vector(17 downto 0);

-- external memory
signal c64_addr     : unsigned(15 downto 0);
signal c64_data_out : unsigned(7 downto 0);
signal sdram_data   : unsigned(7 downto 0);
signal dout         : std_logic_vector(7 downto 0);
signal idle         : std_logic;
signal dram_addr    : std_logic_vector(22 downto 0);
signal dram_addr_s  : std_logic_vector(22 downto 0);
signal ram_scramble : std_logic_vector(1 downto 0);
signal ram_ready    : std_logic;
signal cb_D         : std_logic;
signal addr         : std_logic_vector(22 downto 0);
signal cs           : std_logic;
signal we           : std_logic;
signal din          : std_logic_vector(7 downto 0);
signal ds           : std_logic_vector(1 downto 0);

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
signal joyUsb1      : std_logic_vector(6 downto 0);
signal joyUsb2      : std_logic_vector(6 downto 0);
signal joyDigital   : std_logic_vector(6 downto 0);
signal joyNumpad    : std_logic_vector(6 downto 0);
signal joyMouse     : std_logic_vector(6 downto 0);
signal joyPaddle    : std_logic_vector(6 downto 0); 
signal joyPaddle2   : std_logic_vector(6 downto 0); 
signal numpad       : std_logic_vector(7 downto 0);
signal joyDS2       : std_logic_vector(6 downto 0);
-- joystick interface
signal joyA        : std_logic_vector(6 downto 0);
signal joyB        : std_logic_vector(6 downto 0);
signal port_1_sel  : std_logic_vector(2 downto 0);
signal port_2_sel  : std_logic_vector(2 downto 0);
-- mouse / paddle
signal pot1        : std_logic_vector(7 downto 0);
signal pot2        : std_logic_vector(7 downto 0);
signal pot3        : std_logic_vector(7 downto 0);
signal pot4        : std_logic_vector(7 downto 0);
signal mouse_x_pos : signed(10 downto 0);
signal mouse_y_pos : signed(10 downto 0);

signal ram_ce      :  std_logic;
signal ram_we      :  std_logic;
signal romCE       :  std_logic;

signal ntscMode    :  std_logic;
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
signal joystick1       : std_logic_vector(7 downto 0);
signal joystick2       : std_logic_vector(7 downto 0);
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
signal reu_cfg        : std_logic; 
signal dma_req        : std_logic;
signal dma_cycle      : std_logic;
signal dma_addr       : std_logic_vector(15 downto 0);
signal dma_dout       : std_logic_vector(7 downto 0);
signal dma_din        : unsigned(7 downto 0);
signal dma_we         : std_logic;
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
signal cart_addr      : std_logic_vector(22 downto 0);
signal exrom          : std_logic;
signal game           : std_logic;
signal romL           : std_logic;
signal romH           : std_logic;
signal UMAXromH       : std_logic;
signal io_rom         : std_logic;
signal cart_oe        : std_logic;
signal io_data        : unsigned(7 downto 0);
signal db9_joy        : std_logic_vector(5 downto 0);
signal sid_filter     : std_logic;
signal turbo_mode     : std_logic_vector(1 downto 0);
signal turbo_speed    : std_logic_vector(1 downto 0);
signal flash_ready    : std_logic;
signal dos_sel        : std_logic_vector(1 downto 0);
signal c1541rom_cs    : std_logic;
signal c1541rom_addr  : std_logic_vector(14 downto 0);
signal c1541rom_data  : std_logic_vector(7 downto 0);
signal ext_en         : std_logic;
signal nmi            : std_logic;
signal nmi_ack        : std_logic;
signal freeze_key     : std_logic;
signal disk_access    : std_logic;
signal c64_iec_clk_old : std_logic;
signal drive_iec_clk_old : std_logic;
signal drive_stb_i_old : std_logic;
signal drive_stb_o_old : std_logic;
signal hsync_out       : std_logic;
signal vsync_out       : std_logic;
signal hblank          : std_logic;
signal vblank          : std_logic;
signal frz_hs          : std_logic;
signal frz_vs          : std_logic;
signal hbl_out         : std_logic; 
signal vbl_out         : std_logic;
signal midi_data       : std_logic_vector(7 downto 0);
signal midi_oe         : std_logic;
signal midi_irq_n      : std_logic;
signal midi_nmi_n      : std_logic;
signal midi_rx         : std_logic;
signal midi_tx         : std_logic;
signal st_midi         : std_logic_vector(2 downto 0);
signal phi             : std_logic;
signal joystick_cs_i   : std_logic;
signal joystick_miso_i : std_logic;
signal frz_hbl         : std_logic;
signal frz_vbl         : std_logic;
signal system_pause    : std_logic;
signal paddle_1        : std_logic_vector(7 downto 0);
signal paddle_2        : std_logic_vector(7 downto 0);
signal paddle_3        : std_logic_vector(7 downto 0);
signal paddle_4        : std_logic_vector(7 downto 0);
signal key_r1          : std_logic;
signal key_r2          : std_logic;
signal key_l1          : std_logic;
signal key_l2          : std_logic;
signal key_triangle    : std_logic;
signal key_square      : std_logic;
signal key_circle      : std_logic;
signal key_cross       : std_logic;
signal audio_div       : unsigned(8 downto 0);
signal flash_clk       : std_logic;
signal flash_lock      : std_logic;
signal dcsclksel       : std_logic_vector(3 downto 0);
signal ioctl_download  : std_logic := '0';
signal ioctl_load_addr : std_logic_vector(22 downto 0);
signal ioctl_req_wr    : std_logic;
signal cart_id         : std_logic_vector(15 downto 0);
signal cart_bank_laddr : std_logic_vector(15 downto 0);
signal cart_bank_size  : std_logic_vector(15 downto 0);
signal cart_bank_num   : std_logic_vector(15 downto 0);
signal cart_bank_type  : std_logic_vector(7 downto 0);
signal cart_exrom      : std_logic_vector(7 downto 0);
signal cart_game       : std_logic_vector(7 downto 0);
signal cart_attached   : std_logic := '0';
signal cart_hdr_cnt    : std_logic_vector(3 downto 0);
signal cart_hdr_wr     : std_logic;
signal cart_blk_len    : std_logic_vector(31 downto 0);
signal io_cycle        : std_logic;
signal io_cycle_ce     : std_logic := '0';
signal io_cycle_we     : std_logic := '0';
signal io_cycle_addr   : std_logic_vector(22 downto 0);
signal io_cycle_data   : std_logic_vector(7 downto 0);
signal load_crt        : std_logic;

component DCS
    generic (
        DCS_MODE : STRING := "RISING"
    );
    port (
        CLKOUT: out std_logic;
        CLKSEL: in std_logic_vector(3 downto 0);
        CLKIN0: in std_logic;
        CLKIN1: in std_logic;
        CLKIN2: in std_logic;
        CLKIN3: in std_logic;
        SELFORCE: in std_logic
    );
 end component;

begin
  spi_io_din  <= m0s(1);
  spi_io_ss   <= m0s(2);
  spi_io_clk  <= m0s(3);
  m0s(0)      <= spi_io_dout;
  m0s(5)      <= 'Z';

  -- mux overlapping DS2 and MIDI signals to IO pin
joystick_cs     <= joystick_cs_i when st_midi = "000" else 'Z';
midi_rx         <= joystick_cs when st_midi /= "000" else '1';
joystick_miso   <= midi_tx when st_midi /= "000" else 'Z';
joystick_miso_i <= joystick_miso when st_midi = "000" else '1';

-- https://store.curiousinventor.com/guides/PS2/
-- https://hackaday.io/project/170365-blueretro/log/186471-playstation-playstation-2-spi-interface

gamepad: entity work.dualshock2
    port map (
    clk           => clk32,
    rst           => system_reset(0) and not pll_locked,
    vsync         => vsync,
    ds2_dat       => joystick_miso_i,
    ds2_cmd       => joystick_mosi,
    ds2_att       => joystick_cs_i,
    ds2_clk       => joystick_clk,
    ds2_ack       => '0',
    stick_lx      => paddle_1,
    stick_ly      => paddle_2,
    stick_rx      => paddle_3,
    stick_ry      => paddle_4,
    key_up        => open,
    key_down      => open,
    key_left      => open,
    key_right     => open,
    key_l1        => key_l1,
    key_l2        => key_l2,
    key_r1        => key_r1,
    key_r2        => key_r2,
    key_triangle  => key_triangle,
    key_square    => key_square,
    key_circle    => key_circle,
    key_cross     => key_cross,
    key_start     => open,
    key_select    => open,
    key_lstick    => open,
    key_rstick    => open,
    debug1        => open,
    debug2        => open
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

disk_reset <= c1541_osd_reset or not pll_locked or c1541_reset or not flash_lock;

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
    reset         => (not flash_ready) or disk_reset,
    pause         => c64_pause,
    ce            => '0',

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
ext_en <= '1' when dos_sel(0) = '0' else '0'; -- dolphindos, speeddos
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
      if not old_sync and freeze_sync then
          freeze <= osd_status and system_pause;
        end if;
  end if;
end process;

video_sync_inst: entity work.video_sync
port map(
	clk32   => clk32,
	pause   => c64_pause,
	hsync   => hsync,
	vsync   => vsync,
	ntsc    => '0',
	wide    => '0',
	hsync_out => hsync_out,
	vsync_out => vsync_out,
	hblank  => hblank,
	vblank  => vblank
);

video_freezer_inst: entity work.video_freezer
port map(
	clk     => clk32,
	freeze  => freeze,
	hs_in   => hsync_out,
	vs_in   => vsync_out,
	hbl_in  => hblank,
	vbl_in  => vblank,
	sync    => freeze_sync,
	hs_out  => frz_hs,
	vs_out  => frz_vs,
	hbl_out => frz_hbl,
	vbl_out => frz_vbl
);

audio_div  <= to_unsigned(342,9) when ntscMode = '1' else to_unsigned(327,9);

video_inst: entity work.video 
port map(
      pll_lock     => pll_locked, 
      clk          => clk32,
      clk_pixel_x5 => clk_pixel_x5,
      audio_div    => audio_div,

      ntscmode  => ntscMode,
      vb_in     => frz_vbl,
      hb_in     => frz_hbl,
      hs_in_n   => frz_hs,
      vs_in_n   => frz_vs,

      r_in      => std_logic_vector(r(7 downto 4)),
      g_in      => std_logic_vector(g(7 downto 4)),
      b_in      => std_logic_vector(b(7 downto 4)),

      audio_l => audio_data_l,  -- interface C64 core specific
      audio_r => audio_data_r,
      osd_status => osd_status,

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

-- system_reset[1] indicates whether a reset is requested. This
-- can either be triggered implicitely by the user changing hardware
-- specs or explicitely via an OSD menu entry.
-- A cold boot means that the ram contents becomes invalid. We achieve this
-- by scrambling the RAM address space a little bit on every rising edge
-- of system_reset[1] 
process(clk32)
begin
  if rising_edge(clk32) then
    cb_D <= system_reset(1);
      if system_reset(1) = '1' and cb_D = '0' then  --rising edge of reset trigger
        ram_scramble <= ram_scramble + 1;
      end if;
    end if;
end process;

-- RAM is scrambled by xor'ing adress lines 2 and 3 with the scramble bits
dram_addr_s <= cart_addr(22 downto 4) & (cart_addr(3 downto 2) xor ram_scramble) & cart_addr(1 downto 0);

addr <= io_cycle_addr when io_cycle ='1' else reu_ram_addr(22 downto 0) when ext_cycle = '1' else dram_addr_s;
cs <= io_cycle_ce when io_cycle ='1' else reu_ram_ce when ext_cycle = '1' else cart_ce; 
we <= io_cycle_we when io_cycle ='1' else reu_ram_we  when ext_cycle = '1' else cart_we;
din <= std_logic_vector(io_cycle_data) when io_cycle ='1' else std_logic_vector(reu_ram_dout) when ext_cycle = '1' else std_logic_vector(c64_data_out);
sdram_data <= unsigned(dout);

dram_inst: entity work.sdram
port map(
    -- SDRAM side interface
    sd_clk    => O_sdram_clk,   -- sd clock
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
    addr      => "00" & addr,   -- 25 bit word address
    ds        => "00",
    cs        => cs,            -- cpu/chipset requests read/wrie
    we        => we             -- cpu/chipset requests write
  );

-- Clock tree and all frequencies in Hz
-- TN 20k
-- pal                   / ntsc
-- pll         315000000 / 329400000
-- serdes      157500000 / 164700000
-- dram         63000000 /  65880000
-- core /pixel  31500000 /  32940000

-- TP 25k /M 138k
-- pal                   / ntsc
-- pll         315000000 / 325000000
-- serdes      157500000 / 162500000
-- dram         63000000 /  65000000
-- core /pixel  31500000 /  32500000

pll_locked <= pll_locked_pal and pll_locked_ntsc;
dcsclksel <= "0001" when ntscMode = '0' else "0010";

clk_switch_1: DCS
generic map (
    DCS_MODE => "RISING"
)
port map (
    CLKOUT => clk_pixel_x5,
    CLKSEL => dcsclksel,
    CLKIN0 => clk_pixel_x5_pal,
    CLKIN1 => clk_pixel_x5_ntsc,
    CLKIN2 => '0',
    CLKIN3 => '0',
    SELFORCE => '1'
);

clk_switch_2: DCS
generic map (
    DCS_MODE => "RISING"
)
port map (
    CLKOUT => clk64,
    CLKSEL => dcsclksel,
    CLKIN0 => clk64_pal,
    CLKIN1 => clk64_ntsc,
    CLKIN2 => '0',
    CLKIN3 => '0',
    SELFORCE => '1'
);

clk32 <= clk32_pal when ntscMode = '0' else clk32_ntsc;

mainclock_pal: entity work.Gowin_PLL_138k_pal
port map (
    lock => pll_locked_pal,
    clkout0 => open,
    clkout1 => clk_pixel_x5_pal,
    clkout2 => clk64_pal,
    clkout3 => clk32_pal,
    clkin => clk
);

mainclock_ntsc: entity work.Gowin_PLL_138k_ntsc
port map (
    lock => pll_locked_ntsc,
    clkout0 => open,
    clkout1 => clk_pixel_x5_ntsc,
    clkout2 => clk64_ntsc,
    clkout3 => clk32_ntsc,
    clkin => clk
);

-- 64.0Mhz for flash controller c1541 ROM
flashclock: entity work.Gowin_PLL_138k_flash
    port map (
        lock => flash_lock,
        clkout0 => flash_clk,
        clkout1 => mspi_clk,
        clkout2 => open, -- 32,0M
        clkin => clk
    );

leds_n <=  not leds;
leds(0) <= led1541;
leds(1) <= '0';
leds(2) <= '0';
leds(3) <= '0';
leds(4) <= system_leds(0);
leds(5) <= system_leds(1);

-- 4 3 2 1 0 digital c64
joyDS2     <=    ("00" & (key_l1 or key_r1) & key_circle & key_square & key_cross & key_triangle);
joyDigital <= not("11" & io(0) & io(4) & io(3) & io(2) & io(1));
joyUsb1    <=    ("00" & joystick1(4) & joystick1(0) & joystick1(1) & joystick1(2) & joystick1(3));
joyUsb2    <=    ("00" & joystick2(4) & joystick2(0) & joystick2(1) & joystick2(2) & joystick2(3));
joyNumpad  <=     "00" & numpad(4) & numpad(0) & numpad(1) & numpad(2) & numpad(3);
joyMouse   <=     "00" & mouse_btns(0) & "000" & mouse_btns(1);
joyPaddle  <=    ("00" & '0' & key_l1 & key_l2 & "00"); -- bound to physical paddle position DS2
joyPaddle2 <=    ("00" & '0' & key_r1 & key_r2 & "00");

-- send external DB9 joystick port to µC
db9_joy <= not('1' & io(0), io(2), io(1), io(4), io(3));

process(clk32)
begin
	if rising_edge(clk32) then
    case port_1_sel is
      when "000"  => joyA <= joyDigital;
      when "001"  => joyA <= joyUsb1;
      when "010"  => joyA <= joyUsb2;
      when "011"  => joyA <= joyNumpad;
      when "100"  => joyA <= joyDS2;
      when "101"  => joyA <= joyMouse;
      when "110"  => joyA <= joyPaddle;
      when "111"  => joyA <= (others => '0');
      when others => null;
    end case;
  end if;
end process;

process(clk32)
begin
	if rising_edge(clk32) then
    case port_2_sel is
      when "000"  => joyB <= joyDigital;
      when "001"  => joyB <= joyUsb1;
      when "010"  => joyB <= joyUsb2;
      when "011"  => joyB <= joyNumpad;
      when "100"  => joyB <= joyDS2;
      when "101"  => joyB <= joyMouse;
      when "110"  => joyB <= joyPaddle2;
      when "111"  => joyB <= (others => '0');
      when others => null;
      end case;
  end if;
end process;

-- paddle pins - mouse
pot1 <= not paddle_1 when port_1_sel = "110" else ('0' & std_logic_vector(mouse_x_pos(6 downto 1)) & '0');
pot2 <= not paddle_2 when port_1_sel = "110" else ('0' & std_logic_vector(mouse_y_pos(6 downto 1)) & '0');
pot3 <= not paddle_3 when port_2_sel = "110" else ('0' & std_logic_vector(mouse_x_pos(6 downto 1)) & '0');
pot4 <= not paddle_4 when port_2_sel = "110" else ('0' & std_logic_vector(mouse_y_pos(6 downto 1)) & '0');

process(clk32, system_reset(0))
 variable mov_x: signed(6 downto 0);
 variable mov_y: signed(6 downto 0);
begin
  if  system_reset(0) = '1' then
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
  joystick0       => joystick1,
  joystick1       => joystick2,
  numpad          => numpad,
  keyboard_matrix_out => keyboard_matrix_out,
  keyboard_matrix_in  => keyboard_matrix_in,
  key_restore     => freeze_key,
  tape_play       => open,
  mod_key         => open,
  mouse_btns      => mouse_btns,
  mouse_x         => mouse_x,
  mouse_y         => mouse_y,
  mouse_strobe    => mouse_strobe
 );

module_inst: entity work.sysctrl 
 port map 
 (
  clk                 => clk32,
  reset               => not pll_locked,
--
  data_in_strobe      => mcu_sys_strobe,
  data_in_start       => mcu_start,
  data_in             => mcu_data_out,
  data_out            => sys_data_out,

  -- values that can be configured by the user
  system_chipset      => open,
  system_memory       => open,
  system_reu_cfg      => reu_cfg,
  system_reset        => system_reset,
  system_scanlines    => system_scanlines,
  system_volume       => system_volume,
  system_wide_screen  => system_wide_screen,
  system_floppy_wprot => system_floppy_wprot,
  system_port_1       => port_1_sel,
  system_port_2       => port_2_sel,
  system_dos_sel      => dos_sel,
  system_1541_reset   => c1541_osd_reset,
  system_audio_filter => sid_filter,
  system_turbo_mode   => turbo_mode,
  system_turbo_speed  => turbo_speed,
  system_video_std    => ntscMode,
  system_midi         => st_midi,
  system_pause        => system_pause,

  int_out_n           => m0s(4),
  int_in              => std_logic_vector(unsigned'("0000" & sdc_int & '0' & hid_int & '0')),
  int_ack             => int_ack,

  buttons             => std_logic_vector(unsigned'(not reset & not user)), -- S0 and S1 buttons on Tang Nano 20k
  leds                => system_leds,         -- two leds can be controlled from the MCU
  color               => ws2812_color -- a 24bit color to e.g. be used to drive the ws2812
);

process(clk32)
variable toX:	integer;
begin
  if rising_edge(clk32) then
    c64_iec_clk_old   <= iec_clk_i;
    drive_iec_clk_old <= iec_clk_o;
    drive_stb_i_old   <= pc2_n;
    drive_stb_o_old   <= flag2_n;
    if ( c64_iec_clk_old /= iec_clk_i or drive_iec_clk_old /= iec_clk_o or ((drive_stb_i_old /= pc2_n or drive_stb_o_old /= flag2_n) and ext_en = '1') ) then
        disk_access <= '1';
        toX := 16000000; -- 0.5s
    elsif (toX /= 0) then
      toX := toX - 1;
    else  
      disk_access <= '0';
    end if;
  end if;
end process;

io_data <=  unsigned(cart_data) when cart_oe  = '1' else unsigned(midi_data) when midi_oe  = '1' else unsigned(reu_dout);

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
  ramDin       => sdram_data,
  ramDout      => c64_data_out,
  ramCE        => ram_ce,
  ramWE        => ram_we,
  io_cycle     => io_cycle,
  ext_cycle    => ext_cycle,
  refresh      => idle,

  cia_mode     => '0',
  turbo_mode   => ((turbo_mode(1) and not disk_access) & turbo_mode(0)),
  turbo_speed  => turbo_speed,

  vic_variant  => "00",
  ntscMode     => ntscMode,
  hsync        => hsync,
  vsync        => vsync,
  r            => r,
  g            => g,
  b            => b,
  debugX       => open,
	debugY       => open,

  phi          => phi,

  game         => game,
  exrom        => exrom,
  io_rom       => io_rom,
  io_ext       => (reu_oe or cart_oe or midi_oe),
  io_data      => io_data,
  irq_n        => midi_irq_n,
  nmi_n        => (not nmi and midi_nmi_n),
  nmi_ack      => nmi_ack,
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
  joyA         => joyA,
  joyB         => joyB,
  pot1         => pot1,
  pot2         => pot2,
  pot3         => pot3,
  pot4         => pot4,

  --SID
  audio_l      => audio_data_l,
  audio_r      => audio_data_r,
  sid_filter   => '1' & sid_filter,
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
    reset     => system_reset(0) or not pll_locked,
    cfg       => std_logic_vector(unsigned'( '0' & reu_cfg) ),
  
    dma_req   => dma_req,
    dma_cycle => dma_cycle,
    dma_addr  => dma_addr,
    dma_dout  => dma_dout,
    dma_din   => dma_din,
    dma_we    => dma_we,
  
    ram_cycle => ext_cycle,
    ram_addr  => reu_ram_addr,
    ram_dout  => reu_ram_dout,
    ram_din   => dout,
    ram_we    => reu_ram_we,
    
    cpu_addr  => c64_addr, 
    cpu_dout  => c64_data_out,
    cpu_din   => reu_dout,
    cpu_we    => ram_we,
    cpu_cs    => IOF,
    
    irq       => reu_irq
  ); 

-- c1541 ROM's SPI Flash
-- TN20k  Winbond 25Q64JVIQ
-- TP25k  XTX XT25F64FWOIG
-- TM138k Winbond 25Q128BVEA
-- phase shift 135° TN, TP and 270° TM
-- offset in spi flash TN20K, TP25K $200000, TM138K $A00000
flash_inst: entity work.flash 
port map(
    clk       => flash_clk,
    resetn    => flash_lock,
    ready     => flash_ready,
    busy      => open,
    address   => (X"A" & "000" & dos_sel & c1541rom_addr),
    cs        => c1541rom_cs,
    dout      => c1541rom_data,
    mspi_cs   => mspi_cs,
    mspi_di   => mspi_di,
    mspi_hold => mspi_hold,
    mspi_wp   => mspi_wp,
    mspi_do   => mspi_do
);

cartridge_inst: entity work.cartridge
port map
  (
    clk32       => clk32,
    reset_n     => not system_reset(0) and pll_locked,
  
    cart_loading    => ioctl_download and load_crt,
    cart_id         => to_unsigned(99,16), -- CARTRIDGE_NONE -- cart_attached ? cart_id : status[52] ? 8'd99 : 8'd255),
    cart_exrom      => cart_exrom,
    cart_game       => cart_game,
    cart_bank_laddr => cart_bank_laddr,
    cart_bank_size  => cart_bank_size,
    cart_bank_num   => cart_bank_num,
    cart_bank_type  => cart_bank_type,
    cart_bank_raddr => ioctl_load_addr,
    cart_bank_wr    => cart_hdr_wr,
  
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
    data_in     => c64_data_out,
    addr_out    => cart_addr,
  
    freeze_key  => freeze_key,
    mod_key     => '0',
    nmi         => nmi,
    nmi_ack     => nmi_ack
  );

midi_inst : entity work.c64_midi
port map (
  clk32   => clk32,
  reset   => system_reset(0) or not pll_locked or not (st_midi(2) or st_midi(1) or st_midi(0)),
  Mode    => st_midi,
  E       => phi,
  IOE     => IOE,
  A       => std_logic_vector(c64_addr),
  Din     => std_logic_vector(c64_data_out),
  Dout    => midi_data,
  OE      => midi_oe,
  RnW     => not (ram_we and IOE),
  nIRQ    => midi_irq_n,
  nNMI    => midi_nmi_n,

  RX      => midi_rx,
  TX      => midi_tx
);

end Behavioral_top;
