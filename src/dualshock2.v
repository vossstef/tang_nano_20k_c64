`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenting Zhang
// 
// Create Date:    13:13:04 04/13/2018 
// Module Name:    dualshock
// Project Name:   VerilogBoy
// Description: 
//   Interface logic of SONY DualShock controller
// Dependencies: 
//
// Additional Comments: 
//   The PSX controller use a SPI like protocol. ATT is the CS, CMD is the MOSI,
//   and the DAT is the MISO. There is an additional ACK line would be pulled
//   low by the controller indicate the presense of the controller. LSB first.
//
//   Clock is Idle High, Data are put on to bus during the leading edge, and
//   pulled from bus during the trailing edge.
//
//   The whole frame can be divided into two parts: the handshake part and the
//   data transmission part.
//
//   The handshake part is always 3 bytes long. Below is the definition:
//      | Byte | TX                | RX                   |
//      |------|-------------------|----------------------|
//      |  00  | Always 01         | Always FF            |
//      |  01  | The command byte  | Mode and ID          |
//      |  02  | Always 00         | Always 5A (padding)  |
//
//   Specifically, it has 3 mode:
//      * 0x04: Digital mode
//      * 0x07: Analog mode
//      * 0x0F: Escape mode
//
//   This module only implement the Command 0x42.
//
//   Command 0x42 Polling keys:
//      | Byte | BIT0  | BIT1  | BIT2  | BIT3  | BIT4  | BIT5  | BIT6  | BIT7  |
//      |------|-------|-------|-------|-------|-------|-------|-------|-------|
//      |  01  | SEL   | JOYR  | JOYL  | START | UP    | RIGHT | DOWN  | LEFT  |
//      |  02  | L2    | R2    | L1    | L1    | TRIAN | CIRCL | CROSS | SQUAR |
//      |  03  | Right Joystick X       0x00 = Left      0xFF = Right          |
//      |  04  | Right Joystick Y       0x00 = Up        0xFF = Down           |
//      |  05  | Left Joystick X        0x00 = Left      0xFF = Right          |
//      |  06  | Left Joystick Y        0x00 = Up        0xFF = Down           |
//
//   Command 0x44 Set major mode (Digital/ Analog)
//      | Byte | TX                          | RX         |
//      |------|-----------------------------|------------|
//      |  01  | 01 - Analog / 00 - Digital  | 00         |
//      |  02  | 03                          | 00         |
//      |  03  | 00                          | 00         |  
//      |  04  | 00                          | 00         |  
//      |  05  | 00                          | 00         |  
//      |  06  | 00                          | 00         |           
//
//  12 / 2024 Stefan Voss mode configuration analog / digital added
//
//////////////////////////////////////////////////////////////////////////////////
module dualshock2(
    input clk,
    input rst,
    input vsync, // Vsync, should be high active, read back happen during Vsync
    input ds2_dat,
    output reg ds2_cmd,
    output reg ds2_att,
    output reg ds2_clk,
    input ds2_ack,
    input analog,  // select analog left stick or digital DPad mode
    output [7:0] stick_lx,
    output [7:0] stick_ly,
    output [7:0] stick_rx,
    output [7:0] stick_ry,
    output key_up,
    output key_down,
    output key_left,
    output key_right,
    output key_l1,
    output key_l2,
    output key_r1,
    output key_r2,
    output key_triangle,
    output key_square,
    output key_circle,
    output key_cross,
    output key_start,
    output key_select,
    output key_lstick,
    output key_rstick,
    //debug
    output [7:0] debug1,
    output [7:0] debug2
    );

    // states of FSM
    localparam [2:0]    FSM_DIGITAL     = 3'd0,
                        FSM_ANALOG      = 3'd1,
                        FSM_POLLING     = 3'd2,
                        FSM_CFG_EXIT    = 3'd3,
                        FSM_WAIT4CHANGE = 3'd4,
                        FSM_DS2CFG      = 3'd5,
                        FSM_CFG_ENTER   = 3'd6,
                        FSM_DS2CFG_ALL  = 3'd7;

    localparam S_IDLE      = 5'd0;
    localparam S_ATT       = 5'd1;
    localparam S_TX        = 5'd2;
    localparam S_RX        = 5'd3;
    localparam S_EOB       = 5'd4;
    localparam S_ACK_L     = 5'd5;
    localparam S_ACK_H     = 5'd6;
    localparam S_END       = 5'd7;
    localparam S_ERR       = 5'd8;
    
    localparam STATUS_OK   = 2'd0;
    localparam STATUS_ERR  = 2'd1;
    localparam STATUS_TR   = 2'd2;
    
    localparam T_ATT       = 5'd4;  // Wait 2 clocks before start
    localparam T_BITS      = 5'd8;  // Word size: 8 bits
    localparam T_TIMEOUT   = 5'd31; // Timeout for ACK
    localparam T_CD        = 5'd8;  // Cool down before next byte
    
    localparam LENGTH      = 4'd9;  // Transfer size should always be 9 bytes
    

    reg [4:0] state;
    reg [4:0] next_state;
    reg [4:0] state_counter; // Delta clock counter
    
    reg [3:0] bytes_count; // Bytes count
    reg [3:0] bits_count; // Bits count
    reg [7:0] tx_buffer [0:8]; // TX buffer, constant
    reg [7:0] rx_buffer [0:8]; // RX buffer
    reg [7:0] rx_byte;
    reg [1:0] status;
    reg ready = 1'b0;

    reg last_vsync = 1'b0;
    reg mode = 1'b0;
    reg [11:0] core_wait_cnt = 12'd0;
    reg [2:0] io_state;
    reg analog_d;
    reg [8:0] clk_cnt;
    reg clk_spi;

    assign debug1 = rx_buffer[3];
    assign debug2 = rx_buffer[4];
    
    wire [7:0] rx_b0 = rx_buffer[3];
    wire [7:0] rx_b1 = rx_buffer[4];
    wire [7:0] rx_b2 = rx_buffer[5];
    wire [7:0] rx_b3 = rx_buffer[6];
    wire [7:0] rx_b4 = rx_buffer[7];
    wire [7:0] rx_b5 = rx_buffer[8];
    
    assign key_select  = ~rx_b0[0] && ready;
    assign key_rstick  = ~rx_b0[1];
    assign key_lstick  = ~rx_b0[2];
    assign key_start   = ~rx_b0[3] && ready;
    assign key_up      = ~rx_b0[4];
    assign key_right   = ~rx_b0[5];
    assign key_down    = ~rx_b0[6];
    assign key_left    = ~rx_b0[7];
    assign key_l2      = ~rx_b1[0];
    assign key_r2      = ~rx_b1[1];
    assign key_l1      = ~rx_b1[2];
    assign key_r1      = ~rx_b1[3];
    assign key_triangle= ~rx_b1[4] && ready;
    assign key_circle  = ~rx_b1[5] && ready;
    assign key_cross   = ~rx_b1[6] && ready;
    assign key_square  = ~rx_b1[7] && ready;
    assign stick_rx    = ~rx_b2;
    assign stick_ry    = ~rx_b3;
    assign stick_lx    = ~rx_b4;
    assign stick_ly    = ~rx_b5;
    
    `define SYSTEM_CLOCK 28800000


    always @(posedge clk or posedge rst)
    if(rst) begin
        clk_cnt <= 9'd0;
        clk_spi <= 1'b0;
        end 
    else begin
        if(clk_cnt < `SYSTEM_CLOCK / 125000 / 2 -1)
            clk_cnt <= clk_cnt + 9'd1;
        else begin
            clk_cnt <= 9'd0;
            clk_spi <= ~clk_spi;
        end
    end

    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:
                if ((last_vsync == 0)&&(vsync == 1)) next_state = S_ATT;
            S_ATT:
                if (state_counter == T_ATT) next_state = S_TX;
            S_TX:
                next_state = S_RX;
            S_RX:
                if (bits_count == 4'd7) next_state = S_EOB; else next_state = S_TX;
            S_EOB:
                if (bytes_count == LENGTH) next_state = S_END; else next_state = S_ACK_L;
            S_ACK_L:
                if (ds2_ack == 1'b0) 
                   next_state = S_ACK_H; 
                else if (state_counter == T_TIMEOUT) 
                    next_state = S_ERR;
            S_ACK_H:
             // if ((ds2_ack == 1'b1)&&(state_counter == T_CD)) next_state = S_TX;
                if (state_counter == T_CD) next_state = S_TX;
            S_END:
                next_state = S_IDLE;
            S_ERR:
                next_state = S_IDLE;//Error recovery
        endcase
    end

    always @(posedge clk_spi or posedge rst)
        if (rst) begin
            state <= S_IDLE;
            state_counter <= 5'd0;
            last_vsync <= 1'b0;
        end
        else begin
            last_vsync <= vsync;
            state <= next_state;
            if (state != next_state)
                state_counter <= 5'd0;
            else
                state_counter <= state_counter + 1'b1;
        end

    always @(posedge clk_spi or posedge rst)
	if(rst) begin
        tx_buffer[0] <= 8'h01; 
        tx_buffer[1] <= 8'h42; // Polling cmd 01 42 00 00 00 00 00 00 00
        tx_buffer[2] <= 8'h00; // Buttons(L D R U St R3 L3 Se □ X O △ R1 L1 R2 L2)
        tx_buffer[3] <= 8'h00; // Axes(RX RY LX LY)
        tx_buffer[4] <= 8'h00; // Buttons are active low
        tx_buffer[5] <= 8'h00;
        tx_buffer[6] <= 8'h00;
        tx_buffer[7] <= 8'h00;
        tx_buffer[8] <= 8'h00;

        io_state <= FSM_DS2CFG;
        core_wait_cnt <= 12'd0;
        ready <= 1'b0;
    end
    else begin
        analog_d <= analog;

        case(io_state)
            FSM_DS2CFG_ALL:
                begin
                    // Dualshock2: Set ReplyProtocol
                    // Digital buttons + analog sticks
                    // TX: 01h 4fh 00h 3Fh 00h 00h 00h 00h 00h
                    // Digital buttons
                    // TX: 01h 4fh 00h 03h 00h 00h 00h 00h 00h
                    // Enable all 18 input bytes
                    // TX: 01h 4fh 00h FFh FFh 03h 00h 00h 00h
                    if(state == S_IDLE) begin
                        tx_buffer[0] <= 8'h01;
                        tx_buffer[1] <= 8'h4f;
                        tx_buffer[2] <= 8'h00;
                        tx_buffer[3] <= 8'h03; // cfg value 1
                        tx_buffer[4] <= 8'h00; // cfg value 2
                        tx_buffer[5] <= 8'h00; // cfg value 3
                        tx_buffer[6] <= 8'h00;
                        tx_buffer[7] <= 8'h00;
                        tx_buffer[8] <= 8'h00;

                        core_wait_cnt <= core_wait_cnt + 1'd1;
                        if(&core_wait_cnt) begin
                                core_wait_cnt <= 12'd0;
                                io_state <= FSM_CFG_EXIT; // cfg exit
                        end
                    end
                end
            FSM_DS2CFG:
                    if(state == S_IDLE) begin
                        begin
                            core_wait_cnt <= core_wait_cnt + 1'd1;
                            if(&core_wait_cnt) begin
                                if (analog)
                                    mode <= 1'b1; 
                                else 
                                    mode <= 1'b0;
                                io_state <= FSM_CFG_ENTER;
                                core_wait_cnt <= 12'd0;
                            end
                        end
                    end
            FSM_WAIT4CHANGE:
                begin
                    ready <= 1'b1;
                    if(analog != analog_d) begin
                        if (analog) 
                            mode <= 1'b1; 
                         else 
                            mode <= 1'b0;
                        io_state <= FSM_CFG_ENTER;
                        core_wait_cnt <= 12'd0;
                    end 
                end
            FSM_CFG_ENTER:
                begin
                    ready <= 1'b0;
                    // 0x43 Config mode cmd ENTER
                    // TX: 01 43 00 01 00 00 00 00 00  enter cfg
                    if(state == S_IDLE) begin
                        tx_buffer[0] <= 8'h01; 
                        tx_buffer[1] <= 8'h43; // control cmd cfg
                        tx_buffer[2] <= 8'h00; 
                        tx_buffer[3] <= 8'h01; // configure FSM_CFG_ENTER
                        tx_buffer[4] <= 8'h00;
                        tx_buffer[5] <= 8'h00;
                        tx_buffer[6] <= 8'h00;
                        tx_buffer[7] <= 8'h00;
                        tx_buffer[8] <= 8'h00;

                        core_wait_cnt <= core_wait_cnt + 1'd1;
                        if(&core_wait_cnt && mode) begin
                            core_wait_cnt <= 12'd0;
                            io_state <= FSM_ANALOG; // analog
                        end 
                        else if (&core_wait_cnt && ~mode) begin
                            core_wait_cnt <= 12'd0;
                            io_state <= FSM_DIGITAL; // digital
                //          io_state <= FSM_DS2CFG_ALL; // digital buttons alternative
                        end
                    end
                end
            FSM_DIGITAL:
                begin
                    // 0x44 Enable analog cmd
                    // Require to be in config mode
                    // TX: 01 44 00 00 03 00 00 00 00  digital
                    // digital mode
                    if(state == S_IDLE) begin
                        tx_buffer[0] <= 8'h01; 
                        tx_buffer[1] <= 8'h44; // control cmd
                        tx_buffer[2] <= 8'h00; 
                        tx_buffer[3] <= 8'h00;  // digital mode
                        tx_buffer[4] <= 8'h03;  // lock key
                        tx_buffer[5] <= 8'h00;
                        tx_buffer[6] <= 8'h00;
                        tx_buffer[7] <= 8'h00;
                        tx_buffer[8] <= 8'h00;

                        core_wait_cnt <= core_wait_cnt + 1'd1;
                        if(&core_wait_cnt) begin
                                core_wait_cnt <= 12'd0;
                                io_state <= FSM_CFG_EXIT; // cfg exit
                        end
                    end
                end
            FSM_ANALOG: 
                begin
                    // analog mode
                    // TX: 01 44 00 01 03 00 00 00 00  analog
                    if(state == S_IDLE) begin
                        tx_buffer[0] <= 8'h01; 
                        tx_buffer[1] <= 8'h44; // control cmd 
                        tx_buffer[2] <= 8'h00; 
                        tx_buffer[3] <= 8'h01; // analog mode
                        tx_buffer[4] <= 8'h03; // lock key
                        tx_buffer[5] <= 8'h00;
                        tx_buffer[6] <= 8'h00;
                        tx_buffer[7] <= 8'h00;
                        tx_buffer[8] <= 8'h00;

                        core_wait_cnt <= core_wait_cnt + 1'd1;
                        if(&core_wait_cnt) begin
                                core_wait_cnt <= 12'd0;
                                io_state <= FSM_CFG_EXIT; // cfg exit
                        end
                    end
                end
            FSM_CFG_EXIT: 
                begin

                    // 0x43 Config mode cmd EXIT
                    // TX: 01 43 00 00 5A 5A 5A 5A 5A  exit cfg
                    if(state == S_IDLE) begin
                        tx_buffer[0] <= 8'h01; 
                        tx_buffer[1] <= 8'h43; // control cmd cfg
                        tx_buffer[2] <= 8'h00; 
                        tx_buffer[3] <= 8'h00; // configure exit
                        tx_buffer[4] <= 8'h5A;
                        tx_buffer[5] <= 8'h5A;
                        tx_buffer[6] <= 8'h5A;
                        tx_buffer[7] <= 8'h5A;
                        tx_buffer[8] <= 8'h5A;

                        core_wait_cnt <= core_wait_cnt + 1'd1;
                        if(&core_wait_cnt) begin
                                core_wait_cnt <= 12'd0;
                                io_state <= FSM_POLLING;  // polling
                        end
                    end
                end
            FSM_POLLING:
                begin
                    // Polling
                    if(state == S_IDLE) begin
                        tx_buffer[0] <= 8'h01; 
                        tx_buffer[1] <= 8'h42; // Polling cmd 01 42 00 00 00 00 00 00 00
                        tx_buffer[2] <= 8'h00; // Buttons(L D R U St R3 L3 Se □ X O △ R1 L1 R2 L2)
                        tx_buffer[3] <= 8'h00; // Axes(RX RY LX LY)
                        tx_buffer[4] <= 8'h00; // Buttons are active low
                        tx_buffer[5] <= 8'h00;
                        tx_buffer[6] <= 8'h00;
                        tx_buffer[7] <= 8'h00;
                        tx_buffer[8] <= 8'h00;
                        core_wait_cnt <= core_wait_cnt + 1'd1;
                        if(&core_wait_cnt) begin
                                core_wait_cnt <= 12'd0;
                                io_state <= FSM_WAIT4CHANGE; // wait for mode change
                        end
                    end
                end
            default: ;
        endcase
    end //  else: if(rst)
    
    always @(posedge clk_spi or posedge rst)
        if (rst) begin
            bytes_count <= 4'd0;
            bits_count <= 4'd0;
            rx_byte <= 8'hff;
            status <= STATUS_OK;
            ds2_clk <= 1'b1;
            ds2_att <= 1'b1;
            ds2_cmd <= 1'b1;
        end
        else begin
            case (state)
                S_ATT:
                    ds2_att <= 1'b0;
                S_TX: begin
                    ds2_clk <= 1'b0;
                    ds2_cmd <= tx_buffer[bytes_count][bits_count];
                end
                S_RX: begin
                    ds2_clk <= 1'b1;
                    rx_byte[bits_count] <= ds2_dat;
                    bits_count <= bits_count + 1'b1;
                end
                S_EOB: begin
                    bytes_count <= bytes_count + 1'b1;
                    bits_count <= 4'd0;
                    rx_buffer[bytes_count] <= rx_byte;
                end
                //nothing to do for S_ACK_L and S_ACK_H
                S_END: begin
                    bytes_count <= 4'd0;
                    bits_count <= 4'd0;
                    status <= STATUS_OK;
                    ds2_att <= 1'b1;
                end
                S_ERR: begin
                    // Error happens, restart from 0x42
                    bytes_count <= 4'd0;
                    bits_count <= 4'd0;
                    status <= STATUS_ERR;
                    ds2_att <= 1'b1;
                end
            endcase 
        end

endmodule
