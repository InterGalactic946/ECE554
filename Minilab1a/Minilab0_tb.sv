/////////////////////////////////////////////////////////////
// Minilab0_tb.sv: First-In-First-Out Memory Module        //
//                                                         //
// This module tests the Minilab0 design by simulating its //
// behavior and checking the outputs against expected      //
// values.                                                 //
/////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module Minilab0_tb();

	// System clock.
	logic CLOCK_50;

	//////////// SEG7 //////////
	logic	     [6:0]		HEX0;
	logic	     [6:0]		HEX1;
	logic	     [6:0]		HEX2;
	logic	     [6:0]		HEX3;
	logic	     [6:0]		HEX4;
	logic	     [6:0]		HEX5;
	
	//////////// LED //////////
	logic		     [9:0]		LEDR;

	//////////// KEY //////////
	logic 		     [3:0]		KEY;

	//////////// SW //////////
	logic 		     [9:0]		SW;

	parameter HEX_0 = 7'b1000000;		// zero
	parameter HEX_1 = 7'b1111001;		// one
	parameter HEX_2 = 7'b0100100;		// two
	parameter HEX_3 = 7'b0110000;		// three
	parameter HEX_4 = 7'b0011001;		// four
	parameter HEX_5 = 7'b0010010;		// five
	parameter HEX_6 = 7'b0000010;		// six
	parameter HEX_7 = 7'b1111000;		// seven
	parameter HEX_8 = 7'b0000000;		// eight
	parameter HEX_9 = 7'b0011000;		// nine
	parameter HEX_10 = 7'b0001000;		// ten
	parameter HEX_11 = 7'b0000011;		// eleven
	parameter HEX_12 = 7'b1000110;		// twelve
	parameter HEX_13 = 7'b0100001;		// thirteen
	parameter HEX_14 = 7'b0000110;		// fourteen
	parameter HEX_15 = 7'b0001110;		// fifteen
	parameter OFF    = 7'b1111111;		// all off

	// Error flag
	logic error;

	// Instantiate the Minilab0 design under test (DUT).
	Minilab0 iDUT(.CLOCK_50(CLOCK_50), 
				.CLOCK2_50(1'b0),
				.CLOCK3_50(1'b0),
				.CLOCK4_50(1'b0),
				.HEX0(HEX0),
				.HEX1(HEX1),
				.HEX2(HEX2),
				.HEX3(HEX3),
				.HEX4(HEX4),
				.HEX5(HEX5),
				.SW(SW),
				.KEY(KEY),
				.LEDR(LEDR));


	initial begin
		// Initialize inputs.
		CLOCK_50 = 1'b0;
		KEY = 4'h0;
		SW = 10'h000;
		error = 1'b0;

		// Wait for the first clock cycle to assert reset
		@(posedge CLOCK_50);
		
		// Assert reset
		@(negedge CLOCK_50) KEY = 1'b0;

		// Deassert reset and start testing.
		@(negedge CLOCK_50) KEY = 1'b1;

		// Check that the HEX displays are all off.

		if ( HEX0 != OFF ) begin
			$error("ERROR First Digit Expecting: 7'b%b, Actual: 7'b%b", OFF, HEX0);
			error = 1'b1;
		end

		if ( HEX1 != OFF ) begin
			$error("ERROR Second Digit Expecting: 7'b%b, Actual: 7'b%b", OFF, HEX1);
			error = 1'b1;
		end

		if ( HEX2 != OFF ) begin
			$error("ERROR Third Digit Expecting: 7'b%b, Actual: 7'b%b", OFF, HEX2);
			error = 1'b1;
		end

		if ( HEX3 != OFF ) begin
			$error("ERROR Fourth Digit Expecting: 7'b%b, Actual: 7'b%b", OFF, HEX3);
			error = 1'b1;
		end

		if ( HEX4 != OFF ) begin
			$error("ERROR Fifth Digit Expecting: 7'b%b, Actual: 7'b%b", OFF, HEX4);
			error = 1'b1;
		end

		if ( HEX5 != OFF ) begin
			$error("ERROR Sixth Digit Expecting: 7'b%b, Actual: 7'b%b", OFF, HEX5);
			error = 1'b1;
		end

		// Activate the switch to display the result of the MAC operation.
		SW = 10'h001;

		// Wait for a few clock cycles.
		repeat(5) @(negedge CLOCK_50);

		// wait for DONE state
		@(posedge LEDR[1]);

		// Wait for a few more clock cycles to ensure the outputs are stable.
		repeat(100) @(negedge CLOCK_50);

		// Check the HEX display outputs against expected values.
		if ( HEX0 != HEX_8 ) begin
			$error("ERROR First Digit Expecting: 7'b%b, Actual: 7'b%b", HEX_8, HEX0);
			error = 1'b1;
		end

		if ( HEX1 != HEX_5 ) begin
			$error("ERROR Second Digit Expecting: 7'b%b, Actual: 7'b%b", HEX_5, HEX1);
			error = 1'b1;
		end

		if ( HEX2 != HEX_11 ) begin
			$error("ERROR Third Digit Expecting: 7'b%b, Actual: 7'b%b", HEX_11, HEX2);
			error = 1'b1;
		end

		if ( HEX3 != HEX_1 ) begin
			$error("ERROR Fourth Digit Expecting: 7'b%b, Actual: 7'b%b", HEX_1, HEX3);
			error = 1'b1;
		end

		if ( HEX4 != HEX_0 ) begin
			$error("ERROR Fifth Digit Expecting: 7'b%b, Actual: 7'b%b", HEX_0, HEX4);
			error = 1'b1;
		end

		if ( HEX5 != HEX_0 ) begin
			$error("ERROR Sixth Digit Expecting: 7'b%b, Actual: 7'b%b", HEX_0, HEX5);
			error = 1'b1;
		end

		// If no errors, print success message.
		if (!error) begin
	  		$display("YAHOO!! All tests passed!");
		end
		
		$stop();
	end

	// Clock generation: 25 MHz clock with a period of 10 ns.
	always 
		#5 CLOCK_50 = ~CLOCK_50;

endmodule