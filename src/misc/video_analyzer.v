//
// video_analyzer.v
//
// try to derive video parameters from hs/vs/de
//

module video_analyzer 
(
 // system interface
 input		  clk,
 input		  hs,
 input		  vs,
 input		  de,
 input		  ntscmode,

 output reg[1:0] mode, // 0=ntsc, 1=pal, 2=mono
 output reg	  vreset
);
   

// generate a reset signal in the upper left corner of active video used
// to synchonize the HDMI video generation to the Atari ST
reg vsD, hsD;
reg [13:0] hcnt;    // signal ranges 0..2047
reg [13:0] hcntL;
reg [9:0] vcnt;    // signal ranges 0..313
reg [9:0] vcntL;
reg changed;

always @(posedge clk) begin
    // ---- hsync processing -----
    hsD <= hs;
    mode <= {1'b0 , ~ntscmode}; // 0=ntsc, 1=pal, 2=mono

    // begin of hsync, falling edge
    if(!hs && hsD) begin
        // check if line length has changed during last cycle
        hcntL <= hcnt;
        if(hcntL != hcnt)
            changed <= 1'b1;

        hcnt <= 0;
    end else
        hcnt <= hcnt + 14'd1;

    if(!hs && hsD) begin
       // ---- vsync processing -----
       vsD <= vs;
       // begin of vsync, falling edge
       if(!vs && vsD) begin
          // check if image height has changed during last cycle
          vcntL <= vcnt;
          if(vcntL != vcnt) changed <= 1'b1;
          vcnt <= 0;  
       end else
         vcnt <= vcnt + 10'd1;
    end

   // the reset signal is sent to the HDMI generator. On reset the
   // HDMI re-adjusts its counters to the start of the visible screen area
   vreset <= 1'b0;
   if( 
       (hcnt == 1 && vcnt == 20 && changed && mode == 2'd1) ||
       (hcnt == 1 && vcnt == 10 && changed && mode == 2'd0) ) begin
       vreset <= 1'b1;
       changed <= 1'b0;
   end
end

endmodule
