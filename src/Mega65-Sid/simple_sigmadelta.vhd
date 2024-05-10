--
-- Sigma-delta output
--
-- Copyright 2008,2009,2010 Álvaro Lopes <alvieboy@alvie.com>
--
-- Version: 1.2
--
-- The FreeBSD license
-- 
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
-- 
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
-- 2. Redistributions in binary form must reproduce the above
--    copyright notice, this list of conditions and the following
--    disclaimer in the documentation and/or other materials
--    provided with the distribution.
-- 
-- THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY
-- EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
-- PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
-- ZPU PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
-- INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
-- OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
-- HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
-- STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--
-- Changelog:
--
-- 1.2: Adapted from ALZPU to ZPUino
-- 1.1: First version, imported from old controller.
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity simple_sigmadelta is
  generic (
    BITS: integer := 8
  );
	port (
    clk:      in std_logic;
    rst:      in std_logic;
    data_in:  in std_logic_vector(BITS-1 downto 0);
    data_out: out std_logic
    );
end entity simple_sigmadelta;

architecture behave of simple_sigmadelta is

signal delta_adder: unsigned(BITS+1 downto 0);
signal sigma_adder: unsigned(BITS+1 downto 0);
signal sigma_latch: unsigned(BITS+1 downto 0);
signal delta_b:     unsigned(BITS+1 downto 0);

signal dat_q: unsigned(BITS+1 downto 0);

begin

dat_q(BITS+1) <= '0';
dat_q(BITS) <= '0';

process(clk)
begin
  if rising_edge(clk) then
    dat_q(BITS-1 downto 0) <= unsigned(data_in);
  end if;
end process;

process(sigma_latch)
begin
  delta_b(BITS+1) <= sigma_latch(BITS+1);
  delta_b(BITS) <= sigma_latch(BITS+1);
  delta_b(BITS-1 downto 0) <= (others => '0');
end process;

process(dat_q, delta_b)
begin
	delta_adder <= dat_q + delta_b;
end process;

process(delta_adder,sigma_latch)
begin
	sigma_adder <= delta_adder + sigma_latch;
end process;

process(clk)
begin
  if rising_edge(clk) then
	  if rst='1' then
      sigma_latch <= (others => '0');
		  sigma_latch(BITS+1) <= '1';
		  data_out <= '0';
	  else
		  sigma_latch <= sigma_adder;
		  data_out <= sigma_latch(BITS+1);
  	end if;
  end if;
end process;

end behave;

