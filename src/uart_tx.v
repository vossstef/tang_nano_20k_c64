module uart_tx
#(
	parameter CLK_FRE = 50,      //clock frequency(Mhz)
	parameter BAUD_RATE = 115200 //serial baud rate
)
(
	input                        clk,              //clock input
	input[19:0]				  	 cycle,        	   //baud counter	
	input                        rst_n,            //asynchronous reset input, low active 
	input[7:0]                   tx_data,          //data to send
	input                        tx_data_valid,    //data to be sent is valid
	output reg                   tx_data_ready,    //send ready
	output                       tx_pin,           //serial data output
	output						 loopback		   //looped back input data
);

//state machine code
localparam                       S_IDLE       = 1;
localparam                       S_START      = 2;//start bit
localparam                       S_SEND_BYTE  = 3;//data bits
localparam                       S_STOP       = 4;//stop bit
reg[2:0]                         state;
reg[2:0]                         next_state;
reg[19:0]                        cycle_cnt; //baud counter
reg[2:0]                         bit_cnt;//bit counter
reg[7:0]                         tx_data_latch; //latch data to send
reg                              tx_reg; //serial data output
reg[7:0]				 		 loopback_reg;

assign tx_pin = tx_reg;
assign loopback = loopback_reg[7];

always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		state <= S_IDLE;
	else
		state <= next_state;
end

always@(*)
begin
	case(state)
		S_IDLE:
			if(tx_data_valid == 1'b1)
				next_state <= S_START;
			else
				next_state <= S_IDLE;
		S_START:
			if(cycle_cnt == 20'd0)
				next_state <= S_SEND_BYTE;
			else
				next_state <= S_START;
		S_SEND_BYTE:
			if(cycle_cnt == 20'd0  && bit_cnt == 3'd7)
				next_state <= S_STOP;
			else
				next_state <= S_SEND_BYTE;
		S_STOP:
			if(cycle_cnt == 20'd0)
				next_state <= S_IDLE;
			else
				next_state <= S_STOP;
		default:
			next_state <= S_IDLE;
	endcase
end
always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		begin
			tx_data_ready <= 1'b0;
		end
	else if(state == S_IDLE)
		if(tx_data_valid == 1'b1)
			tx_data_ready <= 1'b0;
		else
			tx_data_ready <= 1'b1;
	else if(state == S_STOP && cycle_cnt == 20'd0)
			tx_data_ready <= 1'b1;
end


always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		begin
			tx_data_latch <= 8'd0;
		end
	else if(state == S_IDLE && tx_data_valid == 1'b1)
			tx_data_latch <= tx_data;
		
end

always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		begin
			bit_cnt <= 3'd0;
		end
	else if(state == S_SEND_BYTE)
		if(cycle_cnt == 20'd0)
			bit_cnt <= bit_cnt + 3'd1;
		else
			bit_cnt <= bit_cnt;
	else
		bit_cnt <= 3'd0;
end


always@(posedge clk)
begin
	if(rst_n == 1'b0)
		cycle_cnt <= cycle;
	else if((state == S_SEND_BYTE && cycle_cnt == 20'd0) || next_state != state)
		cycle_cnt <= cycle;
	else
		cycle_cnt <= cycle_cnt - 20'd1;	
end

always@(posedge clk or negedge rst_n)
begin
	if(rst_n == 1'b0)
		begin
            tx_reg <= 1'b1;
            loopback_reg <= 8'b11111111;
		end
	else
		case(state)
			S_IDLE,S_STOP:
				begin
					tx_reg <= 1'b1; 
					loopback_reg <= {loopback_reg[6:0], 1'b1};
				end
			S_START:
				begin
					tx_reg <= 1'b0; 
					loopback_reg <= {loopback_reg[6:0], 1'b0};
				end
			S_SEND_BYTE:
				begin
					tx_reg <= tx_data_latch[bit_cnt]; 
					loopback_reg <= {loopback_reg[6:0], tx_data_latch[bit_cnt]};
				end
			default:
				begin
					tx_reg <= 1'b1; 
					loopback_reg <= {loopback_reg[6:0], 1'b1};
				end
		endcase
end

endmodule 