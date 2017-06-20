
/////// Synchronized Asynchronous Reset asynchronously asserted and synchronously deasserted////////////

`timescale 1 ns / 1 ns

module sync(
   // Outputs
	rst_n_sync_24MHz,
	rst_n_sync_408MHz,
   // Inputs
	clk_408MHz,
	clk_24MHz,
	rst_n
   ) ;
	
output reg rst_n_sync_24MHz;	
output reg rst_n_sync_408MHz;
input		clk_408MHz;
input		clk_24MHz;
input 	rst_n ;

always @ (posedge clk_408MHz or negedge rst_n) 
begin	
	if (!rst_n) begin
		rst_n_sync_408MHz <= 1'b0;
	end
	else begin
		rst_n_sync_408MHz <= 1'b1;
	end
end

always@(posedge clk_24MHz or negedge rst_n) 
begin	
	if (!rst_n) begin
		rst_n_sync_24MHz <= 1'b0;
	end
	else begin
		rst_n_sync_24MHz <= 1'b1;
	end
end

endmodule

