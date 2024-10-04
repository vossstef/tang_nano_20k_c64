////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 4.0
// File Name:		uart_6551.v
//
// CoCo3 in an FPGA
//
// Revision: 4.0 07/10/16
////////////////////////////////////////////////////////////////////////////////
//
// CPU section copyrighted by John Kent
// The FDC co-processor copyrighted Daniel Wallner.
// SDRAM Controller copyrighted by XESS Corp.
//
////////////////////////////////////////////////////////////////////////////////
//
// Color Computer 3 compatible system on a chip
//
// Version : 4.0
//
// Copyright (c) 2008 Gary Becker (gary_l_becker@yahoo.com)
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in synthesized form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// Neither the name of the author nor the names of other contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Please report bugs to the author, but before you do so, please
// make sure that this is not a derivative work and that
// you have the latest version of this file.
//
// The latest version of this file can be found at:
//      http://groups.yahoo.com/group/CoCo3FPGA
//
// File history :
//
//  1.0			Full Release
//  2.0			Partial Release
//  3.0			Full Release
//  3.0.0.1		Update to fix DoD interrupt issue
//	3.0.1.0		Update to fix 32/40 CoCO3 Text issue and add 2 Meg max memory
//	4.0.X.X		Full Release
////////////////////////////////////////////////////////////////////////////////
// Gary Becker
// gary_L_becker@yahoo.com
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
// MISTer Conversion by Stan Hodge and Alan Steremberg (& Gary Becker)
// stan.pda@gmail.com
// 
//	1/11/22		Changed to be super synchronus
////////////////////////////////////////////////////////////////////////////////

module glb6551(
RESET_N,
CLK,
RX_CLK,
RX_CLK_IN,
XTAL_CLK_IN,
PH_2,
DI,
DO,
IRQ,
CS,
RW_N,
RS,
TXDATA_OUT,
RXDATA_IN,
RTS,
CTS,
DCD,
DTR,
DSR
);

input					RESET_N;
input					CLK;
output				RX_CLK;
input					RX_CLK_IN;
input					XTAL_CLK_IN;
input					PH_2;
input		[7:0]		DI;
output	[7:0]		DO;
output				IRQ;
input		[1:0]		CS;
input		[1:0]		RS;
input					RW_N;
output				TXDATA_OUT;
input					RXDATA_IN;
output				RTS;
input					CTS;
input					DCD;
output				DTR;
input					DSR;

reg		[7:0]		TX_BUFFER;
reg		[7:0]		TX_REG;
wire		[7:0]		RX_BUFFER;
reg		[7:0]		RX_REG;
wire		[7:0]		STATUS_REG;
reg		[7:0]		CTL_REG;
reg		[7:0]		CMD_REG;
reg					OVERRUN;
reg					FRAME;
reg					PARITY;

wire					TX_DONE;
reg					TX_DONE0;
reg					TX_DONE1;
reg					TX_START;
reg					TDRE;
reg					RDRF;
reg		[10:0]	TX_CLK_DIV;
wire					TX_CLK;
wire					RX_CLK;
wire					FRAME_BUF;
wire		[1:0]		WORD_SELECT;
wire					RESET_X;
wire					STOP;
wire					PARITY_ERR;
wire					PAR_DIS;
reg		[7:0]		LOOPBACK;
wire					RX_DATA;
wire					TX_DATA;
reg					RESET_NX;
reg					TX_CLK_REG_T;
reg			 		TX_CLK_REG;
reg		[1:0]		READ_STATE;
wire					GOT_DATA;
reg					READY0;
reg					READY1;
/*
Baud rate divisors
(for toggle of baud clock bit)
1	50		1152
2	75		768
3	110	524 	-0.069396
4	135	428 	-0.311526
5	150	384
6	300	192
7	600	96
8	1200	48
9	1800	32
A	2400	24
B	3600	16
C	4800	12
D	7200	8
E	9600	6
F	19200	3
*/

//assign TX_CLK_REG = TX_CLK_REG_T & XTAL_CLK_IN;

