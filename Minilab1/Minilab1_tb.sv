/////////////////////////////////////////////////////////////
// Minilab1b_tb.sv: Testbench for Minilab1b Module         //
//                                                         //
// This module verifies the functionality of the M         //
// MatVectMult module by applying a series of test cases   //
// and checking the outputs against expected values.       //
/////////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps

module Minilab1b_tb();
    // System clock signal for the DUT.
	logic clk;

	////////////////// INPUTS ///////////////////////
	logic [3:0] KEY;
	logic [9:0] SW;


	////////////////////// OUTPUTS ////////////////////
	logic [6:0]	HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	logic [9:0] LEDR;

	////////////////// HEX PARAMS ////////////////////
	localparam HEX_0 = 7'b1000000;		// zero
	localparam HEX_1 = 7'b1111001;		// one
	localparam HEX_2 = 7'b0100100;		// two
	localparam HEX_3 = 7'b0110000;		// three
	localparam HEX_4 = 7'b0011001;		// four
	localparam HEX_5 = 7'b0010010;		// five
	localparam HEX_6 = 7'b0000010;		// six
	localparam HEX_7 = 7'b1111000;		// seven
	localparam HEX_8 = 7'b0000000;		// eight
	localparam HEX_9 = 7'b0011000;		// nine
	localparam HEX_10 = 7'b0001000;		// ten
	localparam HEX_11 = 7'b0000011;		// eleven
	localparam HEX_12 = 7'b1000110;		// twelve
	localparam HEX_13 = 7'b0100001;		// thirteen
	localparam HEX_14 = 7'b0000110;		// fourteen
	localparam HEX_15 = 7'b0001110;		// fifteen
	localparam OFF   = 7'b1111111;		// all off

    // Instantiate the DUT.
	Minilab1b iDUT(
		.CLOCK_50(clk),
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
		.LEDR(LEDR)
	);

    // Task to check the HEX display outputs against expected values.
    task automatic hexCheck (input [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, EXP0, EXP1, EXP2, EXP3, EXP4, EXP5);
		begin
			integer error = 0;

			if (HEX0 !== EXP0) begin
                $error("ERROR First Digit Expecting: 7'b%b, Actual: 7'b%b", EXP0, HEX0);
                error = 1;
			end

			if (HEX1 !== EXP1) begin
                $error("ERROR Second Digit Expecting: 7'b%b, Actual: 7'b%b", EXP1, HEX1);
				error = 1;
			end

			if (HEX2 !== EXP2) begin
                $error("ERROR Third Digit Expecting: 7'b%b, Actual: 7'b%b", EXP2, HEX2);
				error = 1;
			end

			if (HEX3 !== EXP3) begin
                $error("ERROR Fourth Digit Expecting: 7'b%b, Actual: 7'b%b", EXP3, HEX3);
				error = 1;
			end

			if (HEX4 !== EXP4) begin
                $error("ERROR Fifth Digit Expecting: 7'b%b, Actual: 7'b%b", EXP4, HEX4);
				error = 1;
			end

			if (HEX5 !== EXP5) begin
                $error("ERROR Sixth Digit Expecting: 7'b%b, Actual: 7'b%b", EXP5, HEX5);
				error = 1;
			end

			if (error == 1) begin
				$stop();
			end
		end
	endtask

	initial begin
        // Initialize inputs.
		clk = 1'b0;
		KEY = 4'b1110; // Assert reset and nothing else.
		SW = 10'h000;

		// Wait for the first clock cycle to assert reset
		@(posedge clk);
		
		// Assert reset
		@(negedge clk) KEY = 4'b1110;

		// Deassert reset and start testing.
		@(negedge clk) KEY = 4'b1111;

        // Check that the HEX displays are all off.
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 OFF, OFF, OFF, OFF, OFF, OFF);

		// Assert start to start the matrix-vector multiplication operation.
		@(negedge clk);
		KEY = 4'b1101;

        // Deassert start.
		@(negedge clk);
		KEY = 4'b1111; 

		// Wait for DONE state
		@(posedge LEDR[2]);

        // Wait a few cycles to ensure outputs are stable.
		repeat(5) @(posedge clk);

		$display("Checking Pre-Clear Test.\n");

        // Check the computed output matrix C values in the DUT.
		if (iDUT.C[0] !== 24'h0012CC) $error("ERROR: C[%0d] = 0x%0h, expected 0x0012CC", 0, iDUT.C[0]);
      	if (iDUT.C[1] !== 24'h00550C) $error("ERROR: C[%0d] = 0x%0h, expected 0x00550C", 1, iDUT.C[1]);
        if (iDUT.C[2] !== 24'h00974C) $error("ERROR: C[%0d] = 0x%0h, expected 0x00974C", 2, iDUT.C[2]);
        if (iDUT.C[3] !== 24'h00D98C) $error("ERROR: C[%0d] = 0x%0h, expected 0x00D98C", 3, iDUT.C[3]);
        if (iDUT.C[4] !== 24'h011BCC) $error("ERROR: C[%0d] = 0x%0h, expected 0x011BCC", 4, iDUT.C[4]);
        if (iDUT.C[5] !== 24'h015E0C) $error("ERROR: C[%0d] = 0x%0h, expected 0x015E0C", 5, iDUT.C[5]);
        if (iDUT.C[6] !== 24'h01A04C) $error("ERROR: C[%0d] = 0x%0h, expected 0x01A04C", 6, iDUT.C[6]);
        if (iDUT.C[7] !== 24'h01E28C) $error("ERROR: C[%0d] = 0x%0h, expected 0x01E28C", 7, iDUT.C[7]);

		// check first digit
		SW = 10'h008;
		$display("Checking first digit of i.e., C[0].");

		@(posedge clk)
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 HEX_12, HEX_12, HEX_2, HEX_1, HEX_0, HEX_0);

		// check second digit
		SW = 10'h009;
		$display("Checking first digit of i.e., C[1].");

		@(posedge clk)
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 HEX_12, HEX_0, HEX_5, HEX_5, HEX_0, HEX_0);

		// check third digit
		SW = 10'h00A;
		$display("Checking first digit of i.e., C[2].");

		@(posedge clk)
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 HEX_12, HEX_4, HEX_7, HEX_9, HEX_0, HEX_0);

		// check fourth digit
		SW = 10'h00B;
		$display("Checking first digit of i.e., C[3].");

		@(posedge clk)
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 HEX_12, HEX_8, HEX_9, HEX_13, HEX_0, HEX_0);

		// check fifth digit
		SW = 10'h00C;
		$display("Checking first digit of i.e., C[4].");

		@(posedge clk)
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 HEX_12, HEX_12, HEX_11, HEX_1, HEX_1, HEX_0);

		// check sixth digit
		SW = 10'h00D;
		$display("Checking first digit of i.e., C[5].");

		@(posedge clk)
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 HEX_12, HEX_0, HEX_14, HEX_5, HEX_1, HEX_0);

		// check seventh digit
		SW = 10'h00E;
		$display("Checking first digit of i.e., C[6].");

		@(posedge clk)
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 HEX_12, HEX_4, HEX_0, HEX_10, HEX_1, HEX_0);

		// check eigth digit
		SW = 10'h00F;
		$display("Checking first digit of i.e., C[7].");

		@(posedge clk)
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 HEX_12, HEX_8, HEX_2, HEX_14, HEX_1, HEX_0);
		
		// Assert CLR to clear the DUT for another operation.
		@(negedge clk) KEY = 4'b1011;

		// Deassert CLR.
		@(negedge clk) KEY = 4'b1111;

		// Wait a few cycles to ensure outputs are stable.
		repeat(5) @(posedge clk);

		// Check that the HEX displays are all off again.
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 OFF, OFF, OFF, OFF, OFF, OFF);
		
		// Repeat the matrix-vector multiplication operation test.
		// Assert start to start the matrix-vector multiplication operation.
		@(negedge clk) KEY = 4'b1101;

		// Deassert start.
		@(negedge clk) KEY = 4'b1111;

		// Wait for DONE state
		@(posedge LEDR[2]);

        // Wait a few cycles to ensure outputs are stable.
		repeat(5) @(posedge clk);

		$display("\nChecking Post-Clear Test.\n");

        // Check the computed output matrix C values in the DUT.
		if (iDUT.C[0] !== 24'h0012CC) $error("ERROR: C[%0d] = 0x%0h, expected 0x0012CC", 0, iDUT.C[0]);
      	if (iDUT.C[1] !== 24'h00550C) $error("ERROR: C[%0d] = 0x%0h, expected 0x00550C", 1, iDUT.C[1]);
        if (iDUT.C[2] !== 24'h00974C) $error("ERROR: C[%0d] = 0x%0h, expected 0x00974C", 2, iDUT.C[2]);
        if (iDUT.C[3] !== 24'h00D98C) $error("ERROR: C[%0d] = 0x%0h, expected 0x00D98C", 3, iDUT.C[3]);
        if (iDUT.C[4] !== 24'h011BCC) $error("ERROR: C[%0d] = 0x%0h, expected 0x011BCC", 4, iDUT.C[4]);
        if (iDUT.C[5] !== 24'h015E0C) $error("ERROR: C[%0d] = 0x%0h, expected 0x015E0C", 5, iDUT.C[5]);
        if (iDUT.C[6] !== 24'h01A04C) $error("ERROR: C[%0d] = 0x%0h, expected 0x01A04C", 6, iDUT.C[6]);
        if (iDUT.C[7] !== 24'h01E28C) $error("ERROR: C[%0d] = 0x%0h, expected 0x01E28C", 7, iDUT.C[7]);

		// check first digit
		SW = 10'h008;
		$display("Checking first digit of i.e., C[0].");

		@(posedge clk)
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 HEX_12, HEX_12, HEX_2, HEX_1, HEX_0, HEX_0);

		// check second digit
		SW = 10'h009;
		$display("Checking first digit of i.e., C[1].");

		@(posedge clk)
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 HEX_12, HEX_0, HEX_5, HEX_5, HEX_0, HEX_0);

		// check third digit
		SW = 10'h00A;
		$display("Checking first digit of i.e., C[2].");

		@(posedge clk)
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 HEX_12, HEX_4, HEX_7, HEX_9, HEX_0, HEX_0);

		// check fourth digit
		SW = 10'h00B;
		$display("Checking first digit of i.e., C[3].");

		@(posedge clk)
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 HEX_12, HEX_8, HEX_9, HEX_13, HEX_0, HEX_0);

		// check fifth digit
		SW = 10'h00C;
		$display("Checking first digit of i.e., C[4].");

		@(posedge clk)
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 HEX_12, HEX_12, HEX_11, HEX_1, HEX_1, HEX_0);

		// check sixth digit
		SW = 10'h00D;
		$display("Checking first digit of i.e., C[5].");

		@(posedge clk)
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 HEX_12, HEX_0, HEX_14, HEX_5, HEX_1, HEX_0);

		// check seventh digit
		SW = 10'h00E;
		$display("Checking first digit of i.e., C[6].");

		@(posedge clk)
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 HEX_12, HEX_4, HEX_0, HEX_10, HEX_1, HEX_0);

		// check eigth digit
		SW = 10'h00F;
		$display("Checking first digit of i.e., C[7].");

		@(posedge clk)
		hexCheck(HEX0, HEX1, HEX2, HEX3, HEX4, HEX5,
				 HEX_12, HEX_8, HEX_2, HEX_14, HEX_1, HEX_0);
				 
        // All tests passed.
		$display("\nYAHOO!! All Tests Passed!");
		$stop();
	end

    // Clock generation: 100 MHz clock period of 10 ns.
	always 
		#5 clk = ~clk;

endmodule