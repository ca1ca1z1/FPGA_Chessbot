// =============================================================================
// tb_chess_board.v
//
// Plain ModelSim testbench for chess_board. It only drives the inputs.
// Read the results from the waveform.
// =============================================================================
`timescale 1ns/1ps

module tb_chess_board;

    reg          clock = 0;
    reg          reset = 1;

    reg          write_square_enable = 0;
    reg  [5:0]   write_square_index  = 0;
    reg  [3:0]   write_square_piece  = 0;

    reg  [5:0]   read_square_index   = 0;
    wire [3:0]   read_square_piece;

    wire [255:0] all_squares_flat;
    wire         side_to_move;
    wire [3:0]   castling_rights;
    wire         en_passant_available;
    wire [2:0]   en_passant_file;
    wire [7:0]   halfmove_clock;

    chess_board board_under_test (
        .clock(clock),
        .reset(reset),
        .write_square_enable(write_square_enable),
        .write_square_index(write_square_index),
        .write_square_piece(write_square_piece),
        .write_game_info_enable(1'b0),
        .new_side_to_move(1'b0),
        .new_castling_rights(4'b0),
        .new_en_passant_available(1'b0),
        .new_en_passant_file(3'b0),
        .new_halfmove_clock(8'b0),
        .read_square_index(read_square_index),
        .read_square_piece(read_square_piece),
        .all_squares_flat(all_squares_flat),
        .side_to_move(side_to_move),
        .castling_rights(castling_rights),
        .en_passant_available(en_passant_available),
        .en_passant_file(en_passant_file),
        .halfmove_clock(halfmove_clock)
    );

    // 10 ns clock period
    always #5 clock = ~clock;

    initial begin
        // Hold reset for 3 clocks, then release.
        repeat (3) @(posedge clock);
        @(negedge clock); reset = 0;
        @(posedge clock);

        // Read a few squares one at a time through the read port.
        read_square_index = 6'd0;   #10;   // a1
        read_square_index = 6'd4;   #10;   // e1
        read_square_index = 6'd12;  #10;   // e2
        read_square_index = 6'd60;  #10;   // e8

        // Move the e2 pawn to e4 by hand using the write port.
        read_square_index = 6'd12;                                        // watch e2 on the read port
        @(negedge clock);
        write_square_enable = 1;
        write_square_index = 6'd12; write_square_piece = 4'b0000;        @(negedge clock); // clear e2
        write_square_index = 6'd28; write_square_piece = {1'b0, 3'd1};   @(negedge clock); // pawn onto e4
        write_square_enable = 0;
        read_square_index = 6'd28;  #20;                                  // watch e4 on the read port

        // Reset again in the middle of a game.
        @(negedge clock); reset = 1; repeat (2) @(posedge clock); @(negedge clock); reset = 0;
        read_square_index = 6'd12;  #20;                                  // e2 should have its pawn back
        read_square_index = 6'd28;  #20;                                  // e4 should be empty again

    end
endmodule
