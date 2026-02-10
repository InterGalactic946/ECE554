/////////////////////////////////////////////////////////////
// Minilab1.sv: Top Level Module for Minilab 1b            //
//                                                         //
// This module computes the matrix-vector multiplication   //
// using the MatVecMult module and interfaces with memory. //
// and displays the result on HEX displays.                //
/////////////////////////////////////////////////////////////
`timescale 1 ps / 1 ps

module Minilab1b(	
    //////////// CLOCK //////////
	input 		          		CLOCK2_50,
	input 		          		CLOCK3_50,
	input 		          		CLOCK4_50,
	input 		          		CLOCK_50,

	//////////// SEG7 //////////
	output	logic [6:0]		HEX0,
	output  logic [6:0]		HEX1,
	output	logic [6:0]		HEX2,
	output	logic [6:0]		HEX3,
	output	logic [6:0]		HEX4,
	output	logic [6:0]		HEX5,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// SW //////////
	input 		     [9:0]		SW
);

    // Clk, rst, clear and start signals from keys.
    logic clk, rst_n, start, clr;

    assign rst_n = KEY[0];
    assign start = ~KEY[1];
    assign clr = ~KEY[2];
    assign clk = CLOCK_50;

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

    // State machine states for controlling the flow of the operation.
    typedef enum logic [2:0] {IDLE, MEM_READ, SHIFT, MULT, DONE} state_t;

    // State machine control signals.
    logic clr_wren, en_wren, read_mem, clr_blk_cnt, clr_byte_cnt, inc_blk_cnt, inc_byte_cnt, shift, done;
    logic fifos_full, bytes_loaded;
    state_t state, nxt_state;
    
    // Registers and counters for controlling the loading of data from memory and feeding it into the MatVecMult module.
    logic [8:0] wren, wen_fifos;
    logic [2:0] byte_cnt;
    logic [3:0] fifo_cnt;
    logic [31:0] address;
    logic [63:0] shift_reg, readdata;

    // Outputs from the MatVecMult module and memory wrapper module.
    logic mult_valid;
    logic mem_valid, mem_busy;
    logic [23:0] C [7:0];

    // Instantiate the MatVecMult and memory wrapper modules.
    MatVecMult matrix_vect_mult (.clk(clk), .rst_n(rst_n), .start(start), .Clr(clr), .wren(wen_fifos), .data_in(shift_reg[63:56]), .valid(mult_valid), .C(C));
    mem_wrapper mem (.clk(clk), .reset_n(rst_n), .address(address), .read(read_mem), .readdata(readdata), .readdatavalid(mem_valid), .waitrequest(mem_busy));

    // Enable signals for writing to the FIFOs in the MatVecMult module, generated based on the state machine control signals.
    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n)
            wren <= 9'h0;
        else if (clr_wren)
            wren <= 1'b0;
        else if (en_wren)
            wren <= 9'h1;
        else if (mem_valid)
            wren <= wren << 1;
    end

    // We only enable writing to the FIFOs when we haven't yet enabled any of them and we have valid data from memory to load into the shift register.
    assign en_wren = ~|wren & mem_valid;

    // Enable the FIFOs only when shifting.
    assign wen_fifos = wren & {9{shift}};

    // Byte counter to keep track of how many bytes have been loaded into the shift register.
    always_ff @(posedge clk, negedge rst_n) begin : byte_cnt_ff
        if (!rst_n)
            byte_cnt <= 3'b0;
        else if (clr_byte_cnt)
            byte_cnt <= 3'b0;
        else if (inc_byte_cnt)
            byte_cnt <= byte_cnt + 1'b1;
    end

    // We have loaded 8 bytes (64 bits) into the shift register when byte_cnt is 7.
    assign bytes_loaded = (byte_cnt == 3'd7);

    // Shift register to load data from memory and feed it into the MatVecMult module.
    always_ff @(posedge clk, negedge rst_n) begin : shift_reg_ff
        if (!rst_n)
            shift_reg <= 64'h0000_0000_0000_0000;
        else if (mem_valid)
            shift_reg <= readdata;                 // Load the shift register with data from memory when it is valid.
        else if (shift)
            shift_reg <= {shift_reg[55:0], 8'h00}; // Shift the register left by 8 bits to load the next byte of data.
    end

    // Register to keep track of the address for reading data blocks from memory.
    always_ff @(posedge clk, negedge rst_n) begin : address_ff
        if (!rst_n)
            address <= 32'h0000_0000;
        else if (clr_blk_cnt)
            address <= 32'h0000_0000;           // Reset address to the beginning of the data blocks.
        else if (mem_valid)
            address <= address + 32'h0000_0001; // Increment address to read the next block of data.
    end

    // Counter to keep track of how many data blocks have been loaded into the FIFOs.
    always_ff @(posedge clk, negedge rst_n) begin : fifo_cnt_ff
        if (!rst_n)
            fifo_cnt <= 4'h0;
        else if (clr_blk_cnt)
            fifo_cnt <= 4'h0;
        else if (inc_blk_cnt)
            fifo_cnt <= fifo_cnt + 1'b1;
    end

    // The FIFOs are full when we have loaded 9 blocks of data (8 for the A matrix and 1 for the B vector).
    assign fifos_full = (fifo_cnt == 4'h8);

    // Implement the state machine to control the flow of the memory loading and matrix-vector multiplication operation.
    always_ff @(posedge clk, negedge rst_n) begin : state_ff
        if (!rst_n)
            state <= IDLE;
        else
            state <= nxt_state;
    end

    // Output the current state on the LEDs for debugging.
    assign LEDR = {7'h00, state};

    // State machine combinational logic.
    always_comb begin : state_machine
        nxt_state = state;
        done = 1'b0;
        read_mem = 1'b0;
        shift = 1'b0;
        clr_wren = 1'b0;
        clr_blk_cnt = 1'b0;
        clr_byte_cnt = 1'b0;
        inc_byte_cnt = 1'b0;
        inc_blk_cnt = 1'b0;

        case (state)
            IDLE: begin
                if (start) begin
                    read_mem = 1'b1; 
                    nxt_state = MEM_READ;
                end
            end 

            MEM_READ: begin
                if (mem_valid) begin
                    clr_byte_cnt = 1'b1;
                    nxt_state = SHIFT;
                end
            end

            SHIFT: begin
                shift = 1'b1;
                inc_byte_cnt = 1'b1;

                if (bytes_loaded) begin
                    if (fifos_full) begin
                        clr_wren = 1'b1;
                        nxt_state = MULT;
                    end else begin
                        inc_blk_cnt = 1'b1;
                        read_mem = 1'b1;
                        nxt_state = MEM_READ;
                    end
                end
            end

            MULT: begin
                if (mult_valid)
                    nxt_state = DONE;
            end 
            
            DONE: begin
                done = 1'b1;
                if (clr) begin
                    clr_blk_cnt = 1'b1;
                    clr_byte_cnt = 1'b1;
                    nxt_state = IDLE;
                end
            end

            default: 
                nxt_state = IDLE;
        endcase
    end

    always_comb begin
        if (state == DONE && SW[3]) begin
            case(C[SW[2:0]][3:0])
                4'd0: HEX0 = HEX_0;
                4'd1: HEX0 = HEX_1;
                4'd2: HEX0 = HEX_2;
                4'd3: HEX0 = HEX_3;
                4'd4: HEX0 = HEX_4;
                4'd5: HEX0 = HEX_5;
                4'd6: HEX0 = HEX_6;
                4'd7: HEX0 = HEX_7;
                4'd8: HEX0 = HEX_8;
                4'd9: HEX0 = HEX_9;
                4'd10: HEX0 = HEX_10;
                4'd11: HEX0 = HEX_11;
                4'd12: HEX0 = HEX_12;
                4'd13: HEX0 = HEX_13;
                4'd14: HEX0 = HEX_14;
                4'd15: HEX0 = HEX_15;
            endcase
        end
        else begin
            HEX0 = OFF;
        end
    end

    always_comb begin
        if (state == DONE && SW[3]) begin
            case(C[SW[2:0]][7:4])
            4'd0: HEX1 = HEX_0;
            4'd1: HEX1 = HEX_1;
            4'd2: HEX1 = HEX_2;
            4'd3: HEX1 = HEX_3;
            4'd4: HEX1 = HEX_4;
            4'd5: HEX1 = HEX_5;
            4'd6: HEX1 = HEX_6;
            4'd7: HEX1 = HEX_7;
            4'd8: HEX1 = HEX_8;
            4'd9: HEX1 = HEX_9;
            4'd10: HEX1 = HEX_10;
            4'd11: HEX1 = HEX_11;
            4'd12: HEX1 = HEX_12;
            4'd13: HEX1 = HEX_13;
            4'd14: HEX1 = HEX_14;
            4'd15: HEX1 = HEX_15;
            endcase
        end
        else begin
            HEX1 = OFF;
        end
    end

    always_comb begin
        if (state == DONE && SW[3]) begin
            case(C[SW[2:0]][11:8])
                4'd0: HEX2 = HEX_0;
                4'd1: HEX2 = HEX_1;
                4'd2: HEX2 = HEX_2;
                4'd3: HEX2 = HEX_3;
                4'd4: HEX2 = HEX_4;
                4'd5: HEX2 = HEX_5;
                4'd6: HEX2 = HEX_6;
                4'd7: HEX2 = HEX_7;
                4'd8: HEX2 = HEX_8;
                4'd9: HEX2 = HEX_9;
                4'd10: HEX2 = HEX_10;
                4'd11: HEX2 = HEX_11;
                4'd12: HEX2 = HEX_12;
                4'd13: HEX2 = HEX_13;
                4'd14: HEX2 = HEX_14;
                4'd15: HEX2 = HEX_15;
            endcase
        end
        else begin
            HEX2 = OFF;
        end
    end

    always_comb begin
        if (state == DONE && SW[3]) begin
            case(C[SW[2:0]][15:12])
                4'd0: HEX3 = HEX_0;
                4'd1: HEX3 = HEX_1;
                4'd2: HEX3 = HEX_2;
                4'd3: HEX3 = HEX_3;
                4'd4: HEX3 = HEX_4;
                4'd5: HEX3 = HEX_5;
                4'd6: HEX3 = HEX_6;
                4'd7: HEX3 = HEX_7;
                4'd8: HEX3 = HEX_8;
                4'd9: HEX3 = HEX_9;
                4'd10: HEX3 = HEX_10;
                4'd11: HEX3 = HEX_11;
                4'd12: HEX3 = HEX_12;
                4'd13: HEX3 = HEX_13;
                4'd14: HEX3 = HEX_14;
                4'd15: HEX3 = HEX_15;
            endcase
        end
        else begin
            HEX3 = OFF;
        end
    end

    always_comb begin
        if (state == DONE && SW[3]) begin
            case(C[SW[2:0]][19:16])
                4'd0: HEX4 = HEX_0;
                4'd1: HEX4 = HEX_1;
                4'd2: HEX4 = HEX_2;
                4'd3: HEX4 = HEX_3;
                4'd4: HEX4 = HEX_4;
                4'd5: HEX4 = HEX_5;
                4'd6: HEX4 = HEX_6;
                4'd7: HEX4 = HEX_7;
                4'd8: HEX4 = HEX_8;
                4'd9: HEX4 = HEX_9;
                4'd10: HEX4 = HEX_10;
                4'd11: HEX4 = HEX_11;
                4'd12: HEX4 = HEX_12;
                4'd13: HEX4 = HEX_13;
                4'd14: HEX4 = HEX_14;
                4'd15: HEX4 = HEX_15;
            endcase
        end
        else begin
            HEX4 = OFF;
        end
    end

    always_comb begin
        if (state == DONE && SW[3]) begin
            case(C[SW[2:0]][23:20])
                4'd0: HEX5 = HEX_0;
                4'd1: HEX5 = HEX_1;
                4'd2: HEX5 = HEX_2;
                4'd3: HEX5 = HEX_3;
                4'd4: HEX5 = HEX_4;
                4'd5: HEX5 = HEX_5;
                4'd6: HEX5 = HEX_6;
                4'd7: HEX5 = HEX_7;
                4'd8: HEX5 = HEX_8;
                4'd9: HEX5 = HEX_9;
                4'd10: HEX5 = HEX_10;
                4'd11: HEX5 = HEX_11;
                4'd12: HEX5 = HEX_12;
                4'd13: HEX5 = HEX_13;
                4'd14: HEX5 = HEX_14;
                4'd15: HEX5 = HEX_15;
            endcase
        end
        else begin
            HEX5 = OFF;
        end
    end

endmodule