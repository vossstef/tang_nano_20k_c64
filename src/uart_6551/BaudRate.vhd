-- Baud Rate Generator

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use ieee.std_logic_unsigned.all;

ENTITY BaudRate IS
	GENERIC (
		BAUD_RATE	: integer := 230400
	);
	PORT (
      i_CLOCK     : IN std_logic;
      o_serialEn  : OUT std_logic
	);
END BaudRate;

ARCHITECTURE BaudRate_beh OF BaudRate IS

   signal w_serialCount   	: std_logic_vector(15 downto 0);
   signal w_serialCount_d	: std_logic_vector(15 downto 0);

BEGIN
	BAUD_230400: if (BAUD_RATE=230400) generate
		begin	
		baud_div: process (w_serialCount_d, w_serialCount)
			 begin
				  w_serialCount_d <= w_serialCount + 767;  -- 315Mhz 
			 end process;
	end generate BAUD_230400;

	BAUD_115200: if (BAUD_RATE=115200) generate
		begin	
		baud_div: process (w_serialCount_d, w_serialCount)
			 begin
				  w_serialCount_d <= w_serialCount + 1887; -- 64Mhz
			 end process;
	end generate BAUD_115200;
		 
	BAUD_38400: if (BAUD_RATE=38400) generate
		begin	
		baud_div: process (w_serialCount_d, w_serialCount)
			 begin
				  w_serialCount_d <= w_serialCount + 805;
			 end process;
	end generate BAUD_38400;

		 
	process (i_CLOCK)
		begin
			if rising_edge(i_CLOCK) then
			  w_serialCount <= w_serialCount_d;
			  if w_serialCount(15) = '0' and w_serialCount_d(15) = '1' then
					o_serialEn <= '1';
			  else
					o_serialEn <= '0';
			  end if;
			end if;
		end process;

END BaudRate_beh;
