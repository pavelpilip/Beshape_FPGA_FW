//
// Slave SPI interface, shared between multiple devices.
//

`timescale  1 ps / 1 ps

module msc_slave_spi (
          rstb,               // active low asynch reset
          clk,                // master synch clock
          xfer_len,           // transfer length in bits
          busy,                // previous transfer finished
          rd_data,            // transfer read result 
          spi_csb,            // SPI CSbar outputs
          spi_clk,            // SPI clock output 
          spi_din,            // SPI data input (peripheral output) 
          spi_dout,           // SPI data output (peripheral input)
			 wr_data,
			 Addressn_Data,
			 Command_Format_Error,
			 Command_Format_Interrupt,
			 Command_Encoding_Interrupt,
			 Reset_All_Errors
       );
 
input rstb; 
input clk;
input [3:0] xfer_len;        // min 2, max 16
input [7:0] wr_data;   
input spi_csb;
input spi_clk;
input spi_din; 
input Reset_All_Errors;
input Command_Encoding_Interrupt;
 
output reg busy; 
output reg[7:0] rd_data;        // MSBs padded with 0 if xfer_len < 16
output reg Addressn_Data; // RECEIVED DATA IS ADDRESS = "0", DATA = "1"
output reg Command_Format_Error;
output reg Command_Format_Interrupt;
output spi_dout;       

///////////////////////////////////////////////////////////////////////////////
// Continuously sample spi_din.  The sample that is actually used will
// depend on sample_pt.

reg spi_din_s, spi_din_s1;
reg spi_clk_s, spi_clk_s1, spi_clk_s2, spi_clk_der, spi_clk_n_der;
reg spi_csb_s, spi_csb_s1;
reg Transaction_Counter;

always @ (posedge clk or negedge rstb)
begin
	if(!rstb) 
	begin  
		spi_din_s1 <= 1'b0;
		spi_din_s <= 1'b0;		
	end 
	else 
	begin
      spi_din_s1 <= spi_din;
		spi_din_s <= spi_din_s1;
   end
end

always @ (posedge clk or negedge rstb)
begin
	if(!rstb) 
	begin  
		spi_clk_s1 <= 1'b0;
		spi_clk_s2 <= 1'b0;
		spi_clk_s <= 1'b0;	
		spi_clk_der <= 1'b0;
		spi_clk_n_der <= 1'b0;
	end 
	else 
	begin
      spi_clk_s1 <= spi_clk;
		spi_clk_s2 <= spi_clk_s1;
		spi_clk_s <= spi_clk_s2;
		spi_clk_der <= spi_clk_s2 & (~spi_clk_s);
		spi_clk_n_der <= spi_clk_s & (~spi_clk_s2);
   end
end

always @ (posedge clk or negedge rstb)
begin
	if(!rstb) 
	begin  
		spi_csb_s1 <= 1'b0;
		spi_csb_s <= 1'b0;		
	end 
	else 
	begin
      spi_csb_s1 <= spi_csb;
		spi_csb_s <= spi_csb_s1;
   end
end

///////////////////////////////////////////////////////////////////////////////
// Read data shift register

reg [7:0] shift_in;
reg [2:0] xfercount;

always @(posedge clk or negedge rstb)
   begin
      if (!rstb) 
			begin
				shift_in <= 8'h0;
				rd_data <= 8'h0;
				xfercount <= 3'h0;
				busy <= 1'b0;
				Addressn_Data <= 1'b0;
				Transaction_Counter <= 1'b0;
				Command_Format_Error <= 1'b0;
				Command_Format_Interrupt <= 1'b0;
			end 
		else 
			begin
				if (spi_csb_s) 
					begin
						shift_in <= 8'h0;
						busy <= 1'b0;
						if (Reset_All_Errors) begin Command_Format_Error <= 1'b0; end
						if (Command_Encoding_Interrupt)
							begin
								rd_data <= 8'h0;
								xfercount <= 3'h0;
								Addressn_Data <= 1'b0;
								Transaction_Counter <= 1'b0;
							end
						if (xfercount > 0) 
							begin 
								xfercount <= 3'h0;
								Transaction_Counter <= 1'b0;
								Command_Format_Error <= 1'b1;
								Command_Format_Interrupt <= 1'b1;
							end
						else begin Command_Format_Interrupt <= 1'b0; end
					end 
				else 
					begin
						if (spi_clk_der) 
							begin
								if (xfercount == (xfer_len-1)) 
								begin
										// End of transfer. Latch a copy of (new) shift register contents.
									rd_data <= {shift_in[6:0], spi_din_s};
									xfercount <= 3'h0;
									Transaction_Counter <= ~Transaction_Counter;
								end
								else 
									begin
										if (Transaction_Counter) begin Addressn_Data <= 1'b1; end
										else begin Addressn_Data <= 1'b0; end
										shift_in <= {shift_in[6:0], spi_din_s};
										xfercount <= xfercount + 3'h1;
										busy <= 1'b1;
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
      end 
		else begin
         if (spi_csb_s) begin
            // Load data to be written into upper part of shift register 
            shift_out <= wr_data; 
         end 
			else if (spi_clk_n_der) begin//
            shift_out <= shift_out << 1;
         end
      end
   end

assign spi_dout = shift_out[7];


///////////////////////////////////////////////////////////////////////////////


	
endmodule