-- -----------------------------------------------------------------------
--
--                                 FPGA 64
--
--     A fully functional commodore 64 implementation in a single FPGA
--
-- -----------------------------------------------------------------------
-- Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/fpga64.html
-- -----------------------------------------------------------------------
--
-- System runs on 32 Mhz
-- The VIC-II runs in 4 cycles of first 16 cycles.
-- The CPU runs in the last 16 cycles. Effective cpu speed is 1 Mhz.
-- 
-- -----------------------------------------------------------------------
-- Dar 08/03/2014 
--
-- Based on fpga64_cone
-- add external selection for 15KHz(TV)/31KHz(VGA)
-- add external selection for power on NTSC(60Hz)/PAL(50Hz)
-- add external conection in/out for IEC signal
-- add sid entity 
-- -----------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.ALL;

entity tang_nano_20k_c64 is
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
    ps2_data    : in std_logic;
    ps2_clk     : in std_logic;
    tmds_clk_n  : out std_logic;
    tmds_clk_p  : out std_logic;
    tmds_d_n    : out std_logic_vector( 2 downto 0);
    tmds_d_p    : out std_logic_vector( 2 downto 0);
    -- sd interface
    sd_clk      : out std_logic; -- SCLK
    sd_cmd      : out std_logic; -- MOSI
    sd_dat0     : in std_logic; -- MISO
    sd_dat1     : in std_logic; -- unused
    sd_dat2     : in std_logic; -- unused
    sd_dat3     : out std_logic; -- CSn
    -- Debug
    debug       : out std_logic_vector(4 downto 0);
    ws2812      : out std_logic;
    -- BL616 controller SPI interface connections (reserved)
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

architecture Behavioral of tang_nano_20k_c64 is

signal clk_pixel, clk_shift, shift_locked  : std_logic;
signal clk32, clk32_locked, clk16: std_logic;

attribute syn_keep : integer;
attribute syn_keep of clk32 : signal is 1;
attribute syn_keep of clk16 : signal is 1;

signal R_btn_joy: std_logic_vector(4 downto 0);
-------------------------------------
-- System state machine
constant CYCLE_IDLE0: unsigned(4 downto 0) := to_unsigned( 0, 5);
constant CYCLE_IDLE1: unsigned(4 downto 0) := to_unsigned( 1, 5);
constant CYCLE_IDLE2: unsigned(4 downto 0) := to_unsigned( 2, 5);
constant CYCLE_IDLE3: unsigned(4 downto 0) := to_unsigned( 3, 5);
constant CYCLE_IDLE4: unsigned(4 downto 0) := to_unsigned( 4, 5);
constant CYCLE_IDLE5: unsigned(4 downto 0) := to_unsigned( 5, 5);
constant CYCLE_IDLE6: unsigned(4 downto 0) := to_unsigned( 6, 5);
constant CYCLE_IDLE7: unsigned(4 downto 0) := to_unsigned( 7, 5);
constant CYCLE_IEC0 : unsigned(4 downto 0) := to_unsigned( 8, 5);
constant CYCLE_IEC1 : unsigned(4 downto 0) := to_unsigned( 9, 5);
constant CYCLE_IEC2 : unsigned(4 downto 0) := to_unsigned(10, 5);
constant CYCLE_IEC3 : unsigned(4 downto 0) := to_unsigned(11, 5);
constant CYCLE_VIC0 : unsigned(4 downto 0) := to_unsigned(12, 5);
constant CYCLE_VIC1 : unsigned(4 downto 0) := to_unsigned(13, 5);
constant CYCLE_VIC2 : unsigned(4 downto 0) := to_unsigned(14, 5);
constant CYCLE_VIC3 : unsigned(4 downto 0) := to_unsigned(15, 5);
constant CYCLE_CPU0 : unsigned(4 downto 0) := to_unsigned(16, 5);
constant CYCLE_CPU1 : unsigned(4 downto 0) := to_unsigned(17, 5);
constant CYCLE_CPU2 : unsigned(4 downto 0) := to_unsigned(18, 5);
constant CYCLE_CPU3 : unsigned(4 downto 0) := to_unsigned(19, 5);
constant CYCLE_CPU4 : unsigned(4 downto 0) := to_unsigned(20, 5);
constant CYCLE_CPU5 : unsigned(4 downto 0) := to_unsigned(21, 5);
constant CYCLE_CPU6 : unsigned(4 downto 0) := to_unsigned(22, 5);
constant CYCLE_CPU7 : unsigned(4 downto 0) := to_unsigned(23, 5);
constant CYCLE_CPU8 : unsigned(4 downto 0) := to_unsigned(24, 5);
constant CYCLE_CPU9 : unsigned(4 downto 0) := to_unsigned(25, 5);
constant CYCLE_CPUA : unsigned(4 downto 0) := to_unsigned(26, 5);
constant CYCLE_CPUB : unsigned(4 downto 0) := to_unsigned(27, 5);
constant CYCLE_CPUC : unsigned(4 downto 0) := to_unsigned(28, 5);
constant CYCLE_CPUD : unsigned(4 downto 0) := to_unsigned(29, 5);
constant CYCLE_CPUE : unsigned(4 downto 0) := to_unsigned(30, 5);
constant CYCLE_CPUF : unsigned(4 downto 0) := to_unsigned(31, 5);

