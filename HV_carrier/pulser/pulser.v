
`timescale 1 ns / 1 ns 
module pulser(
   // Outputs
  
   // Inputs
	clk,
	reset_n,
	Pulser_Enable_Out,
	Pulse_Control_Out,
	Pulser_Set_Out,
	Tissue_Temperature_Measure,
	Pulser_IC_Error,
	Reset_All_Errors,
	Out_Pulse_Measure
   );
	
output reg Pulser_Enable_Out;
output reg Pulse_Control_Out;
output reg Pulser_Set_Out;
output reg Pulser_IC_Error;
	
input clk;
input reset_n;	
input Tissue_Temperature_Measure;
input Reset_All_Errors;
input Out_Pulse_Measure;

reg [11:0] Pulse_Width_Counter;
reg [2:0] state;
reg Tissue_Temperature_Measure_d;
reg Tissue_Temperature_Measure_dd;
reg Tissue_Temperature_Measure_der;

parameter Pulse_High_Duration = 12'h3; // 200nS
parameter Pulse_Low_Duration = 12'h960; // 100uS

parameter IDLE = 3'h0, PULSE_WIDTH_DELAY = 3'h1, PULSE_PERIOD_DELAY = 3'h2, DELAY_ONE_CLOCK = 3'h3, VALIDATE_PULSE_OUT = 3'h4;

always @ (posedge clk or negedge reset_n)
begin
	if(!reset_n) begin  
		Tissue_Temperature_Measure_d <= 1'b0;
		Tissue_Temperature_Measure_dd <= 1'b0;
		Tissue_Temperature_Measure_der <= 1'b0;			
	end 
	else begin
		Tissue_Temperature_Measure_d <= Tissue_Temperature_Measure;
		Tissue_Temperature_Measure_dd <= Tissue_Temperature_Measure_d;
		Tissue_Temperature_Measure_der <= (~Tissue_Temperature_Measure_dd) && Tissue_Temperature_Measure_d;
	end
end		

always @ (posedge clk or negedge reset_n)
begin
	if(!reset_n) begin
		Pulse_Width_Counter <= 12'h0;	
		Pulser_Enable_Out <= 1'b0;
		state <= IDLE;
		Pulse_Control_Out <= 1'b0;	
		Pulser_Set_Out <= 1'b0;		
		Pulser_IC_Error <= 1'b0;
	end 
	else begin
		if (Reset_All_Errors) begin Pulser_IC_Error <= 1'b0; end
		case(state) 
			IDLE: 	        
				begin
					if ((Tissue_Temperature_Measure_der) && (!Pulser_IC_Error))
						begin
							Pulse_Control_Out <= 1'b1;
							state <= DELAY_ONE_CLOCK;
						end
					Pulser_Enable_Out <= 1'b1;
					Pulse_Width_Counter <= 12'h0;
					Pulser_Set_Out <= 1'b1;		
				end
				
			DELAY_ONE_CLOCK: 	        
				begin
					Pulse_Width_Counter <= Pulse_Width_Counter + 12'h1;
					state <= VALIDATE_PULSE_OUT;
				end
			
			VALIDATE_PULSE_OUT: 	        
				begin
					if (Out_Pulse_Measure) 
						begin 
							Pulse_Width_Counter <= Pulse_Width_Counter + 12'h1;
							state <= PULSE_WIDTH_DELAY; 
						end
					else 
						begin
							Pulser_IC_Error <= 1'b1;
							state <= IDLE;
						end
				end

			PULSE_WIDTH_DELAY:  	        
				begin
					if (Pulse_Width_Counter == Pulse_High_Duration)
						begin
							state <= PULSE_PERIOD_DELAY;
							Pulse_Control_Out <= 1'b0;
						end
					else begin Pulse_Width_Counter <= Pulse_Width_Counter + 12'h1; end
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
