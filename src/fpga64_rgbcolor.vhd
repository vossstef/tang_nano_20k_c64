-- -----------------------------------------------------------------------
--
--                                 FPGA 64
--
--     A fully functional commodore 64 implementation in a single FPGA
--
-- -----------------------------------------------------------------------
--
-- C64 palette index to 24 bit RGB color
-- AUTHOR=EMARD
--
-- -----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

-- -----------------------------------------------------------------------

entity fpga64_rgbcolor is
	port (
		index: in unsigned(3 downto 0);
		r: out unsigned(7 downto 0);
		g: out unsigned(7 downto 0);
		b: out unsigned(7 downto 0)
	);
end fpga64_rgbcolor;

-- -----------------------------------------------------------------------

architecture Behavioral of fpga64_rgbcolor is
type t64_colors is array(0 to 15) of unsigned(23 downto 0);
constant c64_colors : t64_colors :=
( -- colors from https://www.c64-wiki.com/wiki/Color
x"000000", -- 0 black
x"FFFFFF", -- 1 white
x"880000", -- 2 red
x"AAFFEE", -- 3 cyan
x"CC44CC", -- 4 purple
x"00CC55", -- 5 green
x"2C379D", -- 6 blue
x"EEEE77", -- 7 yellow
x"DD8855", -- 8 orange
x"602C00", -- 9 brown
x"FF7777", -- A light red
x"333333", -- B dark grey
x"777777", -- C grey
x"AAFF66", -- D light green
x"848EF4", -- E light blue
x"BBBBBB"  -- F light grey
);
begin
	r <= c64_colors(to_integer(index))(23 downto 16);
	g <= c64_colors(to_integer(index))(15 downto  8);
	b <= c64_colors(to_integer(index))( 7 downto  0);
end Behavioral;
