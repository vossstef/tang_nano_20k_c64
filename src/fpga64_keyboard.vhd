-- -----------------------------------------------------------------------
--
--                                 FPGA 64
--
--     A fully functional commodore 64 implementation in a single FPGA
--
-- -----------------------------------------------------------------------
-- Copyright 2005-2008 by Peter Wendrich (pwsoft@syntiac.com)
-- http://www.syntiac.com/fpga64.html
-- -----------------------------------------------------------------------
-- 'Joystick emulation on keypad' additions by
-- Mark McDougall (msmcdoug@iinet.net.au)
-- -----------------------------------------------------------------------
--
-- VIC20/C64 Keyboard matrix
--
-- Hardware huh?
--	In original machine if a key is pressed a contact is made.
--	Bidirectional reading is possible on real hardware, which is difficult
--	to emulate. (set backwardsReadingEnabled to '1' if you want this enabled).
--	Then we have the joysticks, one of which is normally connected
--	to a OUTPUT pin.
--
-- Emulation:
--	All pins are high except when one is driven low and there is a
--	connection. This is consistent with joysticks that force a line
--	low too. CIA will put '1's when set to input to help this emulation.
--
-- -----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.ALL;
use IEEE.numeric_std.ALL;

entity fpga64_keyboard is
	port (
		clk     : in std_logic;
		reset   : in std_logic;
		
		keyboard_matrix_out : out std_logic_vector(7 downto 0);
		keyboard_matrix_in  : in std_logic_vector(7 downto 0);

		joyA    : in unsigned(6 downto 0);
		joyB    : in unsigned(6 downto 0);
		
		shift_mod: in std_logic_vector(1 downto 0);

		pai     : in unsigned(7 downto 0);
		pbi     : in unsigned(7 downto 0);
		pao     : out unsigned(7 downto 0);
		pbo     : out unsigned(7 downto 0);
		
		restore_key : out std_logic;
		mod_key     : out std_logic;
		tape_play   : out std_logic;
		-- Config
		-- backwardsReadingEnabled = 1 allows reversal of PIA registers to still work.
		-- not needed for kernel/normal operation only for some specific programs.
		-- set to 0 to save some hardware.
		backwardsReadingEnabled : in std_logic
	);
end fpga64_keyboard;

architecture rtl of fpga64_keyboard is

begin
	mod_key <= '0';
	restore_key <= '0';
	tape_play <= '0';

	matrix: process(clk)
	begin
		if rising_edge(clk) then
			-- https://www.c64-wiki.com/wiki/Keyboard
			-- pao = column , pbi = row
			keyboard_matrix_out <= std_logic_vector(pai);

			-- reading B, scan pattern on A
			pbo(0) <= pbi(0) and joyA(0) and keyboard_matrix_in(0);
			pbo(1) <= pbi(1) and joyA(1) and keyboard_matrix_in(1);
			pbo(2) <= pbi(2) and joyA(2) and keyboard_matrix_in(2);
			pbo(3) <= pbi(3) and joyA(3) and keyboard_matrix_in(3);
			pbo(4) <= pbi(4) and joyA(4) and keyboard_matrix_in(4);
			pbo(5) <= pbi(5) and keyboard_matrix_in(5);
			pbo(6) <= pbi(6) and keyboard_matrix_in(6);
			pbo(7) <= pbi(7) and keyboard_matrix_in(7);

			-- reading A, scan pattern on B
			pao(0) <= pai(0) and joyB(0);
			pao(1) <= pai(1) and joyB(1);
			pao(2) <= pai(2) and joyB(2);
			pao(3) <= pai(3) and joyB(3);
			pao(4) <= pai(4) and joyB(4);
			pao(5) <= pai(5);
			pao(6) <= pai(6);
			pao(7) <= pai(7);
    	end if;
	end process;
end architecture;
