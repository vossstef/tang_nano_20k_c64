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
//
// 03/2025      Stefan Voss io controller added based on Till Harbaums MFP 68901 work
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
DSR,

// serial rs232 connection to io controller
serial_data_out_available,  // bytes available
serial_data_in_free,        // free buffer available
serial_strobe_out,
serial_data_out,
serial_status_out,

// serial rs223 connection from io controller
serial_strobe_in,
serial_data_in
);

input				RESET_N;
input				CLK;
output				RX_CLK;
input				RX_CLK_IN;
input				XTAL_CLK_IN;
input				PH_2;
input		[7:0]	DI;
output		[7:0]	DO;
output				IRQ;
input		[1:0]	CS;
input		[1:0]	RS;
input				RW_N;
output				TXDATA_OUT;
input				RXDATA_IN;
output				RTS;
input				CTS;
input				DCD;
output				DTR;
input				DSR;

output		[7:0]	serial_data_out_available;
output		[7:0]	serial_data_in_free;
input				serial_strobe_out;
output		[7:0]	serial_data_out;
output    [31:0]	serial_status_out;
input				serial_strobe_in;
input		[7:0]	serial_data_in;


wire	[7:0]		STATUS_REG;
reg		[7:0]		CTL_REG = 8'd0;
reg		[7:0]		CMD_REG = 8'd0;
reg					OVERRUN = 1'b0;
reg					FRAME = 1'b0;
reg					PARITY = 1'b0;
reg					TDRE;
reg					RDRF;

reg		[10:0]		TX_CLK_DIV;
wire				TX_CLK;
wire				RX_CLK;
wire	[1:0]		WORD_SELECT;
wire				RESET_X;
wire				STOP;
wire				PAR_DIS;
reg		[7:0]		LOOPBACK;
wire				RX_DATA;
wire				TX_DATA;
reg					RESET_NX;
reg					TX_CLK_REG_T;
reg			 		TX_CLK_REG;

// assemble output status structure. Adjust bitrate endianess
assign serial_status_out = { 
	bitrate[7:0], bitrate[15:8], bitrate[23:16], 
	databits, parity, stopbits };

