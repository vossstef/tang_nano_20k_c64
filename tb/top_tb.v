`timescale 1ps / 1ps

module top_tb;

///////////////////////////////////////////////////////////////////////////
// Instantiate the test module
///////////////////////////////////////////////////////////////////////////

reg clk;
reg rst;
reg vsync;
reg ds2_dat;

dualshock2 dut(
    .clk(clk),
    .rst(rst),
    .vsync(vsync),
    .ds2_dat(ds2_dat),
    .ds2_ack(1'b0),

    .ds2_cmd(),
    .ds2_att(),
    .ds2_clk(),
    .stick_lx(),
    .stick_ly(),
    .stick_rx(),
    .stick_ry(),
    .key_up(),
    .key_down(),
    .key_left(),
    .key_right(),
    .key_l1(),
    .key_l2(),
    .key_r1(),
    .key_r2(),
    .key_triangle(),
    .key_square(),
    .key_circle(),
    .key_cross(),
    .key_start(),
    .key_select(),
    .key_lstick(),
    .key_rstick(),
    .debug1(),
    .debug2()
    );

///////////////////////////////////////////////////////////////////////////
// Set everything going
///////////////////////////////////////////////////////////////////////////
initial
  begin
                
         clk = 1'b0;
         rst = 1'b0;
         vsync = 1'b0;
         ds2_dat = 1'b0;

          #20000
          rst <= 1'b1;
          #10000
          rst <= 1'b0;
          #100000000
          $stop;
          end

///////////////////////////////////////////////////////////////////////////
// Toggle the clock indefinitely
///////////////////////////////////////////////////////////////////////////
    always 
    begin
         #17 clk <= ~clk;
    end

    always 
    begin
         #2000000 vsync <= ~vsync;
    end

    always 
    begin
         #4000000 ds2_dat <= ~ds2_dat;
  end


endmodule