signal sysCycle     : unsigned(4 downto 0) := (others => '0');
signal phi0_cpu     : std_logic;
signal cpuHasBus    : std_logic;

signal baLoc        : std_logic;
signal irqLoc       : std_logic;
signal nmiLoc       : std_logic;
signal aec          : std_logic;

signal enableCpu    : std_logic;
signal enableVic    : std_logic;
signal enablePixel  : std_logic;

signal irq_cia1     : std_logic;
signal irq_cia2     : std_logic;
signal irq_vic      : std_logic;

signal ps2_key      : std_logic_vector(10 downto 0);

signal systemWe     : std_logic;
signal pulseWrRam   : std_logic;
signal colorWe      : std_logic;
signal systemAddr   : unsigned(15 downto 0);
signal ramDataReg   : unsigned(7 downto 0);

-- external memory
signal ramAddr     : unsigned(15 downto 0);
signal ramDataIn   : unsigned(7 downto 0);
signal ramDataOut  : unsigned(15 downto 0);
signal ramDataIn_vec : std_logic_vector(15 downto 0);

signal ram_CE       : std_logic;
signal ram_WE       : std_logic;

signal io_cycle    : std_logic;
signal idle        : std_logic;
signal cia_mode    : std_logic  := '0';

signal cs_vic       : std_logic;
signal cs_sid       : std_logic;
signal cs_color     : std_logic;
signal cs_cia1      : std_logic;
signal cs_cia2      : std_logic;
signal cs_ram       : std_logic;
signal cs_ioE       : std_logic;
signal cs_ioF       : std_logic;
signal cs_romL      : std_logic;
signal cs_romH      : std_logic;
signal cs_UMAXromH  : std_logic; -- romH VIC II read flag
signal cpuWe        : std_logic;
signal cpuAddr      : unsigned(15 downto 0);
signal cpuDi        : unsigned(7 downto 0);
signal cpuDo        : unsigned(7 downto 0);
signal cpuIO        : unsigned(7 downto 0);
signal cpudiIO      : unsigned(7 downto 0);

signal reset        : std_logic := '1';
signal reset_cnt    : integer range 0 to resetCycles := 0;

-- CIA signals
signal enableCia_p  : std_logic;
signal enableCia_n  : std_logic;
signal cia1Do       : unsigned(7 downto 0);
signal cia2Do       : unsigned(7 downto 0);
signal cia1_pai     : unsigned(7 downto 0);
signal cia1_pao     : unsigned(7 downto 0);
signal cia1_pbi     : unsigned(7 downto 0);
signal cia1_pbo     : unsigned(7 downto 0);
signal cia2_pai     : unsigned(7 downto 0);
signal cia2_pao     : unsigned(7 downto 0);
signal cia2_pbo     : unsigned(7 downto 0);
signal cia2_pbe     : unsigned(7 downto 0);

signal todclk       : std_logic;