always @ (negedge CLK or negedge RESET_X)
begin
	if(!RESET_X)
	begin
		TX_CLK_DIV <= 11'h000;
		TX_CLK_REG_T <= 1'b0;
		TX_CLK_REG <= 1'b0;
	end
	else
	begin
		TX_CLK_REG <= 1'b0;
		if (XTAL_CLK_IN)
		begin
			case (TX_CLK_DIV)
			11'h000:
			begin
				TX_CLK_DIV <= 11'h001;
				TX_CLK_REG_T <= ~TX_CLK_REG_T;
				if (TX_CLK_REG_T)
					TX_CLK_REG <= 1'b1;
			end
			11'h002:
			begin
				if(CTL_REG[3:0] == 4'hF)
					TX_CLK_DIV <= 11'h000;
				else
					TX_CLK_DIV <= 11'h003;
			end
			11'h005:
			begin
				if(CTL_REG[3:0] == 4'hE)
					TX_CLK_DIV <= 11'h000;
				else
					TX_CLK_DIV <= 11'h006;
			end
			11'h007:
			begin
				if(CTL_REG[3:0] == 4'hD)
					TX_CLK_DIV <= 11'h000;
				else
					TX_CLK_DIV <= 11'h008;
			end
			11'h00B:
			begin
				if(CTL_REG[3:0] == 4'hC)
					TX_CLK_DIV <= 11'h000;
				else
					TX_CLK_DIV <= 11'h00C;
			end
			11'h00F:
			begin
				if(CTL_REG[3:0] == 4'hB)
					TX_CLK_DIV <= 11'h000;
				else
					TX_CLK_DIV <= 11'h010;
			end
			11'h017:
			begin
				if(CTL_REG[3:0] == 4'hA)
					TX_CLK_DIV <= 11'h000;
				else
					TX_CLK_DIV <= 11'h018;
			end
			11'h01F:
			begin
				if(CTL_REG[3:0] == 4'h9)
					TX_CLK_DIV <= 11'h000;
				else
					TX_CLK_DIV <= 11'h020;
			end
			11'h02F:
			begin
				if(CTL_REG[3:0] == 4'h8)
					TX_CLK_DIV <= 11'h000;
				else
					TX_CLK_DIV <= 11'h030;
			end
			11'h05F:
			begin
				if(CTL_REG[3:0] == 4'h7)
					TX_CLK_DIV <= 11'h000;
				else
					TX_CLK_DIV <= 11'h060;
			end
			11'h0BF:
			begin
				if(CTL_REG[3:0] == 4'h6)
					TX_CLK_DIV <= 11'h000;
				else
					TX_CLK_DIV <= 11'h0C0;
			end
			11'h17F:
			begin
				if(CTL_REG[3:0] == 4'h5)
					TX_CLK_DIV <= 11'h000;
				else
					TX_CLK_DIV <= 11'h180;
			end
			11'h1AB:
			begin
				if(CTL_REG[3:0] == 4'h4)
					TX_CLK_DIV <= 11'h000;
				else
					TX_CLK_DIV <= 11'h1AC;
			end
			11'h20B:
			begin
				if(CTL_REG[3:0] == 4'h3)
					TX_CLK_DIV <= 11'h000;
				else
					TX_CLK_DIV <= 11'h20C;
			end
			11'h2FF:
			begin
				if(CTL_REG[3:0] == 4'h2)
					TX_CLK_DIV <= 11'h000;
				else
					TX_CLK_DIV <= 11'h300;
			end
			11'h47F:
			begin
				TX_CLK_DIV <= 11'h000;
			end
			default:
			begin
				TX_CLK_DIV <= TX_CLK_DIV +1'b1;
			end
			endcase
		end
	end
end

assign TX_CLK = (CTL_REG[3:0] == 4'h0)	?	XTAL_CLK_IN:
											TX_CLK_REG;

assign RX_CLK = (CTL_REG[4] == 1'b0)	?	RX_CLK_IN:
											TX_CLK;

assign RESET_X = RESET_NX 					?	1'b0:
												RESET_N;

always @ (negedge CLK)
begin
		if (TX_CLK)
			LOOPBACK <= {LOOPBACK[6:0], TX_DATA};			//half bit time FIFO
end

assign RX_DATA = (CMD_REG[4:2] == 3'b100)	?	LOOPBACK[7]:
												RXDATA_IN;

assign TXDATA_OUT =	(CMD_REG[4:2] == 3'b100)	?	1'b1:
													TX_DATA;

assign STATUS_REG = {!IRQ, DSR, DCD, TDRE, RDRF, OVERRUN, FRAME, PARITY};

assign DO =	(RS == 2'b00)	?	RX_REG:
			(RS == 2'b01)	?	STATUS_REG:
			(RS == 2'b10)	?	CMD_REG:
								CTL_REG;

assign IRQ =	({CMD_REG[1:0], RDRF} == 3'b011)						?	1'b0:
				({CMD_REG[3:2], CMD_REG[0], TDRE} == 4'b0111)			?	1'b0:
																			1'b1;

assign RTS = (CMD_REG[3:2] == 2'b00);
assign DTR = ~CMD_REG[0];

assign STOP =	(CTL_REG[7] == 1'b0)									?	1'b0:		// Stop = 1
				({CTL_REG[7:5], CMD_REG[5]} == 4'b1001)					?	1'b0:		// Stop >1 but 8bit word and parity
																			1'b1;		// Stop > 1

assign PAR_DIS = ~CMD_REG[5];
assign WORD_SELECT = CTL_REG[6:5];

always @ (negedge CLK or negedge RESET_N)
begin
	if(!RESET_N)
		RESET_NX <= 1'b1;
	else
	begin
		if (PH_2)
			if({RW_N, CS, RS} == 5'b00101)						// Software RESET
				RESET_NX <= 1'b1;
			else
				RESET_NX <= 1'b0;
			end
end

always @ (negedge CLK or negedge RESET_X)
begin
	if(!RESET_X)
	begin
		RDRF <= 1'b0;
		READ_STATE <= 2'b00;
		TX_BUFFER <= 8'h00;
		CTL_REG <= 8'h00;
// Commador data sheet says reset value is 02
// but Apple will not work unless it is 00
		CMD_REG <= 8'h00;
		TDRE <= 1'b1;
		TX_START <= 1'b0;
		RX_REG <= 8'h00;
		OVERRUN <= 1'b0;
		FRAME <= 1'b0;
		PARITY <= 1'b0;
		TX_DONE1 <= 1'b1;
		TX_DONE0 <= 1'b1;
		READY0 <= 1'b0;
		READY1 <= 1'b0;
	end
	else
	begin
		if (PH_2)
		begin
			TX_DONE1 <= TX_DONE0;			// sync TX_DONE with E clock for metastability?
			TX_DONE0 <= TX_DONE;
			READY1 <= READY0;
			READY0 <= GOT_DATA;
			case (READ_STATE)
			2'b00:
			begin
				if(READY1)				//Stop bit
				begin
					RDRF <= 1'b1;
					READ_STATE <= 2'b01;
					RX_REG <= RX_BUFFER;
					OVERRUN <= 1'b0;
					PARITY <= (PARITY_ERR & !PAR_DIS);
					FRAME <= FRAME_BUF;
				end
			end
			2'b01:
			begin
				if({RW_N, CS, RS} == 5'b10100)
				begin
					RDRF <= 1'b0;
					READ_STATE <= 2'b10;
					PARITY <= 1'b0;
					OVERRUN <= 1'b0;
					FRAME <= 1'b0;
				end
				else
				begin
					if(~READY1)
						READ_STATE <= 2'b11;
				end
			end
			2'b10:
			begin
				if(~READY1)
					READ_STATE <= 2'b00;
			end
			2'b11:
			begin
				if({RW_N, CS, RS} == 5'b10100)
				begin
					RDRF <= 1'b0;
					READ_STATE <= 2'b00;
					PARITY <= 1'b0;
					OVERRUN <= 1'b0;
					FRAME <= 1'b0;
				end
				else
				begin
					if(READY1)
					begin
						RDRF <= 1'b1;
						READ_STATE <= 2'b01;
						OVERRUN <= 1'b1;
						PARITY <= (PARITY_ERR & !PAR_DIS);
						FRAME <= FRAME_BUF;
						RX_REG <= RX_BUFFER;
					end
				end
			end
			endcase

			if({RW_N, CS, RS} == 5'b00100)						// Write TX data register
				TX_REG <= DI;

			if({RW_N, CS, RS} == 5'b00110)						// Write CMD register
				CMD_REG <= DI;

			if({RW_N, CS, RS} == 5'b00111)						// Write CTL register
				CTL_REG <= DI;

			if(~TDRE & TX_DONE1 & ~TX_START & ~(CS == 2'b01))
			begin
				TX_BUFFER <= TX_REG;
				TDRE <= 1'b1;
				TX_START <= 1'b1;
			end
			else
			begin
				if({RW_N, CS, RS} == 5'b00100)					// Write TX data register
					TDRE <= 1'b0;
				if(~TX_DONE1)
					TX_START <= 1'b0;
			end
		end
	end
end

uart51_tx tx(
.RESET_N(RESET_X),
.CLK(CLK),
.BAUD_CLK(TX_CLK),
.TX_DATA(TX_DATA),
.TX_START(TX_START),
.TX_DONE(TX_DONE),
.TX_STOP(STOP),
.TX_WORD(WORD_SELECT),
.TX_PAR_DIS(PAR_DIS),
.TX_PARITY(CMD_REG[7:6]),
.CTS(CTS),
.TX_BUFFER(TX_BUFFER)
);

uart51_rx rx(
.RESET_N(RESET_X),
.CLK(CLK),
.BAUD_CLK(RX_CLK),
.RX_DATA(RX_DATA),
.RX_BUFFER(RX_BUFFER),
.RX_WORD(WORD_SELECT),
.RX_PAR_DIS(PAR_DIS),
.RX_PARITY(CMD_REG[7:6]),
.PARITY_ERR(PARITY_ERR),
.FRAME(FRAME_BUF),
.READY(GOT_DATA)
);

endmodule