// report the available unused space in the input fifo
assign serial_data_in_free = { 4'h0, serial_data_in_space };

wire serial_data_out_fifo_full;
wire serial_data_in_full;

// --- 6551 output fifo ---
// filled by the CPU when writing to the uart data register
// emptied by the io controller when reading via SPI
assign serial_data_out_available[7:4] = 4'h0;

io_fifo uart_out_fifo (
	.reset            ( ~RESET_N ),

	.in_clk           ( CLK ),
	.in               ( DI ),
	.in_strobe        ( 1'b0 ),
	.in_enable        ( {PH_2, RW_N, CS, RS} == 6'b100100 ),

	.out_clk          ( CLK ),
	.out              ( serial_data_out ),
	.out_strobe       ( serial_strobe_out ),
	.out_enable       ( 1'b0 ),

	.space            (  ),
	.used             ( serial_data_out_available[3:0] ),
	.empty            (  ),
	.full             ( serial_data_out_fifo_full )
);

reg serial_cpu_data_read;
wire [7:0] serial_data_in_cpu;
wire	   serial_data_in_empty;
wire [3:0] serial_data_in_used;
wire [3:0] serial_data_in_space;
wire	   uart_rx_busy;

// As long as "rx busy" the same previous byte can still be read from the
// rx fifo. Thus we increment the io_fifo read pointer at the end of
// the rx_busy phase which is the falling edge of uart_rx_busy
reg uart_rx_busyD;
always @(posedge CLK) uart_rx_busyD <= uart_rx_busy;
wire uart_rx_busy_ends = !uart_rx_busy && uart_rx_busyD;
   
// --- uart input fifo ---
// filled by the io controller when writing via SPI
// emptied by CPU when reading the uart RXD data register
io_fifo uart_in_fifo (
	.reset            ( ~RESET_N ),

	.in_clk           ( CLK ),
	.in               ( serial_data_in ),
	.in_strobe        ( serial_strobe_in ),
	.in_enable        ( 1'b0 ),

	.out_clk          ( CLK ),
	.out              ( serial_data_in_cpu ),
	.out_strobe       ( 1'b0 ),
	.out_enable       ( !serial_data_in_empty && uart_rx_busy_ends ),

	.space            ( serial_data_in_space ),
	.used             ( serial_data_in_used ),
	.empty            ( serial_data_in_empty ),
	.full             ( serial_data_in_full )
);

// ---------------- uart data to/from io controller ------------
always @(posedge CLK) begin
	serial_cpu_data_read <= 1'b0;
	if (PH_2) begin
		// read on uart RX data register
		if({RW_N, CS, RS} == 5'b10100)  // RXD Addr = 0
			serial_cpu_data_read <= 1'b1;
	end
end

// delay data_in_available one more cycle to give the fifo a chance to remove one item
wire	   serial_data_in_available = !serial_data_in_empty && !uart_rx_busy && !uart_rx_busyD;

// the cpu reading data clears rx irq. It may raise again immediately if there's more
// data in the input fifo.
wire uart_rx_irq = serial_data_in_available;

// the io controller reading data clears tx irq. It may raus again immediately if 
// there's more data in the output fifo
wire uart_tx_irq = !serial_data_out_fifo_full && !serial_strobe_out;

// timer to simulate the timing behaviour of a serial transmitter by
// reporting "tx buffer not empty" for about one byte time after each byte
// being requested to be sent
wire [23:0] bitrate = 24'd38400;
wire [1:0] parity = 2'h0;
wire [1:0] stopbits = 2'h0;
wire [3:0] databits = 4'd8;
wire [3:0] timerd_ctrl_o = 3'b001;  // 38400 bit/s
wire [7:0] timerd_set_data = 8'h01; // 38400 bit/s

// bps is 3.6864MHz /2/16 prescaler/datavalue. These values are used for byte timing
// and are thus 10*the bit values (1 start + 8 data + 1 stop)
wire [10:0] uart_prediv =11'd30; // 38400 bit/s

reg [15:0] uart_rx_prediv_cnt;
reg [15:0] uart_tx_prediv_cnt;
reg [7:0]  uart_tx_delay_cnt;
wire   uart_tx_busy = uart_tx_delay_cnt != 8'd0;
reg [7:0]  uart_rx_delay_cnt;
assign     uart_rx_busy = uart_rx_delay_cnt != 8'd0;

// delay data_in_available one more cycle to give the fifo a chance to remove one item
wire   serial_data_in_available = !serial_data_in_empty && !uart_rx_busy && !uart_rx_busyD;

reg [1:0 ]CS_D;

always @(posedge CLK) begin
	CS_D <= CS;

   // the timer itself runs at 3.6864 Mhz
   if(XTAL_CLK_IN) begin
      if(uart_rx_prediv_cnt != 16'd0)
	 uart_rx_prediv_cnt <= uart_rx_prediv_cnt - 16'd1;
      else begin
	 uart_rx_prediv_cnt <= { uart_prediv-11'd1, 5'b00000 };
	 if(uart_rx_delay_cnt != 8'd0)
	   uart_rx_delay_cnt <= uart_rx_delay_cnt - 8'd1;
      end
	 
      if(uart_tx_prediv_cnt != 16'd0)
	 uart_tx_prediv_cnt <= uart_tx_prediv_cnt - 16'd1;
      else begin
	 uart_tx_prediv_cnt <= { uart_prediv-11'd1, 5'b00000 };
	 if(uart_tx_delay_cnt != 8'd0)
	   uart_tx_delay_cnt <= uart_tx_delay_cnt - 8'd1;
      end
   end

	// CPU reads the RX Data Register)
	if(serial_cpu_data_read && serial_data_in_available) begin
		uart_rx_delay_cnt <= timerd_set_data;
		uart_rx_prediv_cnt <= { uart_prediv-11'd1, 5'b00000 };// load predivider with 2*16 the predivider value
	end

   // cpu bus write to TX data register
   if({PH_2, RW_N, CS_D, CS, RS} == 8'b10100100) begin
      // CPU write to TX Data starts the delay counter. The uart transamitter is then
      // reported busy as long as the counter runs
      uart_tx_delay_cnt <= timerd_set_data;
      uart_tx_prediv_cnt <= { uart_prediv-11'd1, 5'b00000 };    // load predivider with 2*16 the predivider value    
   end
end

// 6551 UART
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

assign TDRE = !serial_data_out_fifo_full && !uart_tx_busy;
assign RDRF = serial_data_in_available;

assign STATUS_REG = {!IRQ, DSR, DCD, TDRE, RDRF, OVERRUN, FRAME, PARITY};
assign DO =	(RS == 2'b00)	?	serial_data_in_cpu:
			(RS == 2'b01)	?	STATUS_REG:
			(RS == 2'b10)	?	CMD_REG:
								CTL_REG;

assign IRQ =	({CMD_REG[1:0], RDRF} == 3'b011)			?	1'b0:
				({CMD_REG[3:2], CMD_REG[0], TDRE} == 4'b0111) ?	1'b0:
																1'b1; // low active

assign RTS = (CMD_REG[3:2] == 2'b00);
assign DTR = ~CMD_REG[0];

assign STOP =	(CTL_REG[7] == 1'b0)									?	1'b0:	// Stop = 1
				({CTL_REG[7:5], CMD_REG[5]} == 4'b1001)					?	1'b0:	// Stop >1 but 8bit word and parity
																			1'b1;	// Stop > 1

assign PAR_DIS = ~CMD_REG[5];
assign WORD_SELECT = CTL_REG[6:5];

always @ (negedge CLK or negedge RESET_N)
begin
	if(!RESET_N)
		RESET_NX <= 1'b1;
	else
	begin
		if (PH_2)
			if({RW_N, CS, RS} == 5'b00101) // Software RESET
				RESET_NX <= 1'b1;
			else
				RESET_NX <= 1'b0;
			end
end

always @ (negedge CLK or negedge RESET_X)
begin
	if(!RESET_X)
	begin
		CTL_REG <= 8'h00;
		CMD_REG <= 8'h00;
		OVERRUN <= 1'b0;
		FRAME <= 1'b0;
		PARITY <= 1'b0;
	end
	else
	begin
		if (PH_2)
		begin
			if({RW_N, CS, RS} == 5'b00110) // Write CMD register
				CMD_REG <= DI;

			if({RW_N, CS, RS} == 5'b00111) // Write CTL register
				CTL_REG <= DI;
		end
	end
end

endmodule