-- video
constant ntscMode   : std_logic := '0';
signal vicColorIndex : unsigned(3 downto 0);
signal vicHSync     : std_logic;
signal vicVSync     : std_logic;
signal vicBus       : unsigned(7 downto 0);
signal vicDi        : unsigned(7 downto 0);
signal vicDiAec     : unsigned(7 downto 0);
signal vicAddr      : unsigned(15 downto 0);
signal vicData      : unsigned(7 downto 0);
signal lastVicDi    : unsigned(7 downto 0);
signal vicAddr1514  : unsigned(1 downto 0);
signal colorQ       : unsigned(3 downto 0);
signal colorData    : unsigned(3 downto 0);
signal colorDataAec : unsigned(3 downto 0);

-- VGA/SCART interface
signal vic_r        : unsigned(7 downto 0); 
signal vic_g        : unsigned(7 downto 0) ;
signal vic_b        : unsigned(7 downto 0) ;

-- SID signals
signal sid_do       : std_logic_vector(7 downto 0);
signal audio_l      : std_logic_vector(17 downto 0);
signal audio_r      : std_logic_vector(17 downto 0);
signal sid_we       : std_logic;
signal sid_sel_int  : std_logic;
signal sid_wren     : std_logic;
signal clk_1MHz_en  : std_logic; -- single clk pulse

-- "external" connections, in this project internal
-- cartridge port
signal  game        : std_logic := '1';
signal  exrom       : std_logic := '1';
signal  ioE_rom     : std_logic := '1';
signal  ioF_rom     : std_logic := '1';
signal  max_ram     : std_logic := '1';
signal  irq_n       : std_logic := '1';
signal  nmi_n       : std_logic := '1';
signal  nmi_ack     : std_logic; 
signal  ba          : std_logic := '1';
signal  romL        : std_logic := '1'; -- cart signals LCA
signal  romH        : std_logic := '1'; -- cart signals LCA
signal  UMAXromH    : std_logic := '1'; -- cart signals LCA
signal  IOE         : std_logic := '1'; -- cart signals LCA
signal  IOF         : std_logic := '1'; -- cart signals LCA
signal  CPU_hasbus  : std_logic := '1'; -- CPU has the bus STROBE
signal  freeze_key  : std_logic;

signal  ioF_ext     : std_logic;
signal  ioE_ext     : std_logic;
signal  io_data     : unsigned(7 downto 0);

-- joystick interface
signal  joyA        : unsigned(6 downto 0) := (others => '1');
signal  joyB        : unsigned(6 downto 0) := (others => '1');
signal  joy_sel     : std_logic := '0'; -- BTN2 toggles joy A/B
signal  btn_debounce: std_logic_vector(6 downto 0);
signal  btn_deb     : std_logic;

-- Connector to the SID
signal  audio_data_l  : signed(17 downto 0);
signal  audio_data_r  : signed(17 downto 0);
signal  extfilter_en: std_logic := '1';

  -- USER
signal  pb_i        :  unsigned(7 downto 0) := (others => '1');
signal  pb_o        :  unsigned(7 downto 0);
signal  pa2_i       :  std_logic := '1';
signal  pa2_o       :  std_logic;
signal  pc2_n_o     :  std_logic;
signal  flag2_n_i   :  std_logic := '1';
signal  sp2_i       :  std_logic := '1';
signal  sp2_o       :  std_logic;
signal  sp1_i       :  std_logic := '1';
signal  sp1_o       :  std_logic;
signal  cnt2_i      :  std_logic := '1';
signal  cnt2_o      :  std_logic;
signal  cnt1_i      :  std_logic := '1';
signal  cnt1_o      :  std_logic;

-- IEC
signal  iec_data_o  : std_logic;
signal  iec_data_i  : std_logic;
signal  iec_clk_o   : std_logic;
signal  iec_clk_i   : std_logic;
signal  iec_atn_o   : std_logic;
signal  iec_atn_i   : std_logic;

-- external (SPI) ROM update
signal  c64rom_addr : std_logic_vector(13 downto 0) := (others => '0');
signal  c64rom_data : std_logic_vector(7 downto 0) := (others => '0');
signal  c64rom_wr   : std_logic := '0';

-- cassette
signal  cass_motor  : std_logic;
signal  cass_write  : std_logic;
signal  cass_sense  : std_logic := '1';
signal  cass_in     : std_logic := '1';

signal colorQ_vec   : std_logic_vector(3 downto 0);
signal dram_addr    : std_logic_vector(21 downto 0);
signal spare        : std_logic_vector(5 downto 0);

	-- keyboard
