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
library work;
use work.keyboard_matrix_pkg.all;

entity fpga64_keyboard is
	port (
		clk     : in std_logic;
		reset   : in std_logic;
		
		ps2_key : in std_logic_vector(10 downto 0);
		keyboard : in keyboard_t;

		joyA    : in unsigned(6 downto 0);
		joyB    : in unsigned(6 downto 0);
		
		shift_mod: in std_logic_vector(1 downto 0);

		pai     : in unsigned(7 downto 0);
		pbi     : in unsigned(7 downto 0);
		pao     : out unsigned(7 downto 0);
		pbo     : out unsigned(7 downto 0);
		
		restore_key : out std_logic;
		mod_key     : out std_logic;
		reset_key : out std_logic;
		disk_num : out std_logic_vector(7 downto 0);
		tape_play   : out std_logic;
		
		-- Config
		-- backwardsReadingEnabled = 1 allows reversal of PIA registers to still work.
		-- not needed for kernel/normal operation only for some specific programs.
		-- set to 0 to save some hardware.
		backwardsReadingEnabled : in std_logic
	);
end fpga64_keyboard;

architecture rtl of fpga64_keyboard is	
	signal extended: boolean;
	signal pressed: std_logic := '0';

	signal key_del: std_logic := '0';
	signal key_return: std_logic := '0';
	signal key_left: std_logic := '0';
	signal key_right: std_logic := '0';
	signal key_F1: std_logic := '0';
	signal key_F2: std_logic := '0';
	signal key_F3: std_logic := '0';
	signal key_F4: std_logic := '0';
	signal key_F5: std_logic := '0';
	signal key_F6: std_logic := '0';
	signal key_F7: std_logic := '0';
	signal key_F8: std_logic := '0';
	signal key_up: std_logic := '0';
	signal key_down: std_logic := '0';

	signal key_3: std_logic := '0';
	signal key_W: std_logic := '0';
	signal key_A: std_logic := '0';
	signal key_4: std_logic := '0';
	signal key_Z: std_logic := '0';
	signal key_S: std_logic := '0';
	signal key_E: std_logic := '0';
	signal key_shiftl: std_logic := '0';

	signal key_5: std_logic := '0';
	signal key_R: std_logic := '0';
	signal key_D: std_logic := '0';
	signal key_6: std_logic := '0';
	signal key_C: std_logic := '0';
	signal key_F: std_logic := '0';
	signal key_T: std_logic := '0';
	signal key_X: std_logic := '0';
	
	signal key_7: std_logic := '0';
	signal key_Y: std_logic := '0';
	signal key_G: std_logic := '0';
	signal key_8: std_logic := '0';
	signal key_B: std_logic := '0';
	signal key_H: std_logic := '0';
	signal key_U: std_logic := '0';
	signal key_V: std_logic := '0';

	signal key_9: std_logic := '0';
	signal key_I: std_logic := '0';
	signal key_J: std_logic := '0';
	signal key_0: std_logic := '0';
	signal key_M: std_logic := '0';
	signal key_K: std_logic := '0';
	signal key_O: std_logic := '0';
	signal key_N: std_logic := '0';

	signal key_plus: std_logic := '0';
	signal key_P: std_logic := '0';
	signal key_L: std_logic := '0';
	signal key_minus: std_logic := '0';
	signal key_dot: std_logic := '0';
	signal key_colon: std_logic := '0';
	signal key_at: std_logic := '0';
	signal key_comma: std_logic := '0';

	signal key_pound: std_logic := '0';
	signal key_star: std_logic := '0';
	signal key_semicolon: std_logic := '0';
	signal key_home: std_logic := '0';
	signal key_shiftr: std_logic := '0';
	signal key_equal: std_logic := '0';
	signal key_arrowup: std_logic := '0';
	signal key_slash: std_logic := '0';

	signal key_1: std_logic := '0';
	signal key_arrowleft: std_logic := '0';
	signal key_ctrl: std_logic := '0';
	signal key_2: std_logic := '0';
	signal key_space: std_logic := '0';
	signal key_commodore: std_logic := '0';
	signal key_Q: std_logic := '0';
	signal key_runstop: std_logic := '0';

	signal mod_key1: std_logic := '0';
	signal mod_key2: std_logic := '0';

	signal key_shift: std_logic := '0';
	signal key_inst: std_logic := '0';
	signal key_caps: std_logic := '0';
	
	signal delay_cnt : integer range 0 to 300000;
	signal delay_end : std_logic;
	signal ps2_stb   : std_logic;
	signal key_8s    : std_logic := '0';

	-- for joystick emulation on PS2
	signal joySelKey : std_logic;
	signal joyKeys : std_logic_vector(joyA'range) := (others => '0');	-- active high
	signal joyA_s : unsigned(joyA'range); -- active low
	signal joyB_s : unsigned(joyB'range); -- active low
	signal joySel : std_logic := '0';
	signal joySelKey_d : std_logic;

	-- for disk image selection
	signal diskChgKey : std_logic := '0';
	signal diskChgKeyDn : std_logic := '0';
	signal disk_nb : std_logic_vector(7 downto 0) := (others => '0');
	signal diskChgKey_d, diskChgKeyDn_d : std_logic;

begin

	delay_end <= '1' when delay_cnt = 0 else '0';

	pressed <= ps2_key(9);
	extended<= ps2_key(8) = '1';

	mod_key <= mod_key1 or mod_key2;
	key_shift <= key_shiftl or key_shiftr;

	process (clk)
	begin
		if rising_edge(clk) then
			if diskChgKey = '1' and diskChgKey_d ='0' then  -- rising edge
				  disk_nb <= disk_nb + 1;
			end if;
			if diskChgKeyDn = '1' and diskChgKeyDn_d = '0' then -- rising edge
				  disk_nb <= disk_nb - 1;
			end if;
			diskChgKeyDn_d <= diskChgKeyDn;
			diskChgKey_d <= diskChgKey;
		end if;
	end process;

	disk_num <= disk_nb;
	--
	-- cycle through joystick emulation options on <CTRL F1>	
	--
	-- '0' - PORTA = JOYA or JOYKEYS, PORTB = JOYB
	-- '1' - PORTA = JOYA,            PORTB = JOYB or JOYKEYS
	
	process (clk)
	begin
		if rising_edge(clk) then
			if joySelKey = '1' and joySelKey_d ='0' then --risige edge of Keypress
				joySel <= not joySel;
			end if;
			joySelKey_d <= joySelKey;			
		end if;
	end process;

	joyA_s <= joyA and not unsigned(joyKeys) when joySel = '0' else joyA;
	joyB_s <= joyB and not unsigned(joyKeys) when joySel = '1' else joyB ;
	
	matrix: process(clk)
	begin
		if rising_edge(clk) then
		
			ps2_stb <= ps2_key(10);

			if delay_cnt /= 0 then
				delay_cnt <= delay_cnt - 1;
			end if;

			-- reading A, scan pattern on B
			pao(0) <= pai(0) and joyB_s(0) and
				((not backwardsReadingEnabled) or
				((pbi(0) or not (key_del or key_inst)) and
				(pbi(1) or not key_return) and
				(pbi(2) or not (key_left or key_right)) and
				(pbi(3) or not (key_F7 or key_F8)) and
				(pbi(4) or not (key_F1 or key_F2)) and
				(pbi(5) or not (key_F3 or key_F4)) and
				(pbi(6) or not (key_F5 or key_F6)) and
				(pbi(7) or not (key_up or key_down))));
			pao(1) <= pai(1) and joyB_s(1) and
				((not backwardsReadingEnabled) or
				((pbi(0) or not key_3) and
				(pbi(1) or not key_W) and
				(pbi(2) or not key_A) and
				(pbi(3) or not key_4) and
				(pbi(4) or not key_Z) and
				(pbi(5) or not key_S) and
				(pbi(6) or not key_E) and
				(pbi(7) or not (((key_left or key_up or key_caps or key_inst or key_F2 or key_F4 or key_F6 or key_F8) and shift_mod(1)) or (key_shiftl and not key_8s)))));
			pao(2) <= pai(2) and joyB_s(2) and
				((not backwardsReadingEnabled) or
				((pbi(0) or not key_5) and
				(pbi(1) or not key_R) and
				(pbi(2) or not key_D) and
				(pbi(3) or not key_6) and
				(pbi(4) or not key_C) and
				(pbi(5) or not key_F) and
				(pbi(6) or not key_T) and
				(pbi(7) or not key_X)));
			pao(3) <= pai(3) and joyB_s(3) and
				((not backwardsReadingEnabled) or
				((pbi(0) or not key_7) and
				(pbi(1) or not key_Y) and
				(pbi(2) or not key_G) and
				(pbi(3) or not key_8) and
				(pbi(4) or not key_B) and
				(pbi(5) or not key_H) and
				(pbi(6) or not key_U) and
				(pbi(7) or not key_V)));
			pao(4) <= pai(4) and joyB_s(4) and
				((not backwardsReadingEnabled) or
				((pbi(0) or not key_9) and
				(pbi(1) or not key_I) and
				(pbi(2) or not key_J) and
				(pbi(3) or not key_0) and
				(pbi(4) or not key_M) and
				(pbi(5) or not key_K) and
				(pbi(6) or not key_O) and
				(pbi(7) or not key_N)));
			pao(5) <= pai(5) and
				((not backwardsReadingEnabled) or
				((pbi(0) or not key_plus) and
				(pbi(1) or not key_P) and
				(pbi(2) or not key_L) and
				(pbi(3) or not key_minus) and
				(pbi(4) or not key_dot) and
				(pbi(5) or not key_colon) and
				(pbi(6) or not key_at) and
				(pbi(7) or not key_comma)));
			pao(6) <= pai(6) and
				((not backwardsReadingEnabled) or
				((pbi(0) or not key_pound) and
				(pbi(1) or not (key_star or (key_8s and delay_end))) and
				(pbi(2) or not key_semicolon) and
				(pbi(3) or not key_home) and
				(pbi(4) or not (((key_left or key_up or key_caps or key_inst or key_F2 or key_F4 or key_F6 or key_F8) and shift_mod(0)) or (key_shiftr and not key_8s))) and
				(pbi(5) or not key_equal) and
				(pbi(6) or not key_arrowup) and
				(pbi(7) or not key_slash)));
			pao(7) <= pai(7) and
				((not backwardsReadingEnabled) or
				((pbi(0) or not key_1) and
				(pbi(1) or not key_arrowleft) and
				(pbi(2) or not (key_ctrl or not joyA_s(6) or not joyB_s(6))) and
				(pbi(3) or not key_2) and
				(pbi(4) or not (key_space or not joyA_s(5) or not joyB_s(5))) and
				(pbi(5) or not (key_commodore or key_caps)) and
				(pbi(6) or not key_Q) and
				(pbi(7) or not key_runstop)));

			-- reading B, scan pattern on A
			pbo(0) <= pbi(0) and joyA_s(0) and 
				(pai(0) or not (key_del or key_inst)) and
				(pai(1) or not key_3) and
				(pai(2) or not key_5) and
				(pai(3) or not key_7) and
				(pai(4) or not key_9) and
				(pai(5) or not key_plus) and
				(pai(6) or not key_pound) and
				(pai(7) or not key_1);
			pbo(1) <= pbi(1) and joyA_s(1) and
				(pai(0) or not key_return) and
				(pai(1) or not key_W) and
				(pai(2) or not key_R) and
				(pai(3) or not key_Y) and
				(pai(4) or not key_I) and
				(pai(5) or not key_P) and
				(pai(6) or not (key_star or (key_8s and delay_end))) and
				(pai(7) or not key_arrowleft);
			pbo(2) <= pbi(2) and joyA_s(2) and
				(pai(0) or not (key_left or key_right)) and
				(pai(1) or not key_A) and
				(pai(2) or not key_D) and
				(pai(3) or not key_G) and
				(pai(4) or not key_J) and
				(pai(5) or not key_L) and
				(pai(6) or not key_semicolon) and
				(pai(7) or not (key_ctrl or not joyA_s(6) or not joyB_s(6)));
			pbo(3) <= pbi(3) and joyA_s(3) and
				(pai(0) or not (key_F7 or key_F8)) and
				(pai(1) or not key_4) and
				(pai(2) or not key_6) and
				(pai(3) or not key_8) and
				(pai(4) or not key_0) and
				(pai(5) or not key_minus) and
				(pai(6) or not key_home) and
				(pai(7) or not key_2);
			pbo(4) <= pbi(4) and joyA_s(4) and
				(pai(0) or not (key_F1 or key_F2)) and
				(pai(1) or not key_Z) and
				(pai(2) or not key_C) and
				(pai(3) or not key_B) and
				(pai(4) or not key_M) and
				(pai(5) or not key_dot) and
				(pai(6) or not (((key_left or key_up or key_caps or key_inst or key_F2 or key_F4 or key_F6 or key_F8) and shift_mod(0)) or (key_shiftr and not key_8s))) and
				(pai(7) or not (key_space or not joyA_s(5) or not joyB_s(5)));
			pbo(5) <= pbi(5) and
				(pai(0) or not (key_F3 or key_F4)) and
				(pai(1) or not key_S) and
				(pai(2) or not key_F) and
				(pai(3) or not key_H) and
				(pai(4) or not key_K) and
				(pai(5) or not key_colon) and
				(pai(6) or not key_equal) and
				(pai(7) or not (key_commodore or key_caps));
			pbo(6) <= pbi(6) and
				(pai(0) or not (key_F5 or key_F6)) and
				(pai(1) or not key_E) and
				(pai(2) or not key_T) and
				(pai(3) or not key_U) and
				(pai(4) or not key_O) and
				(pai(5) or not key_at) and
				(pai(6) or not key_arrowup) and
				(pai(7) or not key_Q);
			pbo(7) <= pbi(7) and
				(pai(0) or not (key_up or key_down)) and
				(pai(1) or not (((key_left or key_up or key_caps or key_inst or key_F2 or key_F4 or key_F6 or key_F8) and shift_mod(1)) or (key_shiftl and not key_8s))) and
				(pai(2) or not key_X) and
				(pai(3) or not key_V) and
				(pai(4) or not key_N) and
				(pai(5) or not key_comma) and
				(pai(6) or not key_slash) and
				(pai(7) or not key_runstop);

--			if ps2_key(10) /= ps2_stb then
--				case ps2_key(7 downto 0) is
--
			key_F1        <= not keyboard(1,0);
			key_F2        <= not keyboard(2,0);
			key_F3        <= not keyboard(3,0);
			key_F4        <= not keyboard(4,0);
			key_F5        <= not keyboard(5,0);
			key_F6        <= not keyboard(6,0);
			key_F7        <= not keyboard(7,0);
			key_F8        <= not keyboard(8,0);
			key_shiftr    <= not keyboard(3,7);
			key_shiftl    <= not keyboard(1,5);
			key_ctrl      <= not keyboard(0,4);
			key_1         <= not keyboard(4,2);
			key_2         <= not keyboard(5,1); 
			key_3         <= not keyboard(5,2);
			key_4         <= not keyboard(6,1);
			key_5         <= not keyboard(6,2);
			key_6         <= not keyboard(7,1);
			key_7         <= not keyboard(7,2);
			key_8         <= not keyboard(8,1);
			key_9         <= not keyboard(8,2);
			key_0         <= not keyboard(9,1);
			key_Q         <= not keyboard(4,4);
			key_Z         <= not keyboard(4,7);
			key_S         <= not keyboard(5,5);
			key_A         <= not keyboard(4,5);
			key_W         <= not keyboard(5,3);
			key_C         <= not keyboard(6,6);
			key_X         <= not keyboard(5,7);
			key_D         <= not keyboard(5,6);
			key_E         <= not keyboard(5,4);
			key_V         <= not keyboard(6,7);
			key_F         <= not keyboard(6,5);
			key_T         <= not keyboard(6,4);
			key_R         <= not keyboard(6,3);
			key_N         <= not keyboard(7,7);
			key_B         <= not keyboard(7,6);
			key_H         <= not keyboard(7,5);
			key_G         <= not keyboard(7,4);
			key_Y         <= not keyboard(7,3);
			key_M         <= not keyboard(8,7);
			key_J         <= not keyboard(8,5);
			key_U         <= not keyboard(8,3);
			key_K         <= not keyboard(8,6);
			key_I         <= not keyboard(8,4);
			key_O         <= not keyboard(9,3);
			key_L         <= not keyboard(9,5);
			key_P         <= not keyboard(9,4);
			key_ctrl      <= not keyboard(0,4);
			key_commodore <= not keyboard(2,6); -- alt
			key_space     <= not keyboard(9,7);
			key_comma     <= not keyboard(9,6); -- ,
			key_dot       <= not keyboard(10,6); -- .
			key_slash     <= not keyboard(11,7); -- /
			key_minus     <= not keyboard(9,2);  -- -
			key_at        <= not keyboard(10,3); -- [
			key_star      <= not keyboard(10,4); -- ]
			key_Return    <= not keyboard(11,5);
			key_arrowleft <= not keyboard(10,2); -- `
			key_del       <= not keyboard(11,2); -- Delete
			key_inst      <= not keyboard(11,3); -- Insert
			key_home      <= not keyboard(12,2);  -- Home
			key_runstop   <= not keyboard(4,1);
			key_colon     <= not keyboard(10,5);
			key_semicolon <= not keyboard(11,6); -- \ 
			key_pound     <= not keyboard(4,6); -- EUR-2 resp | 
			key_arrowup   <= not keyboard(9,0); -- F9
			key_plus      <= not keyboard(10,1); -- equal as c64 plus
			key_equal     <= not keyboard(11,4); -- \ 
			key_down      <= not keyboard(12,4);
			key_right     <= not keyboard(12,5);
			key_left      <= not keyboard(12,3);
			key_up        <= not keyboard(12,1);
			restore_key   <= not keyboard(12,0); -- PageDown -> UNDO
			tape_play     <= not keyboard(11,0); -- PageUp -> HELP
			key_caps      <= not keyboard(10,7);
			
			diskChgKey    <= not keyboard(14,5); -- KP +
			diskChgKeyDn  <= not keyboard(14,3); -- KP -
			reset_key     <= not keyboard(14,7); -- KP Enter

			joySelKey     <= not keyboard(14,1); -- KP *
			joyKeys(2)    <= not keyboard(13,4); -- PAD_4 left
			joyKeys(4)    <= not keyboard(12,7); -- PAD 0 fire
			joyKeys(1)    <= not keyboard(13,6); -- PAD 2 down
			joyKeys(3)    <= not keyboard(14,4); -- PAD 6 right
			joyKeys(0)    <= not keyboard(13,3); -- PAD 8 up
			joyKeys(5)    <= '0';
            joyKeys(6)    <= '0';

-- mod_key1   
-- mod_key2
-- not keyboard(12,0); -- PageDown -> UNDO
--not keyboard(13,7); -- KP .
--not keyboard(14,0); -- KP /
--not keyboard(13,0); -- PrtScr -> KP-(
--not keyboard(13,1); -- End -> KP-)


			if reset = '1' then
					key_F1        <= '0';
					key_F2        <= '0';
					key_F3        <= '0';
					key_F4        <= '0';
					key_F5        <= '0';
					key_F6        <= '0';
					key_F7        <= '0';
					key_F8        <= '0';
					key_shiftr    <= '0';
					key_shiftl    <= '0';
					key_ctrl      <= '0'; 
					mod_key1      <= '0'; 
					mod_key2      <= '0'; 
					key_commodore <= '0'; 
					key_runstop   <= '0';
					restore_key   <= '0';
					tape_play     <= '0';
					key_arrowup   <= '0';
					key_equal     <= '0';
					key_arrowleft <= '0';
					key_space     <= '0'; 
					key_comma     <= '0';
					key_dot       <= '0'; 
					key_slash     <= '0'; 
					key_colon     <= '0'; 
					key_minus     <= '0';
					key_semicolon <= '0'; 
					key_at        <= '0'; 
					key_plus      <= '0';
					key_caps      <= '0';
					key_Return    <= '0'; 
					key_star      <= '0'; 
					key_pound     <= '0';
					key_del       <= '0'; 
					key_left      <= '0';
					key_home      <= '0';
					key_inst      <= '0';
					key_down      <= '0';
					key_right     <= '0';
					key_up        <= '0';
					key_1         <= '0'; 
					key_2         <= '0'; 
					key_3         <= '0'; 
					key_4         <= '0'; 
					key_5         <= '0'; 
					key_6         <= '0';
					key_7         <= '0';
					key_8         <= '0';
					key_8s        <= '0';
					key_9         <= '0';
					key_0         <= '0';
					key_Q         <= '0'; 
					key_Z         <= '0'; 
					key_S         <= '0'; 
					key_A         <= '0'; 
					key_W         <= '0'; 
					key_C         <= '0'; 
					key_X         <= '0'; 
					key_D         <= '0'; 
					key_E         <= '0'; 
					key_V         <= '0'; 
					key_F         <= '0'; 
					key_T         <= '0'; 
					key_R         <= '0'; 
					key_N         <= '0'; 
					key_B         <= '0'; 
					key_H         <= '0'; 
					key_G         <= '0'; 
					key_Y         <= '0'; 
					key_M         <= '0';
					key_J         <= '0';
					key_U         <= '0';
					key_K         <= '0';
					key_I         <= '0';
					key_O         <= '0';
					key_L         <= '0'; 
					key_P         <= '0'; 
			end if;
		end if;
	end process;
end architecture;
