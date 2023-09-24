library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_unsigned.all;
  use ieee.numeric_std.all;

entity C64_DBLSCAN is
  port (
  CLK               : in   std_logic;
  ENA               : in   std_logic;
  index             : in   unsigned(3 downto 0);
  clk_5x_pixel      : in   std_logic;
  clk_pixel         : in   std_logic;
  I_HSYNC           : in   std_logic;
  I_VSYNC           : in   std_logic;
  I_AUDIO_PCM_L     : in   std_logic_vector( 15 downto 0);
  I_AUDIO_PCM_R     : in   std_logic_vector( 15 downto 0);
  tmds_clk_n        : out  std_logic;
  tmds_clk_p        : out  std_logic;
  tmds_d_n          : out  std_logic_vector( 2 downto 0);
  tmds_d_p          : out  std_logic_vector( 2 downto 0)
  );
end;

architecture RTL of C64_DBLSCAN is

signal O_R               :    std_logic_vector( 7 downto 0);
signal O_G               :    std_logic_vector( 7 downto 0);
signal O_B               :    std_logic_vector( 7 downto 0);
signal vic_r             :    unsigned( 7 downto 0);
signal vic_g             :    unsigned( 7 downto 0);
signal vic_b             :    unsigned( 7 downto 0);
signal O_HSYNC, O_VSYNC, O_BLANK : std_logic;
signal int_BLANK, int_VSYNC, int_HSYNC : std_logic;

signal o_rgb_out        : std_logic_vector(3 downto 0);
signal serialized_c     : std_logic;
signal serialized_r     : std_logic;
signal serialized_g     : std_logic;
signal serialized_b     : std_logic;
signal tmds_r           : std_logic_vector(9 downto 0);
signal tmds_g           : std_logic_vector(9 downto 0);
signal tmds_b           : std_logic_vector(9 downto 0);
signal hsync_int        : std_logic;
signal vsync_int        : std_logic;
-- HDMI signals
signal hsync1           : std_logic;
signal vsync1           : std_logic;
signal hcnt             : std_logic_vector(9 downto 0);
signal vcnt             : std_logic_vector(9 downto 0);
signal hdmi_aspect_169  : std_logic;
signal hdmi_red         : std_logic_vector(7 downto 0);
signal hdmi_green       : std_logic_vector(7 downto 0);
signal hdmi_blue        : std_logic_vector(7 downto 0);
signal hdmi_hsync       : std_logic;
signal hdmi_vsync       : std_logic;
signal hdmi_blank       : std_logic;
signal audio_l_int      : std_logic_vector (15 downto 0);
signal audio_r_int      : std_logic_vector (15 downto 0);
signal vid_debug        : std_logic := '0';
signal hdmi_audio_en    : std_logic := '1';
signal vic_audio_s      : std_logic_vector(15 downto 0);

component fpga64_rgbcolor is
	port (
		index: in unsigned(3 downto 0);
		r: out unsigned(7 downto 0);
		g: out unsigned(7 downto 0);
		b: out unsigned(7 downto 0)
	);
end component;

component rgb2vga_scandoubler
    generic (
        WIDTH : integer
        );
    port (
        clock     : in  std_logic;
        clken     : in  std_logic;
        clk_pixel : in  std_logic;
        rgbi_in   : in  std_logic_vector(WIDTH - 1 downto 0);
        hSync_in  : in  std_logic;
        vSync_in  : in  std_logic;
        rgbi_out  : out std_logic_vector(WIDTH - 1 downto 0);
        hSync_out : out std_logic;
        vSync_out : out std_logic
        );
end component;

COMPONENT ELVDS_OBUF
  PORT (
  O:INOUT std_logic;
  OB:INOUT std_logic;
  I:IN std_logic
  );
end component;

COMPONENT OSER10
   GENERIC (
        GSREN:string:="false";
        LSREN:string:="true"
   );
   PORT(
       Q:OUT std_logic;
       D0:IN std_logic;
       D1:IN std_logic;
       D2:IN std_logic;
       D3:IN std_logic;
       D4:IN std_logic;
       D5:IN std_logic;
       D6:IN std_logic;
       D7:IN std_logic;
       D8:IN std_logic;
       D9:IN std_logic;
       FCLK:IN std_logic;
       PCLK:IN std_logic;
       RESET:IN std_logic
   );