signal newScanCode  : std_logic;
signal theScanCode  : unsigned(7 downto 0);
signal disk_num     : std_logic_vector(7 downto 0);
signal joyKeys      : std_logic_vector(6 downto 0);
signal reset_key    : std_logic;
signal disk_reset   : std_logic;

-- CONTROLLER DUALSHOCK
signal dscjoyKeys   : std_logic_vector(6 downto 0);
signal dsc_joy_rx0  : std_logic_vector(7 downto 0);
signal dsc_joy_rx1  : std_logic_vector(7 downto 0);

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

-- verilog components

component mos6526
  port (
    clk           : in  std_logic;
    mode          : in  std_logic := '0'; -- 0 - 6526 "old", 1 - 8521 "new"
    phi2_p        : in  std_logic;
    phi2_n        : in  std_logic;
    res_n         : in  std_logic;
    cs_n          : in  std_logic;
    rw            : in  std_logic; -- '1' - read, '0' - write
    rs            : in  unsigned(3 downto 0);
    db_in         : in  unsigned(7 downto 0);
    db_out        : out unsigned(7 downto 0);
    pa_in         : in  unsigned(7 downto 0);
    pa_out        : out unsigned(7 downto 0);
    pa_oe         : out unsigned(7 downto 0);
    pb_in         : in  unsigned(7 downto 0);
    pb_out        : out unsigned(7 downto 0);
    pb_oe         : out unsigned(7 downto 0);
    flag_n        : in  std_logic;
    pc_n          : out std_logic;
    tod           : in  std_logic;
    sp_in         : in  std_logic;
    sp_out        : out std_logic;
    cnt_in        : in  std_logic;
    cnt_out       : out std_logic;
    irq_n         : out std_logic
  );
end component; 

---------------------------------------------------------
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
    par_data_i    => std_logic_vector(pb_o),
    par_stb_i     => pc2_n_o,
    std_logic_vector(par_data_o) => pb_i,
    par_stb_o     => flag2_n_i,

    dbg_act       => led(1)  -- LED floppy indicator
  );

  disk_reset <= reset or reset_key;

  vga2hdmi_instance: entity work.C64_DBLSCAN 
  port map (
   CLK               => clk32,
   ENA               => enablePixel,
   index             => vicColorIndex,
   clk_5x_pixel      => clk_shift,
   clk_pixel         => clk_pixel,
   I_HSYNC           => vicHSync,
   I_VSYNC           => vicVSync,
   I_AUDIO_PCM_L     => audio_l(17 downto 2),
   I_AUDIO_PCM_R     => audio_r(17 downto 2),
   tmds_clk_n        => tmds_clk_n,
   tmds_clk_p        => tmds_clk_p,
   tmds_d_n          => tmds_d_n,
   tmds_d_p          => tmds_d_p
  );

ramDataIn <= unsigned(ramDataIn_vec(7 downto 0));
dram_addr(15 downto 0)  <= std_logic_vector(ramAddr);
dram_addr(21 downto 16) <= (others => '0');

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
	clk       => clk32,         -- sdram is accessed at 32MHz
	reset_n   => clk32_locked,  -- init signal after FPGA config to initialize RAM
	ready     => open,          -- ram is ready and has been initialized
	refresh   => idle,          -- chipset requests a refresh cycle
	din       => std_logic_vector(ramDataOut), -- data input from chipset/cpu
	dout      => ramDataIn_vec,
	addr      => dram_addr,      -- 22 bit word address
	ds        => (others => '0'),-- upper/lower data strobe R = low and W = low
	cs        => ram_CE,        -- cpu/chipset requests read/wrie
	we        => ram_WE         -- cpu/chipset requests write
);

gsr_inst: GSR
    PORT MAP(
    GSRI => not reset_btn
  );

