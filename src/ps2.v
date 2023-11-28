`timescale 1ns / 1ps
`default_nettype none

module ps2 (
    input wire clk,
    input wire ps2_clk,
    input wire ps2_data,
    output wire[10:0] ps2_key
);

    `define RCVSTART    2'b00
    `define RCVDATA     2'b01 
    `define RCVPARITY   2'b10
    `define RCVSTOP     2'b11

    reg [7:0] scancode;
    reg       extended = 1'b0;
    reg       released = 1'b0;
    reg       kb_interrupt = 1'b0;
    reg       kb_released = 1'b0;
    reg       kb_extended = 1'b0;

    reg [7:0] key = 8'h00;
    reg [1:0] state = `RCVSTART;
    
    assign ps2_key = {kb_interrupt, ~kb_released, kb_extended, scancode};

    // Synchronise ps2 clock and data with system clock
    reg [1:0] ps2clk_synchr;
    reg [1:0] ps2dat_synchr;
    wire ps2clk = ps2clk_synchr[1];
    wire ps2data = ps2dat_synchr[1];
    
    always @(posedge clk) begin
        ps2clk_synchr[0] <= ps2_clk;
        ps2clk_synchr[1] <= ps2clk_synchr[0];
        ps2dat_synchr[0] <= ps2_data;
        ps2dat_synchr[1] <= ps2dat_synchr[0];
    end

    // De-glitcher. Detect falling edge of ps2_clk
    reg [15:0] negedge_detect = 16'h0000;
    always @(posedge clk) begin
        negedge_detect <= {negedge_detect[14:0], ps2clk};
    end
    wire ps2clk_edge = (negedge_detect == 16'hF000);
    
    // Time out and return to start state if no falling edge is detected
    // on ps2_clk for 64k clock cycles
    reg [15:0] timeout_cnt = 0;

    always @(posedge clk) begin
        kb_interrupt <= 1'b0;

        if (ps2clk_edge) begin
            timeout_cnt <= 16'h0000;
            if (state == `RCVSTART && !ps2data) begin // Start bit
                state <= `RCVDATA;
                key <= 8'h80;
            end else if (state == `RCVDATA) begin
                key <= {ps2data, key[7:1]};
                if (key[0]) state <= `RCVPARITY;
            end else if (state == `RCVPARITY) begin
		state <= ps2data ^ ^key ? `RCVSTOP : state <= `RCVSTART;
            end else if (state == `RCVSTOP) begin
                state <= `RCVSTART;                
                if (ps2data) begin // Stop bit
                   if (key == 8'hE0) extended <= 1'b1;
                   else if (key == 8'hF0) released <= 1'b1;
                   else begin
                     scancode <= key;
		     kb_released <= released;
		     kb_extended <= extended;
		     extended <= 1'b0;
		     released <= 1'b0;
                     kb_interrupt <= 1'b1;
                   end
                end
            end      
        end else begin
            timeout_cnt <= timeout_cnt + 1;
	    if (&timeout_cnt) begin
              state <= `RCVSTART;
              //extended <= 1'b0;
              //released <= 2'b0;
            end
        end
    end
endmodule
`default_nettype wire
