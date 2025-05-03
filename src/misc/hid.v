/*
    hid.v
 
    hid (keyboard, mouse etc) interface to the IO MCU

    c64 core specific variant of hid
  */

module hid (
  input               clk,
  input               reset,

  input               data_in_strobe,
  input               data_in_start,
  input [7:0]         data_in,
  output reg [7:0]    data_out,

  // input local db9 port events to be sent to MCU
  input  [5:0]        db9_port,
  output reg          irq,
  input               iack,
  input [1:0]         shift_mod,

  // output HID data received from USB
  output reg [7:0]    joystick0,
  output reg [7:0]    joystick1,
  output reg [7:0]    numpad,
  input  [7:0]        keyboard_matrix_out,
  output [7:0]        keyboard_matrix_in,
  output reg          key_restore,
  output reg          tape_play,
  output reg          mod_key,
  output reg [1:0]    mouse_btns,
  output reg [7:0]    mouse_x,
  output reg [7:0]    mouse_y,
  output reg          mouse_strobe,
  output reg [7:0]    joystick0ax,
  output reg [7:0]    joystick0ay,
  output reg [7:0]    joystick1ax,
  output reg [7:0]    joystick1ay,
  output reg          joystick_strobe,
  output reg [7:0]    extra_button0,
  output reg [7:0]    extra_button1
);

reg [7:0] keyboard[7:0]; // array of 8 elements of width 8bit
reg [7:0] keyboard_s[7:0];
reg [7:0] usb_kbd;

