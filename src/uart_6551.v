////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 1.0
// File Name:		uart_6551.v
//
// CoCo3 in an FPGA
// Based on the Spartan 3 Starter board by Digilent Inc.
// with the 1000K gate upgrade
//
// Revision: 1.0 08/31/08
////////////////////////////////////////////////////////////////////////////////
//
// CPU section copyrighted by John Kent
//
////////////////////////////////////////////////////////////////////////////////
//
// Color Computer 3 compatible system on a chip
//
// Version : 1.0
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
//  1.0		Full release
//
////////////////////////////////////////////////////////////////////////////////
// Gary Becker
// gary_L_becker@yahoo.com
////////////////////////////////////////////////////////////////////////////////

module glb6551(
    input clk_logic_i,
	input RESET_N,
	input PH_2,
	input[7:0] DI,
	output[7:0] DO,
	output IRQ,
	input[1:0] CS,
	input[1:0] RS,
	input RW_N,
	output TXDATA_OUT,
	input RXDATA_IN,
	output RTS,
	input CTS,
	input DCD,
	output DTR,
	input DSR
);

reg[7:0] TX_BUFFER;
reg[7:0] TX_REG;
wire[7:0] RX_BUFFER;
reg[7:0] RX_REG;
wire[7:0] STATUS_REG;
reg[7:0] CTL_REG;
reg[7:0] CMD_REG;

wire TX_DONE;
reg TX_START;
reg TDRE;
reg RDRF;
wire RESET_X;
wire LOOPBACK;
wire RX_DATA;
wire TX_DATA;
reg RESET_NX;
reg[1:0] READ_STATE;
wire GOT_DATA;

assign RESET_X = RESET_NX ?	1'b0: RESET_N;

