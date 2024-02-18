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
reg vsD2, hsD2;
reg [12:0] hcnt;    // signal ranges 0..2047
reg [12:0] hcntL;
reg [9:0] vcnt;    // signal ranges 0..313
reg [9:0] vcntL;
reg changed;

always @(posedge clk) begin
    // ---- hsync processing -----
    hsD <= hs;
    hsD2 <= hsD;
    mode <= {1'b0 , ~ntscmode}; // 0=ntsc, 1=pal, 2=mono

    // begin of hsync, falling edge
    if(!hsD && hsD2) begin
        // check if line length has changed during last cycle
        hcntL <= hcnt;
        if(hcntL != hcnt)
            changed <= 1'b1;

        hcnt <= 0;
    end else
        hcnt <= hcnt + 13'd1;

    if(!hsD && hsD2) begin
       // ---- vsync processing -----
       vsD <= vs;
       vsD2 <= vsD;
       // begin of vsync, falling edge
       if(!vsD && vsD2) begin
          // check if image height has changed during last cycle
          vcntL <= vcnt;
          if(vcntL != vcnt)
             changed <= 1'b1;

          vcnt <= 0;  
	  // check for PAL/NTSC values
//	  if(vcnt == 10'd312 && hcntL == 13'd1727) mode <= 2'd1;  // PAL
//	  if(vcnt == 10'd263 && hcntL == 13'd1695) mode <= 2'd0;  // NTSC
       end else
         vcnt <= vcnt + 10'd1;
    end

   // the reset signal is sent to the HDMI generator. On reset the
   // HDMI re-adjusts its counters to the start of the visible screen area
   
   vreset <= 1'b0;
   if( 
       (hcnt == 0 && vcnt == 18 && changed && mode == 2'd1) ||
       (hcnt == 0 && vcnt == 18 && changed && mode == 2'd0) ) begin
        vreset <= 1'b1;
        changed <= 1'b0;
   end
end

endmodule
