// Copyright (C) 1991-2005 Altera Corporation
// Your use of Altera Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic       
// functions, and any output files any of the foregoing           
// (including device programming or simulation files), and any    
// associated documentation or information are expressly subject  
// to the terms and conditions of the Altera Program License      
// Subscription Agreement, Altera MegaCore Function License       
// Agreement, or other applicable license agreement, including,   
// without limitation, that your use is for the sole purpose of   
// programming logic devices manufactured by Altera and sold by   
// Altera or its authorized distributors.  Please refer to the    
// applicable agreement for further details.

// synopsys translate_off
`timescale 1ns/1ns
// synopsys translate_on 
module top( 
	// Outputs
	
	output wire wd_stp,
	output wire SPI_Bus_DOUT,
//	output wire clk_408MHz,
	output wire clk_24mhz_out,
	output wire Pulser_Trigger_Out,
	output wire Pulse_Measurement_Done,
	output wire Pulser_Enable_Out,
	output wire Pulse_Control_Out,
	output wire Pulser_Set_Out,
	output wire Main_Busy_Signal,
	output wire [15:0] Amplifier_Switches_Activation,
	output reg Global_Interrupt_Signal,
	output reg Test_LED1,
	
	// Inputs
	
	input clk_24mhz, 
	input Restorated_Pulse_In,
	input reset_n,
	input SPI_Bus_CS,
	input SPI_Bus_CLK,
	input SPI_Bus_DIN,
	input Amplifier_Temperature_Status,
	input Amplifier_Reverse_Power1_Status,
	input Amplifier_Reverse_Power2_Status,
	input P12v_Supply_Status,
	input P24v_Supply_Status,
	input P48v_Supply_Status,
	input PC_Communication_Status,
	input Tissue_Temperature_Measure,
	input Out_Pulse_Measure,				
	input Power_Button_Status,
	input Emergency_Button_Status,
	input HP_Connection_Status,
	input HP_Switch_NC1_Trigger_Status,
	input HP_Switch_NC2_Trigger_Status,
	input Expander_A_Port_A_Interrupt_Status,
	input Expander_A_Port_B_Interrupt_Status,			
	input Expander_B_Port_A_Interrupt_Status,
	input Expander_B_Port_B_Interrupt_Status,
	input Start_Amplifier_Switches_Cnf_Frame,
	input Amplifier_Switches_Strobe,
	input Amplifier_Switches_State,
	input [3:0] Amplifier_Switches_Data
   );
	
wire locked;
wire SPI_Transaction_Completed;
wire [7:0] Received_SPI_Data;
wire [7:0] Write_To_SPI;
wire Addressn_Data;
wire Command_Format_Error;
wire Switch_Arbiter_Error;
wire Command_Format_Interrupt;
wire Command_Encoding_Interrupt;
wire Interface_Signal_Interrupt;
wire Summarized_Interrupt_Signal;
wire [15:0] Tissue_Temperature_Value;
wire Reset_All_Errors;
wire Pulser_IC_Error;
wire rst_n_sync_24MHz;
wire rst_n_sync_408MHz;
wire clk_408MHz;

reg [7:0] Interrupt_High_Time;
reg [23:0] LED_Time_Counter;

assign Pulser_Trigger_Out = Pulse_Control_Out; // SAMPLE PULSER CONTROL
assign Main_Busy_Signal = Register_Load_Busy || SPI_Transaction_Completed;
assign Summarized_Interrupt_Signal = Command_Encoding_Interrupt || Command_Format_Interrupt || Interface_Signal_Interrupt;

parameter Interrupt_Signal_Width = 8'h64;
parameter LED_On_Time = 24'hB71B00; // 0.5SEC

always @ (posedge clk_24mhz_out or negedge rst_n_sync_24MHz) // MONOSTABLE MULTIVIBRATOR FOR EXPANSION INTERRUPT SIGNAL WIDTH
begin
  if (!rst_n_sync_24MHz) begin
		LED_Time_Counter <= 24'h0;
		Test_LED1 <= 1'b0;
	end
  else begin
		if (LED_Time_Counter < LED_On_Time)
			begin
				LED_Time_Counter <= LED_Time_Counter + 8'h1;
			end
		else
			begin
				Test_LED1 <= ~Test_LED1;
				LED_Time_Counter <= 24'h0;
			end
	end
end

always @ (posedge clk_24mhz_out or negedge rst_n_sync_24MHz) // MONOSTABLE MULTIVIBRATOR FOR EXPANSION INTERRUPT SIGNAL WIDTH
begin
  if (!rst_n_sync_24MHz) begin
		Global_Interrupt_Signal <= 1'b0;
		Interrupt_High_Time <= 8'h0;
	end
  else begin
		if (Summarized_Interrupt_Signal)
			begin
				if (Interrupt_High_Time < Interrupt_Signal_Width)
					begin
						Interrupt_High_Time <= Interrupt_High_Time + 8'h1;
						Global_Interrupt_Signal <= 1'b1;
					end
				else
					begin
						Global_Interrupt_Signal <= 1'b0;
					end
			end
		else
			begin
				if ((Interrupt_High_Time > 8'h0) && (Interrupt_High_Time < Interrupt_Signal_Width))
					begin
						Interrupt_High_Time <= Interrupt_High_Time + 8'h1;
						Global_Interrupt_Signal <= 1'b1;
					end
				else
					begin
						Interrupt_High_Time <= 8'h0;
						Global_Interrupt_Signal <= 1'b0;
					end
			end
	end
end

adc_pll	adc_pll_inst (
	.inclk0 (clk_24mhz),
	.c0 (clk_24mhz_out),
	.c1 (clk_408MHz),
	.locked(locked)
	);

sync sync_c(
   // Outputs
	.rst_n_sync_24MHz(rst_n_sync_24MHz),
	.rst_n_sync_408MHz(rst_n_sync_408MHz),
   // Inputs
	.clk_408MHz(clk_408MHz),
	.clk_24MHz(clk_24mhz_out),
	.rst_n(reset_n)
   ) ;
	
pulser pulser_inst (
	.clk (clk_24mhz_out),
	.reset_n (rst_n_sync_24MHz),
	.Pulser_Enable_Out(Pulser_Enable_Out),
	.Pulse_Control_Out(Pulse_Control_Out),
	.Pulser_Set_Out(Pulser_Set_Out),
	.Tissue_Temperature_Measure(Tissue_Temperature_Measure),
	.Reset_All_Errors(Reset_All_Errors),
	.Pulser_IC_Error(Pulser_IC_Error),
	.Out_Pulse_Measure(Out_Pulse_Measure)
	);
	
restoration	restoration_inst (
	.clk (clk_408MHz),
	.reset_n (rst_n_sync_408MHz),
	.Restorated_Pulse(Restorated_Pulse_In),
	.Pulser_Trigger_Request(Pulse_Control_Out),
	.Pulse_Measurement_Done(Pulse_Measurement_Done),
	.Pulse_Propagation_Counter(Tissue_Temperature_Value),
	.Pulser_IC_Error(Pulser_IC_Error)
	);
	
Amplifier_Switch_Arbiter Amplifier_Switch_Arbiter_inst (
	.clk (clk_24mhz_out),
	.reset_n (rst_n_sync_24MHz),
	.Start_Amplifier_Switches_Cnf_Frame(Start_Amplifier_Switches_Cnf_Frame),
	.Amplifier_Switches_Strobe(Amplifier_Switches_Strobe),
	.Amplifier_Switches_State(Amplifier_Switches_State),
	.Amplifier_Switches_Data(Amplifier_Switches_Data),
	.Amplifier_Switches_Activation(Amplifier_Switches_Activation),
	.Switch_Arbiter_Error(Switch_Arbiter_Error),
	.Reset_All_Errors(Reset_All_Errors)	
	);
	
System_Data_Parser Data_Parser(	
	.reset_n(rst_n_sync_24MHz),
	.clk(clk_24mhz_out),
	.TxD_data(Write_To_SPI),
	.RxD_data(Received_SPI_Data),
	.SPI_data_ready(~SPI_Transaction_Completed), 
	.Addressn_Data(Addressn_Data),
	.Command_Format_Error(Command_Format_Error),
	.Switch_Arbiter_Error(Switch_Arbiter_Error),
	.Command_Encoding_Interrupt(Command_Encoding_Interrupt),
	.Interface_Signal_Interrupt(Interface_Signal_Interrupt),
	.Reset_All_Errors(Reset_All_Errors),	
	.Register_Load_Busy(Register_Load_Busy),
	.Tissue_Temperature_Value(Tissue_Temperature_Value),	
	
	.Amplifier_Temperature_Status(Amplifier_Temperature_Status),
	.Amplifier_Reverse_Power1_Status(Amplifier_Reverse_Power1_Status),
	.Amplifier_Reverse_Power2_Status(Amplifier_Reverse_Power2_Status),
	.P12v_Supply_Status(P12v_Supply_Status),
	.P24v_Supply_Status(P24v_Supply_Status),
	.P48v_Supply_Status(P48v_Supply_Status),
	.PC_Communication_Status(PC_Communication_Status),
	.Pulser_IC_Status(Pulser_IC_Error),				
	.Power_Button_Status(Power_Button_Status),
	.Emergency_Button_Status(Emergency_Button_Status),
	.HP_Connection_Status(HP_Connection_Status),
	.HP_Switch_NC1_Trigger_Status(HP_Switch_NC1_Trigger_Status),
	.HP_Switch_NC2_Trigger_Status(HP_Switch_NC2_Trigger_Status),
	.Expander_A_Port_A_Interrupt_Status(Expander_A_Port_A_Interrupt_Status),
	.Expander_A_Port_B_Interrupt_Status(Expander_A_Port_B_Interrupt_Status),			
	.Expander_B_Port_A_Interrupt_Status(Expander_B_Port_A_Interrupt_Status),
	.Expander_B_Port_B_Interrupt_Status(Expander_B_Port_B_Interrupt_Status)
	
	);
	
msc_slave_spi SPI_Slave_Inst (
	.clk (clk_24mhz_out),
	.rstb (rst_n_sync_24MHz),
	.xfer_len(4'h8),//
	.wr_data(Write_To_SPI),
	.busy(SPI_Transaction_Completed),
	.rd_data(Received_SPI_Data),
	.spi_csb(SPI_Bus_CS),
	.spi_clk(SPI_Bus_CLK),
	.spi_din(SPI_Bus_DIN),
	.spi_dout(SPI_Bus_DOUT),
	.Addressn_Data(Addressn_Data),
	.Command_Format_Error(Command_Format_Error),
	.Command_Format_Interrupt(Command_Format_Interrupt),
	.Command_Encoding_Interrupt(Command_Encoding_Interrupt),
	.Reset_All_Errors(Reset_All_Errors)	
	);

watchdog_counter watchdog_counter_c(
   // Outputs
   .wd_stp(wd_stp), 
   // Inputs
   .adc_clk(clk_24mhz_out), 
   .rst_n(rst_n_sync_24MHz));

endmodule 

