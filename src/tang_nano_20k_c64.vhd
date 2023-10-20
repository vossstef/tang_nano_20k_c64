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
		resetCycles : integer := 4095
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
    -- "Magic" port names that the gowin compiler connects to the on-chip SDRAM
    O_sdram_clk : out std_logic;
    O_sdram_cke : out std_logic;
    O_sdram_cs_n : out std_logic;            -- chip select
    O_sdram_cas_n : out std_logic;           -- columns address select
    O_sdram_ras_n : out std_logic;           -- row address select
    O_sdram_wen_n : out std_logic;           -- write enable
    IO_sdram_dq : inout std_logic_vector(31 downto 0); -- 32 bit bidirectional data bus
    O_sdram_addr : out std_logic_vector(10 downto 0);  -- 11 bit multiplexed address bus
    O_sdram_ba : out std_logic_vector(1 downto 0);     -- two banks
    O_sdram_dqm : out std_logic_vector(3 downto 0)     -- 32/4
  );
end;

architecture Behavioral of tang_nano_20k_c64 is

signal clk_pixel, clk_shift, shift_locked  : std_logic;
signal clk32, clk32_locked: std_logic;

attribute syn_keep : integer;
attribute syn_keep of clk32 : signal is 1;

signal R_btn_joy: std_logic_vector(6 downto 0);
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
signal ramDataIn_vec   : std_logic_vector(15 downto 0);

signal ram_CE       : std_logic;
signal ram_WE       : std_logic;

signal io_cycle    : std_logic;
signal idle        : std_logic;

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
signal cia2_pbi     : unsigned(7 downto 0);
signal cia2_pbo     : unsigned(7 downto 0);

signal todclk       : std_logic;
signal toddiv       : std_logic_vector(19 downto 0);
signal toddiv3      : std_logic_vector(1 downto 0);

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
signal sid_do6581   : std_logic_vector(7 downto 0);
signal sid_we       : std_logic;
signal sid_sel_int  : std_logic;
signal sid_wren     : std_logic;
signal audio_6581_l   : signed(17 downto 0);
signal audio_6581_r   : signed(17 downto 0);
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
signal  nmi_ack     : std_logic := '1';
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
signal  joyA        : std_logic_vector(6 downto 0) := (others => '0');
signal  joyB        : std_logic_vector(6 downto 0) := (others => '0');
signal  joyC        : std_logic_vector(6 downto 0) := (others => '0');
signal  joyD        : std_logic_vector(6 downto 0) := (others => '0');
signal  joy_sel     : std_logic := '0'; -- BTN2 toggles joy A/B
signal  btn_debounce: std_logic_vector(6 downto 0);

-- Connector to the SID
signal  audio_data_l  : std_logic_vector(17 downto 0);
signal  audio_data_r  : std_logic_vector(17 downto 0);
signal  extfilter_en: std_logic := '1';  -- added

-- IEC
signal  iec_data_o  : std_logic;
signal  iec_data_i  : std_logic;
signal  iec_clk_o   : std_logic;
signal  iec_clk_i   : std_logic;
signal  iec_atn_o   : std_logic;

-- external (SPI) ROM update
signal  c64rom_addr : std_logic_vector(13 downto 0) := (others => '0');
signal  c64rom_data : std_logic_vector(7 downto 0) := (others => '0');
signal  c64rom_wr   : std_logic := '0';

-- cassette
signal  cass_motor  : std_logic;
signal  cass_write  : std_logic;
signal  cass_sense  : std_logic;
signal  cass_in     : std_logic;

signal  uart_enable : std_logic;

signal  uart_txd    : std_logic; -- CIA2, PortA(2) 
signal  uart_rts    : std_logic; -- CIA2, PortB(1)
signal  uart_dtr    : std_logic; -- CIA2, PortB(2)
signal  uart_ri_out : std_logic; -- CIA2, PortB(3)
signal  uart_dcd_out: std_logic; -- CIA2, PortB(4)

