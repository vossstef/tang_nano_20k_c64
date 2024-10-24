`timescale 1ns/1ns
module WS2812 #
(
	parameter clk_freq = 50_000_000,	//20ns
	parameter fps = 60,
	parameter used_led  = 1,
	parameter independent_led_ctrl = "true"
)(
	input sys_clk,
	input rst_n,
	output Do,
	/* LED Input Interface, Sync to sys_clk */
	input  [7:0] pixel_addr,
	input  [7:0] pixel_Red,
	input  [7:0] pixel_Green,
	input  [7:0] pixel_Blue,
	input  pixel_valid,
	output TE
);

	/* LED Memory */
	reg [23:0] led_mem[used_led-1:0];
	reg [7:0] for_var;
	always@(posedge sys_clk or negedge rst_n)
	begin
		if(!rst_n)
		begin
			for(for_var=0; for_var<used_led; for_var=for_var+1)
			begin
				led_mem[for_var] <= 24'd0;
			end
		end else begin
			if(pixel_valid)
			begin
				if(independent_led_ctrl == "true")
				begin
					if(pixel_addr < used_led)
					begin
						led_mem[pixel_addr] <= {pixel_Green, pixel_Red, pixel_Blue};
					end
				end else begin
					for(for_var = 0; for_var < used_led; for_var = for_var+1)
					begin
						led_mem[for_var] <= {pixel_Green, pixel_Red, pixel_Blue};
					end
				end
				
			end
		end
	end

	/*           1 Code									0 Code
	 *	     __________		   _____			   ______			   _______
	 * _____|          |______|				______|		 |____________|
	 *      |<-------->|<---->|					  |<---->|<---------->|
	 *			 T1H      T0L						T0H			T0L
	 *			0.85us   0.4us						0.4us		0.85us
	 *
	 *   One code duration: T0H + T0L = 1.25us +- 600ns
	 *   Reset Code: keep low for tReset(>50us)
	 *
	 *	Data: G7-G0, R7-R0, B7-B0 MSB, GRB
	 */

	localparam cnt_H = clk_freq / 1_176_470;
	localparam cnt_L = clk_freq / 2_500_000;
	localparam cnt_dur = cnt_H + cnt_L;	//bit clk cnt
	localparam cnt_1frame = clk_freq / fps;

	reg [31:0] frame_cnt;
	reg ws2812_proging;
	reg load_led;

	reg [23:0] led_data;		//Temp Memory
	reg [23:0] latch_led_data;	//Shift Memory
	reg [15:0] timing_cnt;			//Timing Gen
	reg [4:0]  led_bit_cnt;			//WS2812 Bit
	reg [7:0] led_num_cnt;			//Current LED Number


	reg tearing_effect;
	assign TE = tearing_effect;

	reg data_out;
	assign Do = data_out;

	/* LED data Latch */
	always@(posedge sys_clk or negedge rst_n)
	begin
		if(!rst_n)
		begin
			led_data <= 24'd0;
		end else begin
			if(load_led)
			begin
				if(led_num_cnt >= used_led)
				begin
					led_data <= led_data;
				end else begin
					led_data <= led_mem[led_num_cnt];
				end
			end else begin
				led_data <= led_data;
			end
		end
	end

	/* bit cnt Generate and data latch,shift */
	always@(posedge sys_clk or negedge rst_n)
	begin
		if(!rst_n)
		begin
			frame_cnt <= 0;
			ws2812_proging <= 0;
			load_led <= 1;
			tearing_effect <= 0;

			timing_cnt <= 16'b0;
			led_bit_cnt <= 5'd0;
			led_num_cnt <= 8'd0;
			latch_led_data <= 24'd0;
		end else begin	
			if(frame_cnt >= cnt_1frame - 1)
			begin
				frame_cnt <= 0;
			end else begin
				frame_cnt <= frame_cnt + 1;
			end

			/* Preload Led data */
			if(frame_cnt >= cnt_1frame - 1)
			begin
				load_led <= 1;
			end else begin
				if(led_bit_cnt == 5'd22 && timing_cnt == cnt_dur)
				begin
					load_led <= 1;
				end else begin
					load_led <= 0;
				end
			end
			

			if(ws2812_proging)	
			begin
				/* 1 Bit Send Complete */
				if(timing_cnt == cnt_dur)	//1bit timeout
				begin
					timing_cnt <= 0;	//Reset to bit start time

					/* 1 LED (24bit) send complete */
					if(led_bit_cnt == 5'd23)
					begin
						led_bit_cnt <= 5'd0;
						/* All led data send out, generate reset to inform WS2812 wait for new transmission */
						if(led_num_cnt == used_led - 1)	
						begin
							tearing_effect <= 1;
							latch_led_data <= 0;
							led_num_cnt <= 0;
							ws2812_proging <= 0;	//to reset state
						end else begin
							tearing_effect <= 0;
							latch_led_data <= led_data;
							led_num_cnt <= led_num_cnt + 1'b1;
							ws2812_proging <= 1;
						end
					end else begin
						led_bit_cnt <= led_bit_cnt + 1'b1;
						//Shift latched led data in each bit send complete
						latch_led_data <= {latch_led_data[22:0], 1'b0};
						tearing_effect <= 0;
						led_num_cnt <= led_num_cnt;
						ws2812_proging <= 1;
					end

				end else begin
					timing_cnt <= timing_cnt + 1;
					led_bit_cnt <= led_bit_cnt;
					load_led <= 0;
					latch_led_data <= latch_led_data;
					tearing_effect <= 0;
					led_num_cnt <= led_num_cnt;
					ws2812_proging <= 1;
				end

			end else begin	//Wait for new write
				if(frame_cnt == 0)
				begin
					timing_cnt <= 0;
					led_bit_cnt <= 0;
					load_led <= 0;
					latch_led_data <= led_data;
					tearing_effect <= 0;
					led_num_cnt <= 0;
					ws2812_proging <= 1;
				end else begin
					timing_cnt <= 0;
					led_bit_cnt <= 0;
					load_led <= 0;
					latch_led_data <= 0;
					tearing_effect <= 0;
					led_num_cnt <= 0;
					ws2812_proging <= 0;
				end
			end
		end
	end
	
	/* Data shift */
	always@(posedge sys_clk or negedge rst_n)
	begin
		if(!rst_n)
		begin
			data_out <= 1'b0;
		end else begin
			if(ws2812_proging)
			begin
				if(latch_led_data[23] == 1'b1)
				begin
					if(timing_cnt < cnt_H - 1)
					begin
						data_out <= 1'b1;
					end else begin
						data_out <= 1'b0;
					end
				end else begin
					if(timing_cnt < cnt_L - 1)
					begin
						data_out <= 1'b1;
					end else begin
						data_out <= 1'b0;
					end
				end
			end else begin
				data_out <= 1'b0;
			end
		end
	end

	

endmodule
	