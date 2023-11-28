--
-- Copyright (C) 2013 Chris McClelland
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU Lesser General Public License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rgb2vga_scandoubler is
generic (
    WIDTH : integer
    );
port (
    clock     : in  std_logic;
    clken     : in  std_logic;
    clk_pixel : in  std_logic;
    -- Input 15.625kHz RGB signals
--    rgbi_in   : in  std_logic_vector(WIDTH - 1 downto 0);
    hSync_in  : in  std_logic;
    vSync_in  : in  std_logic;
    r_in      :in  std_logic_vector(7 downto 0);
    g_in      :in  std_logic_vector(7 downto 0);
    b_in      :in  std_logic_vector(7 downto 0);
    -- Output 31.250kHz VGA signals

    r_out :out  std_logic_vector(7 downto 0);
    g_out :out  std_logic_vector(7 downto 0);
    b_out :out  std_logic_vector(7 downto 0);
    hSync_out : out std_logic;
    vSync_out : out std_logic
    );
end entity;

architecture rtl of rgb2vga_scandoubler is
    -- Config parameters
    constant SAMPLE_OFFSET0 : integer := 120;
    constant SAMPLE_WIDTH   : integer := 360;
    constant width25       : integer := 10;
-- 720x576, 27Mhz *5 = 135Mhz pll 
    constant HORIZ_BP      : integer := 68;
    constant HORIZ_DISP    : integer := 720;
    constant HORIZ_FP      : integer := 12;
    constant HORIZ_RT      : integer := 64; -- H Sync

-- Modeline "720x576 @ 50hz"  27    720   732   796   864   576   581   586   625 31.25khz
-- Hcnt is set to 0 on the trailing edge of hsync from core
-- so the H constants below need to be offset by 864-796=68
-- Vcnt is set to 0 on the trailing edge of vsync from the core
-- so the V constants below need to be offset by 625-586=39

-- Registers in the 8MHz clock domain:
    signal hSync_s8        : std_logic;
    signal hSyncStart      : std_logic;
    signal hCount8         : unsigned(9 downto 0) := (others => '0');
    signal hCount8_next    : unsigned(9 downto 0);
    signal lineToggle      : std_logic := '1';
    signal lineToggle_next : std_logic;

    -- Registers in the 27MHz clock domain:
    signal hSync_s27a      : std_logic;
    signal hSync_s27b      : std_logic;
    signal hCount27        : unsigned(9 downto 0) := to_unsigned(HORIZ_DISP + HORIZ_FP, 10);
    signal hCount27_next   : unsigned(9 downto 0);

    -- Signals on the write side of the RAMs:
    signal writeEn0        : std_logic;
    signal writeEn1        : std_logic;

    -- Signals on the read side of the RAMs:
    signal ram0Data        : std_logic_vector(WIDTH - 1 downto 0);
    signal ram1Data        : std_logic_vector(WIDTH - 1 downto 0);

    signal rgbi_out        : std_logic_vector(WIDTH - 1 downto 0);

begin
    -- Two RAM blocks, each straddling the 8MHz and 25MHz clock domains, for storing pixel lines;
    -- whilst we're reading from one at 25MHz, we're writing to the other at 8MHz. Their roles
    -- swap every incoming 64us scanline.

    ram0: entity work.Gowin_DPBi
    port map (
        dina            => r_in & g_in & b_in,
        douta           => open,
        clka            => clock,
        ocea            => '1',
        cea             => writeEn0,
        reseta          => '0',
        wrea            => '1',
        ada(9 downto 0) => std_logic_vector(hCount8),
        clkb            => clk_pixel,
        oceb            => '1',
        ceb             => '1',
        resetb          => '0',
        wreb            => '0',
        ADB             => std_logic_vector(hCount27(9 downto 0)/2),
        dinb            => (others => '0'), 
        doutb           => ram0data
    );

    ram1: entity work.Gowin_DPBi
    port map (
        dina            => r_in & g_in & b_in,
        douta           => open,
        clka            => clock,
        ocea            => '1',
        cea             => writeEn1,
        reseta          => '0',
        wrea            => '1',
        ada(9 downto 0) => std_logic_vector(hCount8),
        clkb            => clk_pixel,
        oceb            => '1',
        ceb             => '1',
        resetb          => '0',
        wreb            => '0',
        ADB             => std_logic_vector(hCount27(9 downto 0)/2),
        dinb            => (others => '0'),
        doutb           => ram1data
    );

    -- 8MHz clock domain ---------------------------------------------------------------------------
    process(clock)
    begin
        if rising_edge(clock) then
            if clken = '1' then
                hSync_s8 <= hSync_in;
                hCount8  <= hCount8_next;
                lineToggle <= lineToggle_next;
            end if;
        end if;
    end process;

    -- Pulses representing the start of incoming HSYNC & VSYNC
    hSyncStart <=
        '1' when hSync_s8 = '0' and hSync_in = '1'
        else '0';

    -- Create horizontal count, aligned to incoming HSYNC
    hCount8_next <=
        to_unsigned(2**10 - SAMPLE_OFFSET0 + 1, 10) when hSyncStart = '1' else
        hCount8 + 1;

    -- Toggle every incoming HSYNC
    lineToggle_next <=
        not(lineToggle) when hSyncStart = '1'
        else lineToggle;

    -- Generate interleaved write signals for dual-port RAMs
    writeEn0 <=
        '1' when hCount8 < SAMPLE_WIDTH and lineToggle = '0' and clken = '1'
        else '0';
    writeEn1 <=
        '1' when hCount8 < SAMPLE_WIDTH and lineToggle = '1' and clken = '1'
        else '0';

    -- Interleave output of dual-port RAMs
    b_out <= rgbi_out(7 downto 0);
    g_out <= rgbi_out(15 downto 8);
    r_out <= rgbi_out(23 downto 16);
   
    rgbi_out <=
        ram0Data when lineToggle = '1'
        else ram1Data;

	-- 27MHz clock domain ---------------------------------------------------------------------------
	process(clk_pixel)
	begin
		if ( rising_edge(clk_pixel) ) then
			hCount27   <= hCount27_next;
			hSync_s27a <= hSync_in;
			hSync_s27b <= hSync_s27a;
			vSync_out  <= vSync_in;
		end if;
	end process;

	-- Generate 27MHz hCount
	hCount27_next <=
		to_unsigned(1024 - HORIZ_RT - HORIZ_BP, 10) when
        (hSync_s27a = '1' and hSync_s27b = '0') or
        (hCount27 = HORIZ_DISP + HORIZ_FP - 1) 
        else hCount27 + 1;

	-- Generate VGA HSYNC
	hSync_out <=
		'0' when hCount27 >= to_unsigned(1024 - HORIZ_RT - HORIZ_BP, 10) and hCount27 < to_unsigned(1024 - HORIZ_BP, 10)
		else '1';
end architecture;