END COMPONENT;

component hdmi 
   generic (
      FREQ: integer := 27000000;              -- pixel clock frequency
      FS: integer := 48000;                   -- audio sample rate - should be 32000, 44100 or 48000
      CTS: integer := 27000;                  -- CTS = Freq(pixclk) * N / (128 * Fs)
      N: integer := 6144                      -- N = 128 * Fs /1000,  128 * Fs /1500 <= N <= 128 * Fs /300
                          -- Check HDMI spec 7.2 for details
   );
   port (
      -- clocks
      I_CLK_PIXEL    : in std_logic;
      -- components
      I_R            : in std_logic_vector(7 downto 0);
      I_G            : in std_logic_vector(7 downto 0);
      I_B            : in std_logic_vector(7 downto 0);
      I_BLANK        : in std_logic;
      I_HSYNC        : in std_logic;
      I_VSYNC        : in std_logic;
      I_ASPECT_169   : in std_logic;
      -- PCM audio
      I_AUDIO_ENABLE : in std_logic;
      I_AUDIO_PCM_L  : in std_logic_vector(15 downto 0);
      I_AUDIO_PCM_R  : in std_logic_vector(15 downto 0);
      -- TMDS parallel pixel synchronous outputs (serialize LSB first)
      O_RED          : out std_logic_vector(9 downto 0); -- Red
      O_GREEN        : out std_logic_vector(9 downto 0); -- Green
      O_BLUE         : out std_logic_vector(9 downto 0)  -- Blue
);
end component;

begin


c64colors: entity work.fpga64_rgbcolor
port map (
	index => unsigned(o_rgb_out),
	r => vic_r,
	g => vic_g,
	b => vic_b
);

rgb2vga: rgb2vga_scandoubler
generic map (
    WIDTH => 4 )
port map (
    clock     => CLK,
    clken     => ENA,
    clk_pixel => clk_pixel,
    rgbi_in   => std_logic_vector(index),
    hSync_in  => I_HSYNC,
    vSync_in  => I_VSYNC,
    rgbi_out  => o_rgb_out,
    hSync_out => hsync_int,
    vSync_out => vsync_int
);

--------------------------------------------------------
-- HDMI
--------------------------------------------------------
-- Recreate the video sync/blank signals that match standard HDTV 720x576p
--
-- Modeline "720x576 @ 50hz"  27    720   732   796   864   576   581   586   625
--
-- Hcnt is set to 0 on the trailing edge of hsync from core
-- so the H constants below need to be offset by 864-796=68
--
-- Vcnt is set to 0 on the trailing edge of vsync from the core
-- so the V constants below need to be offset by 625-586=39

process(clk_pixel)
    variable voffset : integer;
    variable vsize   : integer;
begin
    if rising_edge(clk_pixel) then
        hsync1 <= hsync_int;
        if hsync1 = '0' and hsync_int = '1' then
            hcnt <= (others => '0');
            vsync1 <= vsync_int;
            if vsync1 = '0' and vsync_int = '1' then
                vcnt <= (others => '0');
            else
                vcnt <= vcnt + 1;
            end if;
        else
            hcnt <= hcnt + 1;
        end if;
            voffset := 39;
            vsize   := 576;
        if hcnt < 68 or hcnt >= 68 + 720 or vcnt < voffset or vcnt >= voffset + vsize then
            hdmi_blank <= '1';
            hdmi_red   <= (others => '0');
            hdmi_green <= (others => '0');
            hdmi_blue  <= (others => '0');
        else
            hdmi_blank <= '0';
            hdmi_red   <= std_logic_vector(vic_r);
            hdmi_green <= std_logic_vector(vic_g);
            hdmi_blue  <= std_logic_vector(vic_b);
        end if;
        if hcnt >= 732 + 68 then -- 800
            hdmi_hsync <= '0';
            if vcnt >= 581 + 39 then -- 620
               hdmi_vsync <= '0';
            else
               hdmi_vsync <= '1';
            end if;
        else
          hdmi_hsync <= '1';
        end if;
    end if;
end process;


