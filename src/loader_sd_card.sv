// 
// loader_sd_card.sv
//
// 2024 Stefan Voss
//
module loader_sd_card
(
	input clk,
	input reset,

	output reg [31:0] sd_lba,
	output reg [2:0] sd_rd, // read request for target
	output reg [2:0] sd_wr, // write request for target
	input sd_busy, // SD is busy (has accepted read or write request)

	input [8:0] sd_byte_index, // address of data byte within 512 bytes sector
	input [7:0] sd_rd_data, // data byte received from SD card
	input sd_rd_byte_strobe, // SD has read a byte to be stored in  buffer
	input sd_done, // SD is done (data has been read or written

	input [3:0] sd_img_mounted,
	input [31:0] sd_img_size,
	output reg load_crt,
	output reg load_prg,
	output reg load_rom,
	output reg loader_busy,
	output reg [1:0] img_select,
	output reg [4:0] leds,

	output reg ioctl_download,
	output reg [22:0] ioctl_addr,
	output reg [7:0] ioctl_data,
	output reg ioctl_wr,
	input ioctl_wait
);

// states of FSM
localparam [2:0] WAIT4CHANGE     = 3'd0,
                 READ_WAIT4SD    = 3'd1,
                 READING         = 3'd2,
                 SPARE2          = 3'd3,
                 READ_NEXT       = 3'd4,
                 DESELECT        = 3'd5,
                 SPARE1          = 3'd6,
                 WAIT4CORE       = 3'd7;

reg img_present[3:0];
wire change = img_present[1]||img_present[2]||img_present[3];

always @(posedge clk) begin

reg [2:0] io_state;
reg old_change;
reg [22:0] addr;
reg [31:0] ch_timeout;
reg wr;
reg [8:0] cnt;
reg [4:0] core_wait_cnt;
reg [22:0] img_size[3:0];
integer i;

	for(i = 0; i < 4; i = i + 1'd1) 
	begin
		if (sd_img_mounted[i]) 
		begin
			img_present[i] <= |sd_img_size;
			img_size[i] <= sd_img_size[22:0];
		end
	end

  //if(img_present[0]) img_select <= 0;
	if(img_present[1]) img_select <= 1;
	else if(img_present[2]) img_select <= 2;
	else if(img_present[3]) img_select <= 3;

//	leds[0] <= img_present[0];
//	leds[1] <= img_present[1];
//	leds[2] <= img_present[2];
//	leds[3] <= img_present[3];

	ioctl_wr <= wr;
	wr <= 1'b0;
	if(sd_busy) {sd_rd,sd_wr} <= 6'd0;
	old_change <= change;

	if(reset) 
	begin
		io_state <= WAIT4CHANGE;
		sd_rd <= 3'd0;
		sd_wr <= 3'd0;
		wr <= 1'b0;
		load_crt <= 1'b0;
		load_prg <= 1'b0;
		load_rom <= 1'b0;
		ioctl_download <= 1'b0;
		ioctl_addr <= 23'd0;
		leds <= 5'd0;
		loader_busy <= 0;
	end 
	else 
	begin
	case(io_state)
		WAIT4CHANGE: 
			begin
				if(~old_change && change)
				begin
					loader_busy <= 1;
					load_crt <= img_present[1];
					load_prg <= img_present[2];
					load_rom <= img_present[3];
					ch_timeout <= 32'd1508863;
					ioctl_addr <= 23'd0;
					ioctl_download <= 1'b1;
					addr <= 23'd0;
					sd_lba <= 32'd0;
					core_wait_cnt <= 5'd0;
					io_state <= WAIT4CORE;
				end
				else loader_busy <= 1'b0;
			end

		WAIT4CORE: 
			begin
				if(ch_timeout > 0) ch_timeout <= ch_timeout - 1'd1;
				if(ch_timeout == 0 && ~ioctl_wait) 
				begin
					sd_rd[0] <= img_present[1];
					sd_rd[1] <= img_present[2];
					sd_rd[2] <= img_present[3];
					cnt <= 9'd0;
					io_state <= READ_WAIT4SD;
				end
			end

		READ_WAIT4SD:
			if(sd_done)
				io_state <= READING;

		READING: 
			begin
				if(ioctl_addr <= img_size[img_select]) // addr
					io_state <= READ_NEXT;
				else 
				begin
					leds[3:0] <= sd_lba[3:0];
					ioctl_download <= 1'b0;
					ioctl_addr <= 23'd0;
					io_state <= DESELECT;
				end
			end

		READ_NEXT:
			begin
				core_wait_cnt <= core_wait_cnt + 5'd1;
				if(~ioctl_wait && &core_wait_cnt) 
					begin
						wr <= 1'b1;
						ioctl_addr <= addr;
						addr <= addr + 1'd1;
						cnt <= cnt + 1'd1;
						if(cnt == 511) 
							begin
								sd_lba <= sd_lba + 1'd1;
								ch_timeout <= 1'd1;
								io_state <= WAIT4CORE;
							end
					end
					else
						io_state <= READING;
			end

		DESELECT: 
			begin
				load_crt <= 1'b0;
				load_prg <= 1'b0;
				load_rom <= 1'b0;
				io_state <= WAIT4CHANGE;
			end

		SPARE1: 
				io_state <= WAIT4CHANGE;

		SPARE2:
				io_state <= WAIT4CHANGE;

		default: ;

		endcase
	end // else: !if(reset)
end

Gowin_DPB_track_buffer_b trkbuf_inst_loader(
	.douta(), 
	.doutb(ioctl_data),
	.clka(clk), 
	.ocea(1'b1), 
	.cea(1'b1), 
	.reseta(1'b0), 
	.wrea(sd_rd_byte_strobe && sd_busy),// sd module
	.clkb(clk), 
	.oceb(1'b1), 
	.ceb(1'b1),
	.resetb(1'b0), 
	.wreb(1'b0),
	.ada(sd_byte_index),  // sd module
	.dina(sd_rd_data),    // sd module
	.adb(ioctl_addr[8:0]),
	.dinb(8'd0)
);

endmodule
