---------------------------------------------------------------------------------
-- c64_midi.vhd - 6850 ACIA based MIDI interface
-- 2022 - Slingshot
--
-- https://codebase64.org/doku.php?id=base:c64_midi_interfaces
-- Mode 1 : SEQUENTIAL CIRCUITS INC.
-- Mode 2 : PASSPORT & SENTECH
-- Mode 3 : DATEL/SIEL/JMS/C-LAB
-- Mode 4 : NAMESOFT
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity c64_midi is
port(
	clk32   : in  std_logic;
	reset   : in  std_logic;
	Mode    : in  std_logic_vector( 2 downto 0);
	E       : in  std_logic;
	IOE     : in  std_logic;
	A       : in  std_logic_vector(15 downto 0);
	Din     : in  std_logic_vector( 7 downto 0);
	Dout    : out std_logic_vector( 7 downto 0);
	OE      : out std_logic;
	RnW     : in  std_logic;
	nIRQ    : out std_logic;
	nNMI    : out std_logic;

	RX      : in  std_logic;
	TX      : out std_logic
);
end c64_midi;

architecture rtl of c64_midi is

component acia is
port
(
	clk   : in  std_logic;
	E     : in  std_logic;
	reset : in  std_logic := '0';
	rxtxclk_sel : in  std_logic := '0';
	din   : in  std_logic_vector(7 downto 0);
	sel   : in  std_logic;
	rs    : in  std_logic;
	rw    : in  std_logic;
	dout  : out std_logic_vector(7 downto 0);
	irq   : out std_logic;
	tx    : out std_logic;
	rx    : in  std_logic
);
end component;

signal acia_E   : std_logic;
signal acia_sel : std_logic;
signal acia_rs  : std_logic;
signal acia_rw  : std_logic;
signal acia_irq : std_logic;
signal acia_rxtxclk_sel : std_logic;

begin

	process(clk32) begin
		if rising_edge(clk32) then
			acia_E <= E;
		end if;
	end process;

	process(Mode, IOE, A, RnW, acia_irq) begin
		acia_rxtxclk_sel <= '0';
		acia_sel <= '0';
		acia_rw <= '1';
		acia_rs <= '0';
		nIRQ <= '1';
		nNMI <= '1';
		case Mode is
			when "001" =>
				-- Mode 1 : SEQUENTIAL CIRCUITS INC.
				nIRQ <= not acia_irq;
				acia_sel <= IOE and not A(4) and not A(5) and not A(6);
				acia_rs <= A(0);
				acia_rw <= A(1);
			when "010" =>
				-- Mode 2 : PASSPORT & SENTECH
				nIRQ <= not acia_irq;
				acia_sel <= IOE and A(3) and not A(4) and not A(5) and not A(6);
				acia_rs <= A(0);
				acia_rw <= RnW;
			when "011" =>
				-- Mode 3 : DATEL/SIEL/JMS/C-LAB
				acia_rxtxclk_sel <= '1'; -- for 2 MHz RX/TX clock
				nIRQ <= not acia_irq;
				acia_sel <= IOE and A(2) and not A(4) and not A(5) and not A(6);
				acia_rs <= A(0);
				acia_rw <= A(1);
			when "100" =>
				-- Mode 4 : NAMESOFT
				nNMI <= not acia_irq;
				acia_sel <= IOE and not A(4) and not A(5) and not A(6);
				acia_rs <= A(0);
				acia_rw <= A(1);
			when others => null;
		end case;
	end process;

	OE <= acia_sel and acia_rw;

	acia_inst : acia
	port map (
		clk   => clk32,
		reset => reset,
		rxtxclk_sel => acia_rxtxclk_sel,
		E     => acia_E,
		din   => Din,
		sel   => acia_sel,
		rs    => acia_rs,
		rw    => acia_rw,
		dout  => Dout,
		irq   => acia_irq,
		tx    => TX,
		rx    => RX
	);

end rtl;
