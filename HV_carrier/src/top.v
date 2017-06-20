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
	
	// Inputs
	
	input clk_24mhz, 
	input Restorated_Pulse_In,
	input reset_n,
	input SPI_Bus_CS,
	input SPI_Bus_CLK,
	input SPI_Bus_DIN
	
   );
   
wire locked;
wire SPI_Transaction_Completed;
wire [7:0] Received_SPI_Data;
wire [7:0] Write_To_SPI;
wire rst_n_sync_24MHz;
wire rst_n_sync_408MHz;

assign Pulser_Trigger_Out = Pulse_Control_Out; // SAMPLE PULSER CONTROL

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
	.reset_n (reset_n),
	.Pulser_Enable_Out(Pulser_Enable_Out),
	.Pulse_Control_Out(Pulse_Control_Out),
	.Pulser_Set_Out(Pulser_Set_Out)
	);
	
restoration	restoration_inst (
	.clk (clk_408MHz),
	.reset_n (reset_n),
	.Restorated_Pulse(Restorated_Pulse_In),
	.Pulser_Trigger_Request(Pulse_Control_Out),
	.Pulse_Measurement_Done(Pulse_Measurement_Done)
	);
	
SPI SPI_Slave_Inst (
	.clk (clk_24mhz_out),
	.rstb (reset_n),
	.xfer_len(4'h8),
	.wr_data(Write_To_SPI),
	.rdy(SPI_Transaction_Completed),
	.rd_data(Received_SPI_Data),
	.spi_csb(SPI_Bus_CS),
	.spi_clk(SPI_Bus_CLK),
	.spi_din(SPI_Bus_DIN),
	.spi_dout(SPI_Bus_DOUT)
	);

watchdog_counter watchdog_counter_c(
   // Outputs
   .wd_stp(wd_stp), 
   // Inputs
   .adc_clk(clk_24mhz_out), 
   .rst_n(reset_n));

endmodule 

