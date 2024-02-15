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
reg vsD, hsD, deD;
reg [12:0] hcnt;    // signal ranges 0..2047
reg [12:0] hcntL;
reg [9:0] vcnt;    // signal ranges 0..313
reg [9:0] vcntL;
reg changed;

always @(posedge clk) begin
    // ---- hsync processing -----
    hsD <= hs;
    deD <= de;
    mode <= {1'b0 , ~ntscmode}; // 0=ntsc, 1=pal, 2=mono

    // begin of hsync, falling edge
    if(!hs && hsD) begin
        // check if line length has changed during last cycle
        hcntL <= hcnt;
        if(hcntL != hcnt)
            changed <= 1'b1;

        hcnt <= 0;
    end else
        hcnt <= hcnt + 13'd1;

    if(!hs && hsD) begin
       // ---- vsync processing -----
       vsD <= vs;
       // begin of vsync, falling edge
       if(!vs && vsD) begin
          // check if image height has changed during last cycle
          vcntL <= vcnt;
          if(vcntL != vcnt)
             changed <= 1'b1;

          vcnt <= 0;
	  // check for PAL/NTSC values
//	  if(vcnt == 10'd312 && hcntL == 13'd2047) mode <= 2'd2;  // PAL @ hozizontal width 1024 (832x576)
//	  if(vcnt == 10'd312 && hcntL == 13'd1727) mode <= 2'd1;  // PAL @ hozizontal width 864  (720x576)
//	  if(vcnt == 10'd262 && hcntL == 13'd2031) mode <= 2'd0;  // NTSC

	  // check for MONO
//	  if(vcnt == 10'd500 && hcntL == 13'd895)  mode <= 2'd2;  // MONO
	  
       end else
         vcnt <= vcnt + 10'd1;
    end

   // the reset signal is sent to the HDMI generator. On reset the
   // HDMI re-adjusts its counters to the start of the visible screen
   // area
   
   vreset <= 1'b0;
   // account for back porches to adjust image position within the
   // HDMI frame
//   if( (hcnt == 244 && vcnt == 36 && changed && mode == 2'd2) ||
//       (hcnt == 152 && vcnt == 28 && changed && mode == 2'd1) ||
//       (hcnt == 152 && vcnt == 18 && changed && mode == 2'd0) ) begin
   if
      ((hcnt == 68 && vcnt == 39 && changed && ntscmode == 1'd0) || // c64 core PAL  720x576
       (hcnt == 60 && vcnt == 30 && changed && ntscmode == 1'd1))   // c64 core NTSC 720x480
         begin
            vreset <= 1'b1;
            changed <= 1'b0;
   end
end
//assign  mode = {1'b0 , ~ntscmode}; // 0=ntsc, 1=pal, 2=mono

endmodule

// Modeline "720x576 @ 50hz"  27    720   732   796   864   576   581   586   625 31.25khz
// Hcnt is set to 0 on the trailing edge of hsync from core so the H constants below need to be offset by 864-796=68
// Vcnt is set to 0 on the trailing edge of vsync from the core so the V constants below need to be offset by 625-586=39

// NTSC 720 480 60 Hz 31.4685 kHz
// ModeLine "720x480" 27.00 720 736 798 858 480 489 495 525 -HSync -VSync 
// Hcnt 858 - 798 = 60
// Vcnt 525 - 495 = 30