assign RX_DATA = (CMD_REG[4:2] == 3'b100) ?	LOOPBACK: RXDATA_IN;

assign TXDATA_OUT  = /* (CMD_REG[4:2] == 3'b100)	?	1'b1: */ TX_DATA;

assign STATUS_REG = {!IRQ, DSR, DCD, TDRE, RDRF, 1'b0, 1'b0, 1'b0};

assign DO =	(RS == 2'b00)	?	RX_REG:
				(RS == 2'b01)	?	STATUS_REG:
				(RS == 2'b10)	?	CMD_REG:
										CTL_REG;

assign IRQ =	({CMD_REG[1:0], RDRF} == 3'b011)							?	1'b0:
					({CMD_REG[3:2], CMD_REG[0], TDRE} == 4'b0111)		?	1'b0:	1'b1;

assign RTS = (CMD_REG[3:2] == 2'b00);
assign DTR = ~CMD_REG[0];

always @ (posedge clk_logic_i or negedge RESET_N)
begin
	if(!RESET_N)
		RESET_NX <= 1'b1;
	else
	begin
		if({RW_N, CS, RS} == 5'b00101)						// Software RESET
			RESET_NX <= 1'b1;
		else
			RESET_NX <= 1'b0;
	end
end

always @ (posedge clk_logic_i or negedge RESET_X)
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
		end
	else
		begin
			case (READ_STATE)
				2'b00:
				begin
					if(GOT_DATA)				//Stop bit
					begin
						RDRF <= 1'b1;
						READ_STATE <= 2'b01;
						RX_REG <= RX_BUFFER;
					end
				end
				2'b01:
				begin
					if({PH_2, RW_N, CS, RS} == 6'b110100)
					begin
						RDRF <= 1'b0;
						READ_STATE <= 2'b10;
					end
					else
					begin
						if(~GOT_DATA)
							READ_STATE <= 2'b11;
					end
				end
				2'b10:
				begin
					if(~GOT_DATA)
						READ_STATE <= 2'b00;
				end
				2'b11:
				begin
					if({PH_2, RW_N, CS, RS} == 6'b110100)
					begin
						RDRF <= 1'b0;
						READ_STATE <= 2'b00;
					end
					else
					begin
						if(GOT_DATA)
						begin
							// Register full, Overrun error, parity error, framing error
							RDRF <= 1'b1;
							READ_STATE <= 2'b01;
							//RX_REG <= RX_BUFFER;
							RX_REG <= 8'd71;
						end
					end
				end
			endcase

			if({PH_2, RW_N, CS, RS} == 6'b100100)						// Write TX data register
				TX_REG <= DI;
				//TX_REG <= 8'd70;

			if({PH_2, RW_N, CS, RS} == 6'b100110)						// Write CMD register
				CMD_REG <= DI;

			if({PH_2, RW_N, CS, RS} == 6'b100111)						// Write CTL register
				CTL_REG <= DI;

			if(~TDRE & TX_DONE & ~TX_START & ~(CS == 2'b01))
				begin
					TX_BUFFER <= TX_REG;
					TDRE <= 1'b1;
					TX_START <= 1'b1;
				end
			else
				begin
					if({PH_2, RW_N, CS, RS} == 6'b100100)					// Write TX data register
						TDRE <= 1'b0;
					if(~TX_DONE)
						TX_START <= 1'b0;
				end
		end
end

localparam CLK_FRE = 50_000_000;
localparam CYCLE_50 = CLK_FRE / 50;
localparam CYCLE_75 = CLK_FRE / 75;
localparam CYCLE_110 = CLK_FRE / 110;
localparam CYCLE_135 = CLK_FRE / 135;
localparam CYCLE_150 = CLK_FRE / 150;
localparam CYCLE_300 = CLK_FRE / 300;
localparam CYCLE_600 = CLK_FRE / 600;
localparam CYCLE_1200 = CLK_FRE / 1200;
localparam CYCLE_1800 = CLK_FRE / 1800;
localparam CYCLE_2400 = CLK_FRE / 2400;
localparam CYCLE_3600 = CLK_FRE / 3600;
localparam CYCLE_4800 = CLK_FRE / 4800;
localparam CYCLE_7200 = CLK_FRE / 7200;
localparam CYCLE_9600 = CLK_FRE / 9600;
localparam CYCLE_19200 = CLK_FRE / 19200;
localparam CYCLE_115200 = CLK_FRE / 115200;

reg[19:0] cycle; //baud cycle

always@(posedge clk_logic_i or negedge RESET_X)
begin
	if(~RESET_X) cycle <= CYCLE_9600;
	else
		case (CTL_REG[3:0])
			4'd0: cycle <= CYCLE_115200;
			4'd1: cycle <= CYCLE_50;
			4'd2: cycle <= CYCLE_75;
			4'd3: cycle <= CYCLE_110;
			4'd4: cycle <= CYCLE_135;
			4'd5: cycle <= CYCLE_150;
			4'd6: cycle <= CYCLE_300;
			4'd7: cycle <= CYCLE_600;
			4'd8: cycle <= CYCLE_1200;
			4'd9: cycle <= CYCLE_1800;
			4'd10: cycle <= CYCLE_2400;
			4'd11: cycle <= CYCLE_3600;
			4'd12: cycle <= CYCLE_4800;
			4'd13: cycle <= CYCLE_7200;
			4'd14: cycle <= CYCLE_9600;
			4'd15: cycle <= CYCLE_19200;
			default: cycle <= CYCLE_9600;
		endcase
end

wire rx_data_ready = 1'b1; //always can receive data,

uart_rx uart_rx_inst
(
	.clk(clk_logic_i),
	.cycle(cycle),
	.rst_n(RESET_X),
	.rx_data(RX_BUFFER),
	.rx_data_valid(GOT_DATA),
	.rx_data_ready(rx_data_ready),
	.rx_pin(RX_DATA)
);

uart_tx uart_tx_inst
(
	.clk(clk_logic_i),
	.cycle(cycle),
	.rst_n(RESET_X),
	.tx_data(TX_BUFFER),
	//.tx_data(8'd69),
	.tx_data_valid(TX_START),
	.tx_data_ready(TX_DONE),
	.tx_pin(TX_DATA),
	.loopback(LOOPBACK)
);

endmodule
