//
// Slave SPI interface, shared between multiple devices.
//

`timescale  1 ps / 1 ps

module SPI(
          rstb,               // active low asynch reset
          clk,                // master synch clock
          xfer_len,           // transfer length in bits
          rdy,                // previous transfer finished
          rd_data,            // transfer read result 
          spi_csb,            // SPI CSbar outputs
          spi_clk,            // SPI clock output 
          spi_din,            // SPI data input (peripheral output) 
          spi_dout,           // SPI data output (peripheral input)
			 wr_data
       );
 
input  rstb; 
input  clk;
input  [3:0] xfer_len;        // min 2, max 16
output reg rdy; 
output reg[7:0] rd_data;        // MSBs padded with 0 if xfer_len < 16
input  spi_csb;
input  spi_clk;
input  spi_din; 
input [7:0] wr_data;     
output spi_dout;       


///////////////////////////////////////////////////////////////////////////////
// Continuously sample spi_din.  The sample that is actually used will
// depend on sample_pt.

reg spi_din_s, spi_din_s1;
reg spi_clk_s, spi_clk_s1, spi_clk_s2, spi_clk_der;
reg spi_csb_s, spi_csb_s1;

reg [7:0] wr_data_d;
reg [7:0] wr_data_dd;
reg [7:0] wr_data_ddd;

always @ (posedge clk or negedge rstb)
begin
	if(!rstb) begin  
		wr_data_d <= 8'h0;
		wr_data_dd <= 8'h0;
		wr_data_ddd <= 8'h0;			
	end 
	else begin
		wr_data_d <= wr_data;
		wr_data_dd <= wr_data_d;
		wr_data_ddd <= wr_data_dd;
	end
end

always @ (posedge clk or negedge rstb)
begin
	if(!rstb) begin  
		spi_din_s1 <= 1'b0;
		spi_din_s <= 1'b0;		
	end 
	else begin
      spi_din_s1 <= spi_din;
		spi_din_s <= spi_din_s1;
   end
end

always @ (posedge clk or negedge rstb)
begin
	if(!rstb) begin  
		spi_clk_s1 <= 1'b0;
		spi_clk_s2 <= 1'b0;
		spi_clk_s <= 1'b0;	
		spi_clk_der <= 1'b0;
	end 
	else begin
      spi_clk_s1 <= spi_clk;
		spi_clk_s2 <= spi_clk_s1;
		spi_clk_s <= spi_clk_s2;
		spi_clk_der <= spi_clk_s2 & (~spi_clk_s);
   end
end

always @ (posedge clk or negedge rstb)
begin
	if(!rstb) begin  
		spi_csb_s1 <= 1'b0;
		spi_csb_s <= 1'b0;		
	end 
	else begin
      spi_csb_s1 <= spi_csb;
		spi_csb_s <= spi_csb_s1;
   end
end

///////////////////////////////////////////////////////////////////////////////
// Read data shift register

reg [23:0] shift_in;
wire din_loopback;
reg [4:0] xfercount;

always @(posedge clk or negedge rstb)
   begin
      if (!rstb) begin
         shift_in <= 8'h0;
         rd_data <= 8'h0;
			xfercount <= 5'h0;
			rdy <= 1'b1;
      end 
		else begin
         if (spi_csb_s) begin
            shift_in <= 8'h0;
				rdy <= 1'b1;
				//xfercount <= 5'h0;
				if (xfercount > 0) begin xfercount <= 5'h0; end
         end 
			else begin
            if (spi_clk_der) begin
               if (xfercount == (xfer_len-1)) begin
                  // End of transfer. Latch a copy of (new) shift register contents.
                  rd_data <= {shift_in[6:0], spi_din_s};
						rdy <= 1'b1;
						xfercount <= 5'h0;
               end
					else begin
						shift_in <= {shift_in[6:0], spi_din_s};
						xfercount <= xfercount + 1;
						rdy <= 1'b0;
					end
            end
         end
      end
   end
   
///////////////////////////////////////////////////////////////////////////////
// Write data shift register

// spi_dout enables data in transfer
//assign spi_dout = shift_out[23];

///////////////////////////////////////////////////////////////////////////////
// Write data shift register

reg [7:0] shift_out;

always @(posedge clk or negedge rstb)
   begin
      if (!rstb) begin
         shift_out <= 8'h0;
      end else begin
         if (spi_csb_s) begin
            // Load data to be written into upper part of shift register 
            shift_out <= wr_data_ddd; 
         end else if (spi_clk_der) begin//
            shift_out <= shift_out << 1;
         end
      end
   end

assign spi_dout = shift_out[7];


///////////////////////////////////////////////////////////////////////////////


	
endmodule