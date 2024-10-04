////////////////////////////////////////////////////////////////////////////////
// Project Name:	CoCo3FPGA Version 4.0
// File Name:		6551tx.v
//
// CoCo3 in an FPGA
//
// Revision: 4.0 07/10/16
////////////////////////////////////////////////////////////////////////////////
//
// CPU section copyrighted by John Kent
// The FDC co-processor copyrighted Daniel Wallner.
// SDRAM Controller copyrighted by XESS Corp.
//
////////////////////////////////////////////////////////////////////////////////
//
// Color Computer 3 compatible system on a chip
//
// Version : 4.0
//
// Copyright (c) 2008 Gary Becker (gary_l_becker@yahoo.com)
//
// All rights reserved
//
// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// Redistributions in synthesized form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.
//
// Neither the name of the author nor the names of other contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
//
// Please report bugs to the author, but before you do so, please
// make sure that this is not a derivative work and that
// you have the latest version of this file.
//
// The latest version of this file can be found at:
//      http://groups.yahoo.com/group/CoCo3FPGA
//
// File history :
//
//  1.0			Full Release
//  2.0			Partial Release
//  3.0			Full Release
//  3.0.0.1		Update to fix DoD interrupt issue
//	3.0.1.0		Update to fix 32/40 CoCO3 Text issue and add 2 Meg max memory
//	4.0.X.X		Full Release
////////////////////////////////////////////////////////////////////////////////
// Gary Becker
// gary_L_becker@yahoo.com
////////////////////////////////////////////////////////////////////////////////

module uart51_tx(
RESET_N,
CLK,
BAUD_CLK,
TX_DATA,
TX_START,
TX_DONE,
TX_STOP,
TX_WORD,
TX_PAR_DIS,
TX_PARITY,
CTS,
TX_BUFFER
);

input					RESET_N;
input					CLK;
input					BAUD_CLK;
output				TX_DATA;
reg					TX_DATA;
input					TX_START;
output				TX_DONE;
reg					TX_DONE;
input					TX_STOP;
input		[1:0]		TX_WORD;
input					TX_PAR_DIS;
input		[1:0]		TX_PARITY;
input					CTS;
input		[7:0]		TX_BUFFER;

reg		[6:0]		STATE;
reg		[2:0]		BIT;
wire					PARITY;
reg					TX_START0;
reg					TX_START1;

assign PARITY =	(~TX_PARITY[1]

					&	((TX_BUFFER[0] ^ TX_BUFFER[1])
					^	 (TX_BUFFER[2] ^ TX_BUFFER[3]))

					^	 (TX_BUFFER[4]
					^   (TX_BUFFER[5] & (TX_WORD != 2'b00)))

					^  ((TX_BUFFER[6] & (TX_WORD[1] == 1'b1))
					^   (TX_BUFFER[7] & (TX_WORD == 2'b11)))) // clear bit #8 if only 7 bits

					^	  ~TX_PARITY[0];

always @ (negedge CLK or negedge RESET_N)
begin
	if(!RESET_N)
	begin
		STATE <= 7'b0000000;
		TX_DATA <= 1'b1;
		TX_DONE <= 1'b1;
		BIT <= 3'b000;
		TX_START0 <= 1'b0;
		TX_START1 <= 1'b0;
	end
	else
	begin
		if (BAUD_CLK)
		begin
			TX_START0 <= TX_START;
			TX_START1 <= TX_START0;
			case (STATE)
			7'b0000000:
			begin
				BIT <= 3'b000;
				TX_DATA <= 1'b1;
				if(TX_START1 == 1'b1)
				begin
					TX_DONE <= 1'b0;
					STATE <= 7'b0000001;
				end
			end
			7'b0000001:									// Start bit
			begin
				TX_DATA <= 1'b0;
				STATE <= 7'b0000010;
			end
			7'b0010001:
			begin
				TX_DATA <= TX_BUFFER[BIT];
				STATE <= 7'b0010010;
			end
			7'b0100000:
			begin
				BIT <= BIT + 1'b1;
				if((TX_WORD == 2'b00) && (BIT != 3'b111))
				begin
					STATE <= 7'b0010001;
				end
				else
				begin
					if((TX_WORD == 2'b01) && (BIT != 3'b110))
					begin
						STATE <= 7'b0010001;
					end
					else
					begin
						if((TX_WORD == 2'b10) && (BIT != 3'b101))
						begin
							STATE <= 7'b0010001;
						end
						else
						begin
							if((TX_WORD == 2'b11) && (BIT != 3'b100))
							begin
								STATE <= 7'b0010001;
							end
							else
							begin
								if(!TX_PAR_DIS)
								begin
									STATE <= 7'b0100001;				// do parity
								end
								else
								begin
									STATE <= 7'b0110001;				// do stop
								end
							end
						end
					end
				end
			end
// Start parity bit
			7'b0100001:
			begin
				TX_DATA <= PARITY;
				STATE <= 7'b0100010;
			end
// start stop
			7'b0110001:
			begin
				TX_DONE <= 1'b1;
				TX_DATA <= 1'b1;
				STATE <= 7'b0110010;
			end
// end of first stop bit-1
			7'b0111111:
			begin
				if(!TX_STOP)
					STATE <= 7'b1001111;						// go check for CTS
				else
					STATE <= 7'b1000000;
			end
			7'b1001111:
			begin
				if(!CTS)								// this is not correct for a 6551
				begin
					STATE <= 7'b0000000;
				end
			end
			default:
				STATE <= STATE + 1'b1;
			endcase
		end
	end
end
endmodule
