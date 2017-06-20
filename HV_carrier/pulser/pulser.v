
`timescale 1 ns / 1 ns 
module pulser(
   // Outputs
  
   // Inputs
	clk,
	reset_n,
	Pulser_Enable_Out,
	Pulse_Control_Out,
	Pulser_Set_Out
   );
	
output reg Pulser_Enable_Out;
output reg Pulse_Control_Out;
output reg Pulser_Set_Out;
	
input clk;
input reset_n;	

reg [11:0] Pulse_Width_Counter;
reg [2:0] state;

parameter Pulse_High_Duration = 12'h3; // 200nS
parameter Pulse_Low_Duration = 12'h960; // 100uS

parameter IDLE = 3'h0, PULSE_WIDTH_DELAY = 3'h1, PULSE_PERIOD_DELAY = 3'h2;

always @ (posedge clk or negedge reset_n)
begin
	if(!reset_n) begin
		Pulse_Width_Counter <= 12'h0;	
		Pulser_Enable_Out <= 1'b0;
		state <= IDLE;
		Pulse_Control_Out <= 1'b0;	
		Pulser_Set_Out <= 1'b0;		
	end 
	else begin
		case(state) 
			IDLE: 	        
				begin
					Pulser_Enable_Out <= 1'b1;
					Pulse_Control_Out <= 1'b1;
					Pulser_Set_Out <= 1'b1;	
					state <= PULSE_WIDTH_DELAY;
				end

			PULSE_WIDTH_DELAY:  	        
				begin
					if (Pulse_Width_Counter == Pulse_High_Duration)
						begin
							state <= PULSE_PERIOD_DELAY;
							Pulse_Control_Out <= 1'b0;
						end
					else 
						Pulse_Width_Counter <= Pulse_Width_Counter + 12'h1;
				end
			
			PULSE_PERIOD_DELAY:  	        
				begin
					if (Pulse_Width_Counter == Pulse_Low_Duration)
						begin
							state <= IDLE;
							Pulse_Control_Out <= 1'b0;
							Pulse_Width_Counter <= 12'h0;
						end
					else 
						Pulse_Width_Counter <= Pulse_Width_Counter + 12'h1;
				end

			default:
				begin
					
				end
		endcase
	end
end		
endmodule
