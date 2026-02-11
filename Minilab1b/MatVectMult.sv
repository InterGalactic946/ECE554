/////////////////////////////////////////////////////////////
// MatVectMult.sv: Matrix-Vector Multiplication Module     //
//                                                         //
// This module implements a matrix-vector multiplication   //
// using FIFOs and MAC units.                              //
/////////////////////////////////////////////////////////////
`timescale 1ns/1ps

module MatVecMult (
    input logic clk, rst_n, start, Clr,
    input logic [8:0] wren,
    input logic [7:0] data_in,
    output logic valid,    
    output logic [23:0] C [7:0]
);

    // Define the states for the state machine controlling the matrix-vector multiplication operation.
    typedef enum logic [1:0] { IDLE, LOAD, MULT, DONE } state_t;

    // State machine control signals.
    logic start_mult, clr_rden, rst_fifo_n;
    state_t state, nxt_state;

    // Internal signals for the FIFOs.
    logic [7:0] a_full, a_empty;
    logic [7:0] a_data [0:7];
    logic [7:0] b_data;
    logic b_full, b_empty;

    // Internal signals for the control of the FIFOs and MAC units.
    logic [7:0] en_a_fifos;
    logic [7:0] mac_en;
    logic [7:0] en_mac;
    logic [55:0] b_shift_reg;

    // Clear the FIFOs either on rst_n or Clr.
    assign rst_fifo_n = rst_n & ~Clr;

    // Instantiate 8 FIFOs for the A matrix rows.
    FIFO FIFO_A [7:0] (.clk(clk),.rst_n(rst_fifo_n), .rden(en_a_fifos), .wren(wren[7:0]), .i_data(data_in), .o_data(a_data), .full(a_full), .empty(a_empty));
    
    // Instantiate FIFO for the B vector.
    FIFO FIFO_B(.clk(clk),.rst_n(rst_fifo_n), .rden(en_a_fifos[0]), .wren(wren[8]), .i_data(data_in), .o_data(b_data), .full(b_full), .empty(b_empty));

    // Instantiate 8 MAC units for the 8 rows of the A matrix, connecting the outputs to the C vector outputs.
    MAC mac [7:0] (.clk(clk),.rst_n(rst_n),.En(en_mac), .Clr(Clr), .Ain(a_data), .Bin({b_shift_reg, b_data}), .Cout(C));

    // Enable each MAC unit a cycle after the previous one, rolling through 
    // all 8 MAC units for each row of the A matrix.
    always_ff @( posedge clk, negedge rst_n ) begin : en_mac_def
        if (!rst_n)
            en_mac <= '0;
        else
            en_mac <= en_a_fifos;
    end

    // Enable the A FIFOs to read out data as long as the 
    // corresponding MAC unit is enabled and the FIFO is not empty and we enable
    // the B FIFO the same time as the first A FIFO.
    assign en_a_fifos = mac_en & ~a_empty;

    // Enable the MAC units once all the FIFOs have been loaded with data. 
    // Shift the enable signal to roll through the MAC units for each row of the A matrix.
    always_ff @(posedge clk, negedge rst_n) begin : rolling_start
        if (!rst_n)
            mac_en <= '0;
        else if (clr_rden)
            mac_en <= '0;
        else if (start_mult)
            mac_en = (mac_en << 1) + 1'b1;
    end

    // Shift the B vector data through a shift register to feed the MAC units with 
    // the correct B vector element for each row of the A matrix.
    always_ff @(posedge clk, negedge rst_n) begin : b_shift_reg_def
        if (!rst_n)
            b_shift_reg <= '{default:0};
        else if (start_mult)
            b_shift_reg <= {b_shift_reg[47:0], b_data};
    end

    // Implement the state machine to control the flow of the matrix-vector multiplication operation.
    always_ff @(posedge clk, negedge rst_n) begin : state_ff
        if (!rst_n)
            state <= IDLE;
        else
            state <= nxt_state;
    end

    // Capture the full and empty conditions of the FIFOs to determine when to transition between states and when to enable the MAC units.
    assign full = &a_full & b_full;
    assign empty = &a_empty & b_empty;

    // State machine combinational logic.
    always_comb begin : state_machine
        nxt_state = state;
        start_mult = 1'b0;
        clr_rden = 1'b0;
        valid = 1'b0;

        case (state)
            IDLE: begin
                if (start) begin
                    clr_rden = 1'b1;
                    nxt_state = LOAD;
                end
            end 
            
            LOAD: begin
                if (full) begin
                    start_mult = 1'b1;
                    nxt_state = MULT;
                end
            end 
            
            MULT: begin
                start_mult = 1'b1;
                if (empty) begin
                    clr_rden = 1'b1;
                    nxt_state = DONE;
                end
            end 
            
            DONE: begin
                valid = 1'b1;
                if (Clr) begin
                    nxt_state = IDLE;
                end
            end

            default: 
                nxt_state = IDLE;
        endcase
    end

endmodule