
`timescale 1 ns / 1 ns

module watchdog_counter(/*AUTOARG*/
   // Outputs
   wd_stp, 
   // Inputs
   adc_clk, rst_n
   ) ;
	
output		wd_stp;		
input		adc_clk;
input 		rst_n ;
reg	[7:0]	wd_counter;
reg			wd_stp;

parameter MAX_CNT = 8'b1111_1010;
//assign		wdog = wd_counter == 32'h1;		

always@(posedge adc_clk or negedge rst_n)
begin	
	if(!rst_n)
		wd_counter 	<= 32'b0;
	else
	begin
		if(wd_counter == MAX_CNT)
			wd_counter <= 8'b0;		
		else
			wd_counter <= wd_counter + 32'b1 ;
	end
end

always @ (posedge adc_clk or negedge rst_n)
begin
  if (!rst_n)
      wd_stp <= 0;
  else if (wd_counter == (MAX_CNT >> 1))
  	    wd_stp <= 1'b1;
  else
		wd_stp <= 1'b0;	
end 

endmodule
// Local Variables:
// verilog-library-directories:("." "../../src" "../megafunction" )
// End:
