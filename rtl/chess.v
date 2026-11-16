// chess.v   (Quartus top-level entity)
//
//to connects chess_board to the DE1-SoC's physical pins.

//for demo:
//   SW[5:0]    pick a square number (0-63)
//   LEDR[3:0]  shows the piece on that square: {colour, type}
//   LEDR[8:5]  castling rights (all 1s at the start)
//   LEDR[9]    side to move (0 = white)
//   KEY[0]     reset the board (pressed = reset)
module chess (
    input  wire        CLOCK_50,   // 50 MHz clock on the board
    input  wire [3:0]  KEY,        // push buttons (active low)
    input  wire [9:0]  SW,
    output wire [9:0]  LEDR        
);

    //inputs
    wire [3:0] piece_on_selected_square;
    wire       side_to_move;
    wire [3:0] castling_rights;

    wire board_reset;
    reset_sync reset_control (.clk(CLOCK_50), .reset_request(~KEY[0]), .reset_out(board_reset));

    chess_board board (
        .clock(CLOCK_50),
        .reset(board_reset),  // synchronized release; board reset remains synchronous

        // Nothing writes to the board yet, so these are tied off to 0.
        .write_square_enable(1'b0),
        .write_square_index(6'd0),
        .write_square_piece(4'd0),
        .write_game_info_enable(1'b0),
        .new_side_to_move(1'b0),
        .new_castling_rights(4'd0),
        .new_en_passant_available(1'b0),
        .new_en_passant_file(3'd0),
        .new_halfmove_clock(8'd0),

        //switches choose the square, board tells us the piece on it.
        .read_square_index(SW[5:0]),
        .read_square_piece(piece_on_selected_square),

        //outputs we don't use yet are left empty.
        .all_squares_flat(),
        .side_to_move(side_to_move),
        .castling_rights(castling_rights),
        .en_passant_available(),
        .en_passant_file(),
        .halfmove_clock()
    );

    assign LEDR[3:0] = piece_on_selected_square;
    assign LEDR[4]   = board_reset;             // reset active indicator
    assign LEDR[8:5] = castling_rights;
    assign LEDR[9]   = side_to_move;

endmodule
