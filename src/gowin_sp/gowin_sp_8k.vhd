--Copyright (C)2014-2023 Gowin Semiconductor Corporation.
--All rights reserved.
--File Title: IP file
--GOWIN Version: V1.9.9 Beta-4 Education
--Part Number: GW2AR-LV18QN88C8/I7
--Device: GW2AR-18
--Device Version: C
--Created Time: Sun Dec 31 18:23:40 2023

library IEEE;
use IEEE.std_logic_1164.all;

entity Gowin_SP_8k is
    port (
        dout: out std_logic_vector(7 downto 0);
        clk: in std_logic;
        oce: in std_logic;
        ce: in std_logic;
        reset: in std_logic;
        wre: in std_logic;
        ad: in std_logic_vector(12 downto 0);
        din: in std_logic_vector(7 downto 0)
    );
end Gowin_SP_8k;

architecture Behavioral of Gowin_SP_8k is

    signal sp_inst_0_dout_w: std_logic_vector(29 downto 0);
    signal sp_inst_1_dout_w: std_logic_vector(29 downto 0);
    signal sp_inst_2_dout_w: std_logic_vector(29 downto 0);
    signal sp_inst_3_dout_w: std_logic_vector(29 downto 0);
    signal gw_gnd: std_logic;
    signal sp_inst_0_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_0_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_0_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_0_DO_o: std_logic_vector(31 downto 0);
    signal sp_inst_1_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_1_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_1_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_1_DO_o: std_logic_vector(31 downto 0);
    signal sp_inst_2_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_2_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_2_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_2_DO_o: std_logic_vector(31 downto 0);
    signal sp_inst_3_BLKSEL_i: std_logic_vector(2 downto 0);
    signal sp_inst_3_AD_i: std_logic_vector(13 downto 0);
    signal sp_inst_3_DI_i: std_logic_vector(31 downto 0);
    signal sp_inst_3_DO_o: std_logic_vector(31 downto 0);

    --component declaration
    component SP
        generic (
            READ_MODE: in bit := '0';
            WRITE_MODE: in bit_vector := "00";
            BIT_WIDTH: in integer := 32;
            BLK_SEL: in bit_vector := "000";
            RESET_MODE: in string := "SYNC";
            INIT_RAM_00: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_01: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_02: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_03: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_04: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_05: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_06: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_07: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_08: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_09: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0A: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0B: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0C: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0D: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0E: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_0F: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_10: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_11: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_12: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_13: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_14: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_15: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_16: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_17: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_18: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_19: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1A: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1B: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1C: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1D: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1E: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_1F: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_20: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_21: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_22: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_23: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_24: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_25: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_26: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_27: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_28: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_29: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2A: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2B: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2C: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2D: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2E: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_2F: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_30: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_31: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_32: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_33: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_34: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_35: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_36: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_37: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_38: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_39: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3A: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3B: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3C: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3D: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3E: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000";
            INIT_RAM_3F: in bit_vector := X"0000000000000000000000000000000000000000000000000000000000000000"
        );
        port (
            DO: out std_logic_vector(31 downto 0);
            CLK: in std_logic;
            OCE: in std_logic;
            CE: in std_logic;
            RESET: in std_logic;
            WRE: in std_logic;
            BLKSEL: in std_logic_vector(2 downto 0);
            AD: in std_logic_vector(13 downto 0);
            DI: in std_logic_vector(31 downto 0)
        );
    end component;

begin
    gw_gnd <= '0';

    sp_inst_0_BLKSEL_i <= gw_gnd & gw_gnd & gw_gnd;
    sp_inst_0_AD_i <= ad(12 downto 0) & gw_gnd;
    sp_inst_0_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(1 downto 0);
    dout(1 downto 0) <= sp_inst_0_DO_o(1 downto 0) ;
    sp_inst_0_dout_w(29 downto 0) <= sp_inst_0_DO_o(31 downto 2) ;
    sp_inst_1_BLKSEL_i <= gw_gnd & gw_gnd & gw_gnd;
    sp_inst_1_AD_i <= ad(12 downto 0) & gw_gnd;
    sp_inst_1_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(3 downto 2);
    dout(3 downto 2) <= sp_inst_1_DO_o(1 downto 0) ;
    sp_inst_1_dout_w(29 downto 0) <= sp_inst_1_DO_o(31 downto 2) ;
    sp_inst_2_BLKSEL_i <= gw_gnd & gw_gnd & gw_gnd;
    sp_inst_2_AD_i <= ad(12 downto 0) & gw_gnd;
    sp_inst_2_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(5 downto 4);
    dout(5 downto 4) <= sp_inst_2_DO_o(1 downto 0) ;
    sp_inst_2_dout_w(29 downto 0) <= sp_inst_2_DO_o(31 downto 2) ;
    sp_inst_3_BLKSEL_i <= gw_gnd & gw_gnd & gw_gnd;
    sp_inst_3_AD_i <= ad(12 downto 0) & gw_gnd;
    sp_inst_3_DI_i <= gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & gw_gnd & din(7 downto 6);
    dout(7 downto 6) <= sp_inst_3_DO_o(1 downto 0) ;
    sp_inst_3_dout_w(29 downto 0) <= sp_inst_3_DO_o(31 downto 2) ;

    sp_inst_0: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 2,
            RESET_MODE => "SYNC",
            BLK_SEL => "000"
        )
        port map (
            DO => sp_inst_0_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_0_BLKSEL_i,
            AD => sp_inst_0_AD_i,
            DI => sp_inst_0_DI_i
        );

    sp_inst_1: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 2,
            RESET_MODE => "SYNC",
            BLK_SEL => "000"
        )
        port map (
            DO => sp_inst_1_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_1_BLKSEL_i,
            AD => sp_inst_1_AD_i,
            DI => sp_inst_1_DI_i
        );

    sp_inst_2: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 2,
            RESET_MODE => "SYNC",
            BLK_SEL => "000"
        )
        port map (
            DO => sp_inst_2_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_2_BLKSEL_i,
            AD => sp_inst_2_AD_i,
            DI => sp_inst_2_DI_i
        );

    sp_inst_3: SP
        generic map (
            READ_MODE => '0',
            WRITE_MODE => "00",
            BIT_WIDTH => 2,
            RESET_MODE => "SYNC",
            BLK_SEL => "000"
        )
        port map (
            DO => sp_inst_3_DO_o,
            CLK => clk,
            OCE => oce,
            CE => ce,
            RESET => reset,
            WRE => wre,
            BLKSEL => sp_inst_3_BLKSEL_i,
            AD => sp_inst_3_AD_i,
            DI => sp_inst_3_DI_i
        );

end Behavioral; --Gowin_SP_8k
