/////////////////////////////////////////////////////////////
// MAC.sv: Multiply-Accumulate Unit                        //
//                                                         //
// This module implements a simple MAC with                //
// parameterized data width.                               //
/////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module MAC #
(
parameter DATA_WIDTH = 8
)
(
input clk,
input rst_n,
input En,
input Clr,
input [DATA_WIDTH-1:0] Ain,
input [DATA_WIDTH-1:0] Bin,
output [DATA_WIDTH*3-1:0] Cout
);

// Use the FPGA vendor's Multiplier and Adder IP cores.
// Internal signals
logic [15:0] mult_result;
logic en_ff, mult_clr;
logic [DATA_WIDTH*3-1:0] accum_result;
logic [DATA_WIDTH*3-1:0] accumulator;

// Clear the multiplier when Clr is asserted or when reset is active.
assign mult_clr = Clr | ~rst_n;

// Instantiate the Mult and Adder IP cores.
Mult mult(.clock(clk), .aclr(mult_clr), .dataa(Ain), .datab(Bin), .result(mult_result));
Adder add(.dataa(mult_result), .datab(accumulator), .result(accum_result));

// Accumulate the sum of products.
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    accumulator <= '0;
  else if (Clr)
    accumulator <= '0;
  else if (en_ff) begin
    accumulator <= accum_result;
  end
end

// Pipeline the enabled output to meet timing requirements.
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    en_ff <= 1'b0;
  else
    en_ff <= En;
end

// Output the accumulated result.
assign Cout = accumulator;

// // Instead, use behavioral implementation.
// // Internal signals
// logic [DATA_WIDTH*3-1:0] accumulator;

// // Accumulate the sum of products.
// always_ff @(posedge clk or negedge rst_n) begin
//   if (!rst_n)
//     accumulator <= '0;
//   else if (Clr)
//     accumulator <= '0;
//   else if (En) begin
//     accumulator <= accumulator + Ain * Bin;
//   end
// end

// // Output the accumulated result.
// assign Cout = accumulator;

endmodule