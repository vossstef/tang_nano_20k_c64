module uclockdiv (
	// System clocks / reset / settings
	input wire CLK,
    input wire RESET_N,
	output reg CLK_6551_EN
);

reg     [7:0]  CLK_6551;
// Targeting 3.686.400Hz clock enable derived
// 63.0 Mhz / 17

always @(negedge CLK or negedge RESET_N)
begin
    if(!RESET_N)
	begin
        CLK_6551 <= 8'd0;
		CLK_6551_EN <= 1'b0;
	end
    else
	begin
		CLK_6551_EN <= 1'b0;
        case(CLK_6551)
        5'd30:
		begin
			CLK_6551_EN <= 1'b1;
            CLK_6551 <= 8'd0;
		end
        default:
            CLK_6551 <= CLK_6551 + 1'b1;
        endcase
	end
end

endmodule