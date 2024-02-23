
module c1541_flux
(
	input        clk,
	input        pause,
	input        ce, // ntscMode

	output       p2_h_r,
	output       p2_h_f,
    output       clk_1M_pulse
);

reg drive_ce;
always @(posedge clk) begin
	int sum;
	int msum;
	msum <= ce ? 32940000 : 31500000;
	drive_ce <= 0;
	sum = sum + 16000000;
	if(sum >= msum) begin
		sum = sum - msum;
		drive_ce <= 1;
	end
end

reg ph2_r;
reg ph2_f;
always @(posedge clk) begin
	reg [3:0] div;
	reg ena, ena1;

	ena1 <= ~pause;
	if(div[2:0]) ena <= ena1;

	ph2_r <= 0;
	ph2_f <= 0;

	if(drive_ce) begin
		div <= div + 1'd1;
		ph2_r <= ena && !div[3] && !div[2:0];
		ph2_f <= ena &&  div[3] && !div[2:0];
	end
end

assign p2_h_r = ph2_r;
assign p2_h_f = ph2_f;
assign clk_1M_pulse = ph2_f;

endmodule
