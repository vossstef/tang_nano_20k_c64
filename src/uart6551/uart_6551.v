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

// serial rs232 connection to io controller
output		[7:0]	serial_data_out_available;
output		[7:0]	serial_data_in_free;
input				serial_strobe_out;
output		[7:0]	serial_data_out;
output    [31:0]	serial_status_out;

// serial rs223 connection from io controller
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

wire	[1:0]		WORD_SELECT;
wire				RESET_X;
wire				PAR_DIS;
reg					RESET_NX;

// report the available unused space in the input fifo
assign serial_data_in_free = { 4'h0, serial_data_in_space };

wire serial_data_out_fifo_full;
wire serial_data_in_full;

wire write = PH_2 && CS==2'b01 && !RW_N && RS==2'b00;
wire read  = PH_2 && CS==2'b01 &&  RW_N && RS==2'b00;

// --- 6551 output fifo ---
// filled by the CPU when writing to the uart data register
// emptied by the io controller when reading via SPI
assign serial_data_out_available[7:4] = 4'h0;

assign RX_CLK = 1'b0 ;

io_fifo uart_out_fifo (
	.reset            ( ~RESET_N ),

	.in_clk           ( CLK ),
	.in               ( DI ),
	.in_strobe        ( 1'b0 ),
	.in_enable        ( write ),

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
		// read on uart RX data register
		if(read) 
			serial_cpu_data_read <= 1'b1;
end

// assemble output status structure. Adjust bitrate endianess
assign serial_status_out = { 
	bitrate[7:0], bitrate[15:8], bitrate[23:16], 
	databits, parity, stopbits };

// --- export bit rate based on 6551 config ---
wire [23:0] bitrate = 
	(CTL_REG[3:0] == 4'hf)?24'd38400:       // 38400 bit/s
	(CTL_REG[3:0] == 4'he)?24'd19200:       // 19200 bit/s
	(CTL_REG[3:0] == 4'hd)?24'd9600:        // 9600 bit/s
	(CTL_REG[3:0] == 4'hc)?24'd7200:        // 7200 bit/s
	(CTL_REG[3:0] == 4'hb)?24'd4800:        // 4800 bit/s
	(CTL_REG[3:0] == 4'ha)?24'd3600:        // 3600 bit/s
	(CTL_REG[3:0] == 4'h9)?24'd2400:        // 2400 bit/s
	(CTL_REG[3:0] == 4'h8)?24'd1800:        // 1800 bit/s
	(CTL_REG[3:0] == 4'h7)?24'd1200:        // 1200 bit/s
	(CTL_REG[3:0] == 4'h6)?24'd600:         // 600 bit/s
	(CTL_REG[3:0] == 4'h5)?24'd300:         // 300 bit/s
	(CTL_REG[3:0] == 4'h4)?24'd150:         // 150 bit/s
	(CTL_REG[3:0] == 4'h3)?24'd134:         // 134 bit/s
	(CTL_REG[3:0] == 4'h2)?24'd109:         // 109 bit/s
	(CTL_REG[3:0] == 4'h1)?24'd75:          // 75 bit/s
	24'd230400;                             // 16 x external clk
	
// timer to simulate the timing behaviour of a serial transmitter by
// reporting "tx buffer not empty" for about one byte time after each byte
// being requested to be sent
wire [1:0] parity = 2'h0;
wire [1:0] stopbits = 2'h0;
wire [3:0] databits = 4'd8;
wire [7:0] timerd_set_data =
	(CTL_REG[3:0] == 4'hf)?8'h01:  // 38400 bit/s
	(CTL_REG[3:0] == 4'he)?8'h02:  // 19200 bit/s
	(CTL_REG[3:0] == 4'hd)?8'h04:  // 9600 bit/s
	(CTL_REG[3:0] == 4'hc)?8'h05:  // 7200 bit/s
	(CTL_REG[3:0] == 4'hb)?8'h08:  // 4800 bit/s
	(CTL_REG[3:0] == 4'ha)?8'h0a:  // 3600 bit/s
	(CTL_REG[3:0] == 4'h9)?8'h10:  // 2400 bit/s
	(CTL_REG[3:0] == 4'h8)?8'h16:  // 1800 bit/s
	(CTL_REG[3:0] == 4'h7)?8'h20:  // 1200 bit/s	
	(CTL_REG[3:0] == 4'h6)?8'h40:  // 600 bit/s
	(CTL_REG[3:0] == 4'h5)?8'h80:  // 300 bit/s
	(CTL_REG[3:0] == 4'h4)?8'h40:  // 150 bit/s
	(CTL_REG[3:0] == 4'h3)?8'h48:  // 134 bit/s
	(CTL_REG[3:0] == 4'h2)?8'h50:  // 109 bit/s
	(CTL_REG[3:0] == 4'h1)?8'hBE:  // 75 bit/s
	8'h01;                         // 16*ext clk, 230400 bit/s

// bps is 3.6864MHz /2/16 prescaler/datavalue. These values are used for byte timing
// and are thus 10*the bit values (1 start + 8 data + 1 stop)
wire [10:0] uart_prediv =
	(CTL_REG[3:0] == 4'hf)?11'd30:  // 38400 bit/s
	(CTL_REG[3:0] == 4'he)?11'd30:  // 19200 bit/s
	(CTL_REG[3:0] == 4'hd)?11'd30:  // 9600 bit/s
	(CTL_REG[3:0] == 4'hc)?11'd30:  // 7200 bit/s
	(CTL_REG[3:0] == 4'hb)?11'd30:  // 4800 bit/s
	(CTL_REG[3:0] == 4'ha)?11'd30:  // 3600 bit/s
	(CTL_REG[3:0] == 4'h9)?11'd30:  // 2400 bit/s
	(CTL_REG[3:0] == 4'h8)?11'd30:  // 1800 bit/s
	(CTL_REG[3:0] == 4'h7)?11'd30:  // 1200 bit/s
	(CTL_REG[3:0] == 4'h6)?11'd30:  // 600 bit/s
	(CTL_REG[3:0] == 4'h5)?11'd30:  // 300 bit/s
	(CTL_REG[3:0] == 4'h4)?11'd120: // 150 bit/s
	(CTL_REG[3:0] == 4'h3)?11'd120: // 134 bit/s
	(CTL_REG[3:0] == 4'h2)?11'd120: // 109 bit/s
	(CTL_REG[3:0] == 4'h1)?11'd120: // 75 bit/s
	11'd30;                         // 16*ext clk, 230400 bit/s

reg [15:0]	uart_rx_prediv_cnt;
reg [15:0]	uart_tx_prediv_cnt;
reg [7:0]	uart_tx_delay_cnt;
wire		uart_tx_busy = uart_tx_delay_cnt != 8'd0;
reg [7:0]	uart_rx_delay_cnt;
assign		uart_rx_busy = uart_rx_delay_cnt != 8'd0;

// delay data_in_available one more cycle to give the fifo a chance to remove one item
wire	   serial_data_in_available = !serial_data_in_empty && !uart_rx_busy && !uart_rx_busyD;

always @(posedge CLK) begin
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
   if(write) begin
      // CPU write to TX Data starts the delay counter. The uart transamitter is then
      // reported busy as long as the counter runs
      uart_tx_delay_cnt <= timerd_set_data;
      uart_tx_prediv_cnt <= { uart_prediv-11'd1, 5'b00000 };    // load predivider with 2*16 the predivider value    
   end
end

// the cpu reading data clears rx irq. It may raise again immediately if there's more
// data in the input fifo.
wire uart_rx_irq = serial_data_in_available;

// the io controller reading data clears tx irq. It may raus again immediately if 
// there's more data in the output fifo
wire uart_tx_irq = !serial_data_out_fifo_full && !serial_strobe_out;

// 6551 UART

assign RESET_X = RESET_NX 					?	1'b0:
											RESET_N;
assign TXDATA_OUT =	1'b1;

assign TDRE = !serial_data_out_fifo_full && !uart_tx_busy;
assign RDRF = serial_data_in_available;

assign STATUS_REG = {!IRQ, DSR, DCD, TDRE, RDRF, OVERRUN, FRAME, PARITY};
assign DO =	(RS == 2'b00)	?	serial_data_in_cpu:
			(RS == 2'b01)	?	STATUS_REG:
			(RS == 2'b10)	?	CMD_REG:
								CTL_REG;

assign IRQ =	({CMD_REG[1:0], RDRF} == 3'b011) ? 1'b0:
				({CMD_REG[3:2], CMD_REG[0], TDRE} == 4'b0111) ?	1'b0:1'b1; // low active

assign RTS = (CMD_REG[3:2] == 2'b00);
assign DTR = ~CMD_REG[0];
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