signal  uart_rxd    : std_logic; -- CIA2, PortB(0)
signal  uart_ri_in  : std_logic; -- CIA2, PortB(3)
signal  uart_dcd_in : std_logic; -- CIA2, PortB(4)
signal  uart_cts    : std_logic; -- CIA2, PortB(6)
signal  uart_dsr    : std_logic; -- CIA2, PortB(7)

signal colorQ_vec   : std_logic_vector(3 downto 0);
signal dram_addr    : std_logic_vector(21 downto 0);
signal ramWe, ramCE : std_logic;

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
    pb_in         : in  unsigned(7 downto 0);
    pb_out        : out unsigned(7 downto 0);
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

component ps2
  port (
    clk           : in  std_logic;
    ps2_clk       : in  std_logic;
    ps2_data      : in  std_logic;
    ps2_key       : out std_logic_vector(10 downto 0)
  );
end component; 

---------------------------------------------------------
begin

  vga2hdmi_instance: entity work.C64_DBLSCAN 
  port map (
   CLK               => clk32,
   ENA               => enablePixel,
   index             => vicColorIndex,
   clk_5x_pixel      => clk_shift,
   clk_pixel         => clk_pixel,
   I_HSYNC           => vicHSync,
   I_VSYNC           => vicVSync,
   I_AUDIO_PCM_L     => audio_data_l(17 downto 2),
   I_AUDIO_PCM_R     => audio_data_r(17 downto 2),
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

hdmi_clockgenerator: entity work.Gowin_rPLL_hdmi
port map (
      clkin  => clk_27mhz,
      clkout => clk_shift,
      reset  => reset_btn,
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
      if R_btn_joy(2)='1' and btn_debounce(2)='0' then
        joy_sel <= not joy_sel;
      end if;
      btn_debounce <= R_btn_joy;
    end if;
  end if;
end process;

led(0) <= joy_sel;
led(1) <= '1';

process(clk32)
begin
  if rising_edge(clk32) then
     R_btn_joy(0) <= '0';        -- was reset in original design
     R_btn_joy(1) <= not btn(4); -- joy fire 
     R_btn_joy(2) <= s2_btn;     -- select Joy port 1 / 2
     R_btn_joy(3) <= not btn(3); -- joy right
     R_btn_joy(4) <= not btn(2); -- joy left
     R_btn_joy(5) <= not btn(1); -- joy down
     R_btn_joy(6) <= not btn(0); -- joy up
  end if;
end process;

joyA <= "00" & R_btn_joy(1) & R_btn_joy(6) & R_btn_joy(5) & R_btn_joy(4) & R_btn_joy(3) when joy_sel='0' 
    else (others => '0');

joyB <= "00" & R_btn_joy(1) & R_btn_joy(6) & R_btn_joy(5) & R_btn_joy(4) & R_btn_joy(3) when joy_sel='1' 
    else (others => '0');

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

  mode6567old => '0', -- 60 Hz NTSC USA
  mode6567R8  => '0', -- 60 Hz NTSC USA
  mode6569    => '1', -- 50 Hz PAL-B Europe
  mode6572    => '0', -- 50 Hz PAL-N southern South America (not Brazil)

  -- CPU bus
  cs => cs_vic,
  we => cpuWe,
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

  lp_n => cia1_pbi(4), -- light pen
  irq_n => irq_vic
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
  sample_left => audio_6581_l,
  sample_right => audio_6581_r
);

process(clk32)
begin
  if rising_edge(clk32) then
    audio_data_l <= std_logic_vector(audio_6581_l);
    audio_data_r <= std_logic_vector(audio_6581_r);
    end if;
end process;

-- -----------------------------------------------------------------------
-- CIAs
-- -----------------------------------------------------------------------
cia1: mos6526
port map (
  clk => clk32,
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
  sp_in => '1',
  cnt_in => '1',

  tod => vicVSync, -- FIXME not exactly 50Hz

  irq_n => irq_cia1
);

cia2: mos6526
port map (
  clk => clk32,
  phi2_p => enableCia_p,
  phi2_n => enableCia_n,
  res_n => not reset,
  cs_n => not cs_cia2,
  rw => not cpuWe,

  rs => cpuAddr(3 downto 0),
  db_in => cpuDo,
  db_out => cia2Do,

  pa_in => cia2_pai,
  pa_out => cia2_pao,
  pb_in => cia2_pbi,
  pb_out => cia2_pbo,

  -- Looks like most of the old terminal programs use the FLAG_N input (and to PB0) on CIA2 to
  -- trigger an interrupt on the falling edge of the RXD input.
  -- (and they don't use the "SP" pin for some reason?) ElectronAsh.
  flag_n => uart_rxd,
  
  sp_in => uart_rxd,  -- Hooking up to the SP pin anyway, ready for the "UP9600" style serial.
  cnt_in => '1',

  tod => vicVSync, -- FIXME not exactly 50Hz

  irq_n => irq_cia2
);

tod_clk: if false generate
-- generate TOD clock from stable 32 MHz
-- Can we simply use vicVSync1?
process(clk32, reset)
begin
  if rising_edge(clk32) then
    toddiv <= toddiv + 1;
    if (ntscMode = '1' and toddiv = 27082 and toddiv3 = "00") or
      (ntscMode = '1' and toddiv = 27083 and toddiv3 /= "00") or
      toddiv = 31999 then
      toddiv <= (others => '0');
      todclk <= not todclk;
      toddiv3 <= toddiv3 + 1;
      if toddiv3 = "10" then toddiv3 <= "00"; end if;
    end if;
  end if;
end process;
end generate;

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
ps2recv: ps2
port map (
  clk      => clk32,
  ps2_clk  => ps2_clk,
  ps2_data => ps2_data,
  ps2_key  => ps2_key
);

Keyboard: entity work.fpga64_keyboard
port map (
  clk => clk32,
  ps2_key => ps2_key,

  joyA => not unsigned(joyA(4 downto 0)),
  joyB => not unsigned(joyB(4 downto 0)),
  pai => cia1_pao,
  pbi => cia1_pbo,
  pao => cia1_pai,
  pbo => cia1_pbi,

  restore_key => freeze_key, -- freeze_key not connected to c64
  backwardsReadingEnabled => '1'
);

-- -----------------------------------------------------------------------
-- Reset button
-- -----------------------------------------------------------------------
calcReset: process(clk32)
begin
  if rising_edge(clk32) then
--    if R_btn_joy(0) = '0' or R_cpu_control(0) = '1' or clk32_locked = '0' then
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

cia2_pai(5 downto 0) <= cia2_pao(5 downto 0);

process(joyC, joyD, cia2_pbo, uart_rxd, uart_ri_in, uart_dcd_in, uart_cts, uart_dsr, uart_enable)
begin
  if uart_enable = '1' then
    cia2_pbi(0) <= uart_rxd;
    cia2_pbi(1) <= '1';
    cia2_pbi(2) <= '1';
    cia2_pbi(3) <= uart_ri_in;
    cia2_pbi(4) <= uart_dcd_in;
    cia2_pbi(5) <= '1';
    cia2_pbi(6) <= uart_cts;
    cia2_pbi(7) <= uart_dsr;
  else
    if cia2_pbo(7) = '1' then
      cia2_pbi(3 downto 0) <= not unsigned(joyC(3 downto 0));
    else
      cia2_pbi(3 downto 0) <= not unsigned(joyD(3 downto 0));
    end if;
    if joyC(6 downto 4) /= "000" then
      cia2_pbi(4) <= '0';
    else
      cia2_pbi(4) <= '1';
    end if;
    if joyD(6 downto 4) /= "000" then
      cia2_pbi(5) <= '0';
    else
      cia2_pbi(5) <= '1';
    end if;
    cia2_pbi(7 downto 6) <= cia2_pbo(7 downto 6);
  end if;
end process;

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