assign keyboard_matrix_in =
      (!keyboard_matrix_out[0]?(keyboard[0]& keyboard_s[0]):8'hff)&
      (!keyboard_matrix_out[1]?(keyboard[1]& keyboard_s[1]):8'hff)&
      (!keyboard_matrix_out[2]?(keyboard[2]& keyboard_s[2]):8'hff)&
      (!keyboard_matrix_out[3]?(keyboard[3]& keyboard_s[3]):8'hff)&
      (!keyboard_matrix_out[4]?(keyboard[4]& keyboard_s[4]):8'hff)&
      (!keyboard_matrix_out[5]?(keyboard[5]& keyboard_s[5]):8'hff)&
      (!keyboard_matrix_out[6]?(keyboard[6]& keyboard_s[6]):8'hff)&
      (!keyboard_matrix_out[7]?(keyboard[7]& keyboard_s[7]):8'hff);

reg [3:0] state;
reg [7:0] command;
reg [7:0] device;   // used for joystick
reg irq_enable;
reg [5:0] db9_portD;
reg [5:0] db9_portD2;

// translate incoming HID key codes into C64 key matrix positions
wire [3:0] kbd_row;
wire [2:0] kbd_column;
wire [3:0] kbd_row_s;
wire [2:0] kbd_column_s;

keymap keymap (
       .code   ( data_in[6:0] ),
       .row    ( kbd_row ),
       .column ( kbd_column ),
       .row_s  ( kbd_row_s ),
       .column_s(kbd_column_s ),
       .shift_mod( shift_mod )
);

always @(posedge clk) begin
   if(reset) begin
      numpad <= 8'h00;
   end else begin
    if (usb_kbd[7])
        numpad <= 8'h00;
    else
        numpad <=
        (usb_kbd[6:0] == 7'h5e)?numpad | 8'h01:
        (usb_kbd[6:0] == 7'h5c)?numpad | 8'h02:
        (usb_kbd[6:0] == 7'h5a)?numpad | 8'h04:
        (usb_kbd[6:0] == 7'h60)?numpad | 8'h08:
        (usb_kbd[6:0] == 7'h62)?numpad | 8'h10:
        (usb_kbd[6:0] == 7'h63)?numpad | 8'h20:
        (usb_kbd[6:0] == 7'h44)?numpad | 8'h40:
        (usb_kbd[6:0] == 7'h4b)?numpad | 8'h80:8'h00;
    end
end

assign mod_key = numpad[5];
assign key_restore = numpad[6]; 
assign tape_play = numpad[7];

// process mouse events
always @(posedge clk) begin
   if(reset) begin
      state <= 4'd0;
      mouse_strobe <=1'b0;
      irq <= 1'b0;
      irq_enable <= 1'b0;
      joystick_strobe <= 1'b0; 
      usb_kbd <= 8'h00;

      // reset entire keyboard to 1's
      keyboard[ 0] <= 8'hff; keyboard[ 1] <= 8'hff; keyboard[ 2] <= 8'hff;
      keyboard[ 3] <= 8'hff; keyboard[ 4] <= 8'hff; keyboard[ 5] <= 8'hff;
      keyboard[ 6] <= 8'hff; keyboard[ 7] <= 8'hff; 

      keyboard_s[ 0] <= 8'hff; keyboard_s[ 1] <= 8'hff; keyboard_s[ 2] <= 8'hff;
      keyboard_s[ 3] <= 8'hff; keyboard_s[ 4] <= 8'hff; keyboard_s[ 5] <= 8'hff;
      keyboard_s[ 6] <= 8'hff; keyboard_s[ 7] <= 8'hff; 

   end else begin
      db9_portD <= db9_port;
      db9_portD2 <= db9_portD;

      // monitor db9 port for changes and raise interrupt
      if(irq_enable) begin
        if(db9_portD2 != db9_portD) begin
            // irq_enable prevents further interrupts until
            // the db9 state has actually been read by the MCU
            irq <= 1'b1;
            irq_enable <= 1'b0;
        end
      end

      if(iack) irq <= 1'b0;      // iack clears interrupt

      mouse_strobe <=1'b0;
      joystick_strobe <=1'b0; 
      if(data_in_strobe) begin      
        if(data_in_start) begin
            state <= 4'd0;
            command <= data_in;
        end else begin
            if(state != 4'd15) state <= state + 4'd1;

            // CMD 0: status data
            if(command == 8'd0) begin
                if(state == 4'd0) data_out <= 8'h01;
                if(state == 4'd1) data_out <= 8'h00;
            end

            // CMD 1: keyboard data
            if(command == 8'd1) begin
            // kbd_column and kbd_row are derived from data_in
               if(state == 4'd0) 
                keyboard[kbd_column][kbd_row] <= data_in[7];
                keyboard_s[kbd_column_s][kbd_row_s] <= data_in[7];
                usb_kbd <= data_in;
            end
            // CMD 2: mouse data
            if(command == 8'd2) begin
                if(state == 4'd0) mouse_btns <= data_in[1:0];
                if(state == 4'd1) mouse_x <= data_in;
                if(state == 4'd2) begin
                    mouse_y <= data_in;
                    mouse_strobe <=1'b1;
                end
            end

            // CMD 3: receive digital joystick data
            if(command == 8'd3) begin
                if(state == 4'd0) device <= data_in;
                if(state == 4'd1) begin
                    if(device == 8'd0) joystick0 <= data_in;
                    if(device == 8'd1) joystick1 <= data_in;
                end
                if(state == 4'd2) begin
                        if(device == 8'd0) joystick0ax <= data_in;
                        if(device == 8'd1) joystick1ax <= data_in;
                end
                if(state == 4'd3) begin
                        if(device == 8'd0) joystick0ay <= data_in;
                        if(device == 8'd1) joystick1ay <= data_in;
                end
                if(state == 4'd4) begin
                        if(device == 8'd0) extra_button0 <= data_in;
                        if(device == 8'd1) extra_button1 <= data_in;
                        joystick_strobe <= 1'b1;
                end
            end

            // CMD 4: send digital joystick data to MCU
            if(command == 8'd4) begin
                if(state == 4'd0) irq_enable <= 1'b1;    // (re-)enable interrupt
                data_out <= {2'b00, db9_portD };
            end
        end
      end
   end
end

endmodule