inst_hdmi: hdmi
    generic map (
        FREQ => 27000000,  -- pixel clock frequency
        FS   => 48000,     -- audio sample rate - should be 32000, 44100 or 48000
        CTS  => 27000,     -- CTS = Freq(pixclk) * N / (128 * Fs)
        N    => 6144       -- N = 128 * Fs /1000,  128 * Fs /1500 <= N <= 128 * Fs /300
        )
    port map (
        -- clocks
        I_CLK_PIXEL      => clk_pixel,
        -- components
        I_R              => hdmi_red,
        I_G              => hdmi_green,
        I_B              => hdmi_blue,
        I_BLANK          => hdmi_blank,
        I_HSYNC          => hdmi_hsync,
        I_VSYNC          => hdmi_vsync,
        I_ASPECT_169     => '1',
        -- PCM audio
        I_AUDIO_ENABLE   => '1',
        I_AUDIO_PCM_L    => I_AUDIO_PCM_L,
        I_AUDIO_PCM_R    => I_AUDIO_PCM_R,
        -- TMDS parallel pixel synchronous outputs (serialize LSB first)
        O_RED            => tmds_r,
        O_GREEN          => tmds_g,
        O_BLUE           => tmds_b
        );
--------------------------------------------------------
-- HDMI Output
--------------------------------------------------------
--  Serialize the three 10-bit TMDS channels to three serialized 1-bit TMDS streams

ser_b: OSER10
    generic map (
        GSREN => "false",
        LSREN => "true"
    )
    port map(
        PCLK  => clk_pixel,
        FCLK  => clk_5x_pixel,
        RESET => '0',
        Q     => serialized_b,
        D0    => tmds_b(0),
        D1    => tmds_b(1),
        D2    => tmds_b(2),
        D3    => tmds_b(3),
        D4    => tmds_b(4),
        D5    => tmds_b(5),
        D6    => tmds_b(6),
        D7    => tmds_b(7),
        D8    => tmds_b(8),
        D9    => tmds_b(9)
    );

ser_g: OSER10
    generic map (
        GSREN => "false",
        LSREN => "true"
    )
    port map (
        PCLK  => clk_pixel,
        FCLK  => clk_5x_pixel,
        RESET => '0',
        Q     => serialized_g,
        D0    => tmds_g(0),
        D1    => tmds_g(1),
        D2    => tmds_g(2),
        D3    => tmds_g(3),
        D4    => tmds_g(4),
        D5    => tmds_g(5),
        D6    => tmds_g(6),
        D7    => tmds_g(7),
        D8    => tmds_g(8),
        D9    => tmds_g(9)
    );

ser_r: OSER10
    generic map (
        GSREN => "false",
        LSREN => "true"
    )
    port map (
        PCLK  => clk_pixel,
        FCLK  => clk_5x_pixel,
        RESET => '0',
        Q     => serialized_r,
        D0    => tmds_r(0),
        D1    => tmds_r(1),
        D2    => tmds_r(2),
        D3    => tmds_r(3),
        D4    => tmds_r(4),
        D5    => tmds_r(5),
        D6    => tmds_r(6),
        D7    => tmds_r(7),
        D8    => tmds_r(8),
        D9    => tmds_r(9)
        );

ser_c: OSER10
    generic map (
        GSREN => "false",
        LSREN => "true"
    )
    port map (
        PCLK  => clk_pixel,
        FCLK  => clk_5x_pixel,
        RESET => '0',
        Q     => serialized_c,
        D0    => '1',
        D1    => '1',
        D2    => '1',
        D3    => '1',
        D4    => '1',
        D5    => '0',
        D6    => '0',
        D7    => '0',
        D8    => '0',
        D9    => '0'
    );

-- Encode the 1-bit serialized TMDS streams to Low-voltage differential signaling (LVDS) HDMI output pins

OBUFDS_c : ELVDS_OBUF
    port map (
        I  => serialized_c,
        O  => tmds_clk_p,
        OB => tmds_clk_n
        );

OBUFDS_b : ELVDS_OBUF
    port map (
        I  => serialized_b,
        O  => tmds_d_p(0),
        OB => tmds_d_n(0)
    );

OBUFDS_g : ELVDS_OBUF
    port map (
        I  => serialized_g,
        O  => tmds_d_p(1),
        OB => tmds_d_n(1)
    );

OBUFDS_r : ELVDS_OBUF
    port map (
        I  => serialized_r,
        O  => tmds_d_p(2),
        OB => tmds_d_n(2)
    );
 end architecture RTL;