mainclock: entity work.Gowin_rPLL
    port map (
        clkout  => open,
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
    if vicVSync = '1' then
      if s2_btn = '1' and btn_deb = '0' then  --risige edge of button
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
joyA <=  unsigned(joyKeys) when joy_sel='0' else unsigned(dscjoyKeys); --(others => '0');
joyB <=  unsigned(joyKeys) when joy_sel='1' else unsigned(dscjoyKeys); --(others => '0');
-- -----------------------------------------------------------------------
-- Local signal to outside world
-- -----------------------------------------------------------------------
ba <= baLoc;

idle <= '1' when
		(sysCycle = CYCLE_IDLE0) or (sysCycle = CYCLE_IDLE1) or
		(sysCycle = CYCLE_IDLE2) or (sysCycle = CYCLE_IDLE3) or
		(sysCycle = CYCLE_IDLE4) or (sysCycle = CYCLE_IDLE5) or
		(sysCycle = CYCLE_IDLE6) or (sysCycle = CYCLE_IDLE7) else '0';

-- -----------------------------------------------------------------------
-- System state machine, controls bus accesses
-- and triggers enables of other components
-- -----------------------------------------------------------------------
process(clk32)
begin
  if rising_edge(clk32) then
      sysCycle <= sysCycle+1;
  end if;
end process;

div1m: process(clk32) -- this process divides 32 MHz to 1 MHz for the SID
begin
  if (rising_edge(clk32)) then
    if sysCycle = CYCLE_VIC0 then
          clk_1MHz_en <= '1'; -- single pulse
    else
          clk_1MHz_en <= '0';
    end if;
  end if;
end process;

-- PHI0/2-clock emulation
process(clk32)
begin
  if rising_edge(clk32) then
    if sysCycle = CYCLE_VIC3 then
      phi0_cpu <= '1';
      if baLoc = '1' or cpuWe = '1' then
        cpuHasBus <= '1';
      end if;
    elsif sysCycle = CYCLE_CPUF then
      phi0_cpu <= '0';
      cpuHasBus <= '0';
    end if;
  end if;
end process;

process(clk32)
begin
  if rising_edge(clk32) then
    if sysCycle = CYCLE_IDLE0 then
      enableCia_p <= '0';
    elsif sysCycle = CYCLE_VIC2 then
      enableVic <= '1';
    elsif sysCycle = CYCLE_VIC3 then
      enableVic <= '0';
    elsif sysCycle = CYCLE_CPUC then
      enableCia_n <= '1';
    elsif sysCycle = CYCLE_CPUD then
      enableCia_n <= '0';
    elsif sysCycle = CYCLE_CPUE then
      enableVic <= '1';
      enableCpu <= '1'; 
    elsif sysCycle = CYCLE_CPUF then
      enableVic <= '0';
      enableCpu <= '0';
      enableCia_p <= '1';
    end if;
  end if;
end process;

-- -----------------------------------------------------------------------
-- Color RAM
-- -----------------------------------------------------------------------
colorram: entity work.Gowin_RAM16S_color
port map (
  dout => colorQ_vec,
  wre => colorWe,
  ad => std_logic_vector(systemAddr(9 downto 0)),
  di => std_logic_vector(cpuDo(3 downto 0)),
  clk => clk32
);
colorQ <= unsigned(colorQ_vec);

process(clk32)
begin
  if rising_edge(clk32) then
    colorWe <= (cs_color and pulseWrRam);
    colorData <= colorQ;
  end if;
end process;

-- -----------------------------------------------------------------------
-- PLA and bus-switches with ROM
-- -----------------------------------------------------------------------
buslogic: entity work.fpga64_buslogic
port map (
  clk => clk32,
  reset => reset,

  cpuHasBus => cpuHasBus,
  aec => aec,

  bankSwitch => cpuIO(2 downto 0),

  game => game,
  exrom => exrom,
  ioE_rom => ioE_rom,
  ioF_rom => ioF_rom,
  max_ram => max_ram,

  ramData => ramDataReg,

  ioF_ext => ioF_ext,
  ioE_ext => ioE_ext,
  io_data => io_data,

  cpuWe => cpuWe,
  cpuAddr => cpuAddr,
  cpuData => cpuDo,
  vicAddr => vicAddr,
  vicData => vicData,
  sidData => unsigned(sid_do),
  colorData => colorData,
  cia1Data => cia1Do,
  cia2Data => cia2Do,
  lastVicData => lastVicDi,

  systemWe => systemWe,
  systemAddr => systemAddr,
  dataToCpu => cpuDi,
  dataToVic => vicDi,

  cs_vic => cs_vic,
  cs_sid => cs_sid,
  cs_color => cs_color,
  cs_cia1 => cs_cia1,
  cs_cia2 => cs_cia2,
  cs_ram => cs_ram,
  cs_ioE => cs_ioE,
  cs_ioF => cs_ioF,
  cs_romL => cs_romL,
  cs_romH => cs_romH,
  cs_UMAXromH => cs_UMAXromH,

  c64rom_addr => c64rom_addr,
  c64rom_data => c64rom_data,
  c64rom_wr => c64rom_wr
);

process(clk32)
begin
  if rising_edge(clk32) then
    if cpuWe = '1' and sysCycle = CYCLE_CPUC then
                        pulseWrRam <= '1';
                else
                        pulseWrRam <= '0';
    end if;
  end if;
end process;

-- -----------------------------------------------------------------------
-- VIC-II video interface chip
-- -----------------------------------------------------------------------
process(clk32)
begin
  if rising_edge(clk32) then
    if phi0_cpu = '1' then
      if cpuWe = '1' and cs_vic = '1' then
        vicBus <= cpuDo;
      else
        vicBus <= x"FF";
      end if;
    end if;
  end if;
end process;

-- In the first three cycles after BA went low, the VIC reads
-- $ff as character pointers and
-- as color information the lower 4 bits of the opcode after the access to $d011.
vicDiAec <= vicBus when aec = '0' else vicDi;
colorDataAec <= cpuDi(3 downto 0) when aec = '0' else colorData;

vic: entity work.video_vicii_656x
generic map (
  registeredAddress => false,
  emulateRefresh    => true,
  emulateLightpen   => true,
  emulateGraphics   => true
)      
port map (
  clk => clk32,
  reset => reset,
  enaPixel => enablePixel,
  enaData => enableVic,
  phi => phi0_cpu,
  
  baSync => '0',
  ba => baLoc,
  ba_dma =>  open,
  mode6567old => '0', -- 60 Hz NTSC USA
  mode6567R8  => '0', -- 60 Hz NTSC USA
  mode6569    => '1', -- 50 Hz PAL-B Europe
  mode6572    => '0', -- 50 Hz PAL-N southern South America (not Brazil)
  turbo_en => '0',
  turbo_state => open,
  
  cs => cs_vic,
  we => cpuWe,
  lp_n => cia1_pbi(4), -- light pen
  aRegisters => cpuAddr(5 downto 0),
  diRegisters => cpuDo,
  -- video data bus
  di => vicDiAec,
  diColor => colorDataAec,
  do => vicData,
  vicAddr => vicAddr(13 downto 0),
  addrValid => aec,
  -- VGA
  hsync => vicHSync,
  vsync => vicVSync,
  colorIndex => vicColorIndex,

  irq_n => irq_vic,

	-- Debug outputs
	debugX  => open,
	debugY  => open,
	vicRefresh => open
  );

-- Pixel timing
process(clk32)
begin
  if rising_edge(clk32) then
    enablePixel <= '0';
    if sysCycle = CYCLE_VIC2
    or sysCycle = CYCLE_IDLE2
    or sysCycle = CYCLE_IDLE6
    or sysCycle = CYCLE_IEC2
    or sysCycle = CYCLE_CPU2
    or sysCycle = CYCLE_CPU6
    or sysCycle = CYCLE_CPUA
    or sysCycle = CYCLE_CPUE then
      enablePixel <= '1';
    end if;
  end if;
end process;

-- -----------------------------------------------------------------------
-- SID
-- -----------------------------------------------------------------------
sid_6581: entity work.sid_top
port map (
  clock => clk32,
  reset => reset,

  addr  => "000" & cpuAddr(4 downto 0),
  wren  => pulseWrRam and phi0_cpu and cs_sid,
  wdata => std_logic_vector(cpuDo),
  rdata => sid_do,

  potx => (others => '0'),
  poty => (others => '0'),

  comb_wave_l => '0',
  comb_wave_r => '0',

  extfilter_en => '1',

  start_iter => clk_1MHz_en,
  sample_left => audio_data_l,
  sample_right => audio_data_r
);

    audio_l <= std_logic_vector(audio_data_l);
    audio_r <= std_logic_vector(audio_data_r);

-- -----------------------------------------------------------------------
-- CIAs
-- -----------------------------------------------------------------------
cia1: mos6526
port map (
  clk => clk32,
  mode => cia_mode,
  phi2_p => enableCia_p,
  phi2_n => enableCia_n,
  res_n => not reset,
  cs_n => not cs_cia1,
  rw => not cpuWe,

  rs => cpuAddr(3 downto 0),
  db_in => cpuDo,
  db_out => cia1Do,

  pa_in => cia1_pai,
  pa_out => cia1_pao,
  pb_in => cia1_pbi,
  pb_out => cia1_pbo,

  flag_n => cass_in,
  sp_in => sp1_i,
  sp_out => sp1_o,
  cnt_in => cnt1_i,
  cnt_out => cnt1_o,

  tod => todclk,

  irq_n => irq_cia1
);

cia2: mos6526
port map (
  clk => clk32,
  mode => cia_mode,
  phi2_p => enableCia_p,
  phi2_n => enableCia_n,
  res_n => not reset,
  cs_n => not cs_cia2,
  rw => not cpuWe,

  rs => cpuAddr(3 downto 0),
  db_in => cpuDo,
  db_out => cia2Do,

  pa_in => cia2_pai and cia2_pao,
  pa_out => cia2_pao,
  pb_in => (pb_i and not cia2_pbe) or (cia2_pbo and cia2_pbe),
  pb_out => cia2_pbo,
  pb_oe => cia2_pbe,

  flag_n => flag2_n_i,
  pc_n => pc2_n_o,

  sp_in => sp2_i,
  sp_out => sp2_o,
  cnt_in => cnt2_i,
  cnt_out => cnt2_o,

  tod => todclk,

  irq_n => irq_cia2
);

process(clk32)
variable sum: integer range 0 to 33000000;
begin
  if rising_edge(clk32) then
    if reset = '1' then
      todclk <= '0';
      sum := 0;
    elsif ntscMode = '1' then
      sum := sum + 120;
      if sum >= 32727266 then
        sum := sum - 32727266;
        todclk <= not todclk;
      end if;
    else
      sum := sum + 100;
      if sum >= 31527954 then
        sum := sum - 31527954;
        todclk <= not todclk;
      end if;
    end if;
  end if;
end process;

-- -----------------------------------------------------------------------
-- 6510 CPU
-- -----------------------------------------------------------------------
cpu: entity work.cpu_6510
port map (
  clk => clk32,
  reset => reset,
  enable => enableCpu,
  nmi_n => nmiLoc,
  nmi_ack => nmi_ack,
  irq_n => irqLoc,
  rdy => baLoc,

  di => cpuDi,
  addr => cpuAddr,
  do => cpuDo,
  we => cpuWe,

  diIO => cpudiIO,
  doIO => cpuIO
);

cpudiIO <= cpuIO(7) & cpuIO(6) & cpuIO(5) & cass_sense & cpuIO(3) & "111";

cass_motor <= cpuIO(5);
cass_write <= cpuIO(3);

-- -----------------------------------------------------------------------
-- Keyboard
-- -----------------------------------------------------------------------

mykeyboard : entity work.io_ps2_com
generic map (
  clockFilter => 15,
  ticksPerUsec => sysclk_frequency/10
)
port map (
  clk => clk32,
  reset => reset, -- active high!
  ps2_clk_in => ps2_clk,
  ps2_dat_in => ps2_data,
  ps2_clk_out => open,
  ps2_dat_out => open,
  
  inIdle => open,
  sendTrigger => '0',
  sendByte => (others => '0'),
  sendBusy => open,
  sendDone => open,
  recvTrigger => newScanCode,
--  recvByte => recvByte,
  recvByte(0) => open,
  unsigned(recvByte(8 downto 1)) => theScanCode,
  recvByte(10 downto 9) => open
  );

myKeyboardMatrix: entity work.fpga64_keyboard_matrix
port map (
  clk => clk32,
  theScanCode => theScanCode,
  newScanCode => newScanCode,
  joyA => (not joyA(4 downto 0)),
  joyB => (not joyB(4 downto 0)),
  pai => cia1_pao,
  pbi => cia1_pbo,
  pao => cia1_pai,
  pbo => cia1_pbi,

  videoKey => open,
  traceKey => open,
  trace2Key => open,
  reset_key => reset_key,
  restore_key => open,
  tapPlayStopKey => open,
  disk_num => disk_num,

  backwardsReadingEnabled => '1'
);

-- -----------------------------------------------------------------------
-- Reset button
-- -----------------------------------------------------------------------
calcReset: process(clk32)
begin
  if rising_edge(clk32) then
    if clk32_locked = '0' then
      reset_cnt <= 0;
                elsif sysCycle = CYCLE_CPUF then
      if reset_cnt = resetCycles then
        reset <= '0';
      else
        reset <= '1';
        reset_cnt <= reset_cnt + 1;
      end if;
    end if;
  end if;
end process;

-- Video modes
-- removed

iec_data_o <= not cia2_pao(5);
iec_clk_o <= not cia2_pao(4);
iec_atn_o <= not cia2_pao(3);

ramDataOut(7 downto 0) <= "00" & cia2_pao(5 downto 3) & "000" when sysCycle >= CYCLE_IEC0 and sysCycle <= CYCLE_IEC3 else cpuDo;
ramDataOut(15 downto 8) <= (others => '0');
ramAddr <= systemAddr;
ram_WE <= systemWe when sysCycle > CYCLE_CPU0 and sysCycle < CYCLE_CPUF  else '0';
ram_CE <= cs_ram when (sysCycle >= CYCLE_IEC0 and sysCycle <= CYCLE_VIC3) or
                      (sysCycle >  CYCLE_CPU0 and sysCycle <  CYCLE_CPUF and cs_ram = '1') else '0';

process(clk32)
begin
  if rising_edge(clk32) then
    if sysCycle = CYCLE_CPUD
    or sysCycle = CYCLE_VIC2 then
      ramDataReg <= unsigned(ramDataIn);
    end if;
    if sysCycle = CYCLE_VIC3 then
      lastVicDi <= vicDi;
    end if;
  end if;
end process;

--serialBus
serialBus: process(clk32)
begin
  if rising_edge(clk32) then
    if sysCycle = CYCLE_IEC1 then
      cia2_pai(7) <= iec_data_i and not cia2_pao(5);
      cia2_pai(6) <= iec_clk_i and not cia2_pao(4);
    end if;
  end if;
end process;

iec_data_o <= not cia2_pao(5);
iec_clk_o <= not cia2_pao(4);
iec_atn_o <= not cia2_pao(3);

cia2_pai(5 downto 3) <= cia2_pao(5 downto 3);
cia2_pai(2) <= pa2_i;
cia2_pai(1 downto 0) <= cia2_pao(1 downto 0);
pa2_o <= cia2_pao(2);
pb_o <= cia2_pbo;

-- -----------------------------------------------------------------------
-- VIC bank to address lines
-- -----------------------------------------------------------------------
-- The glue logic on a C64C will generate a glitch during 10 <-> 01
-- generating 00 (in other words, bank 3) for one cycle.
--
-- When using the data direction register to change a single bit 0->1
-- (in other words, decreasing the video bank number by 1 or 2),
-- the bank change is delayed by one cycle. This effect is unstable.
process(clk32)
begin
  if rising_edge(clk32) then
    if phi0_cpu = '0' and enableVic = '1' then
      vicAddr1514 <= not cia2_pao(1 downto 0);
    end if;
  end if;
end process;

-- emulate only the first glitch (enough for Undead from Emulamer)
vicAddr(15 downto 14) <= "11" when ((vicAddr1514 xor not cia2_pao(1 downto 0)) = "11") and (cia2_pao(0) /= cia2_pao(1)) else not unsigned(cia2_pao(1 downto 0));

-- -----------------------------------------------------------------------
-- Interrupt lines
-- -----------------------------------------------------------------------
irqLoc <= irq_cia1 and irq_vic and irq_n; 
nmiLoc <= irq_cia2 and nmi_n;

-- -----------------------------------------------------------------------
-- Cartridge port lines LCA
-- -----------------------------------------------------------------------
romL <= cs_romL;
romH <= cs_romH;
IOE  <= cs_ioE;
IOF  <= cs_ioF;
UMAXromH <= cs_UMAXromH;
CPU_hasbus <= cpuHasBus;

end Behavioral;
