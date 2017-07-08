
`timescale 1 ns / 1 ns 
module restoration(
   // Outputs
  
   // Inputs
	clk,
	reset_n,
	Restorated_Pulse,
	Pulser_Trigger_Request,
	Pulse_Measurement_Done,
	Pulse_Propagation_Counter,
	Pulser_IC_Error
   );
	
output reg Pulse_Measurement_Done;
output reg [15:0] Pulse_Propagation_Counter;
	
input clk;
input reset_n;
input Restorated_Pulse;
input Pulser_Trigger_Request;
input Pulser_IC_Error;

reg Pulse_Counter_Enable;

reg Pulser_Trigger_Request_d;
reg Pulser_Trigger_Request_dd;
reg Pulser_Trigger_Request_der;

reg Restorated_Pulse_d;
reg Restorated_Pulse_dd;
reg Restorated_Pulse_der;		

always @ (posedge clk or negedge reset_n)
begin
	if(!reset_n) begin  
		Pulser_Trigger_Request_d <= 1'b0;
		Pulser_Trigger_Request_dd <= 1'b0;
		Pulser_Trigger_Request_der <= 1'b0;			
	end 
	else begin
		Pulser_Trigger_Request_d <= Pulser_Trigger_Request;
		Pulser_Trigger_Request_dd <= Pulser_Trigger_Request_d;
		Pulser_Trigger_Request_der <= (~Pulser_Trigger_Request_dd) && Pulser_Trigger_Request_d;
	end
end

always @ (posedge clk or negedge reset_n)
begin
	if(!reset_n) begin  
		Restorated_Pulse_d <= 1'b0;
		Restorated_Pulse_dd <= 1'b0;
		Restorated_Pulse_der <= 1'b0;			
	end 
	else begin
		Restorated_Pulse_d <= Restorated_Pulse;
		Restorated_Pulse_dd <= Restorated_Pulse_d;
		Restorated_Pulse_der <= (~Restorated_Pulse_dd) && Restorated_Pulse_d;
	end
end		

always @ (posedge clk or negedge reset_n)
begin
  if (!reset_n) 
	begin
		Pulse_Propagation_Counter <= 16'h0;	
		Pulse_Counter_Enable <= 1'b0;
		Pulse_Measurement_Done <= 1'b0;
	end
  else 
	begin
		if (Pulser_Trigger_Request_der) 
			begin 
				Pulse_Propagation_Counter <= 16'h0;	
				Pulse_Counter_Enable <= 1'b1;
				Pulse_Measurement_Done <= 1'b0;	
			end
		else if (Pulser_IC_Error)
			begin
				Pulse_Counter_Enable <= 1'b0;
				Pulse_Measurement_Done <= 1'b0;
				Pulse_Propagation_Counter <= 16'h0;	
			end
		else if (Restorated_Pulse_der) 
			begin
				Pulse_Counter_Enable <= 1'b0;
				Pulse_Measurement_Done <= 1'b1;
			end
		
		if (Pulse_Counter_Enable) Pulse_Propagation_Counter <= Pulse_Propagation_Counter + 16'h1;

	end  		
end			

endmodule
