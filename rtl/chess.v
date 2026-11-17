// chess.v   (Quartus top-level entity)
//
//to connects chess_board to the DE1-SoC's physical pins.

//controls:
//   KEY[3]     move the cursor one column right (h wraps back to a)
//   KEY[2]     move the cursor one row up (row 8 wraps back to row 1)
//   KEY[1]     confirm: select a piece / move it to the cursor / cancel on the same square
//   KEY[0]     reset the board (pressed = reset)
//
//display:
//   HEX5 HEX4  cursor square, for example "E2"
//   HEX3 HEX2  selected square (blank when nothing is selected)
//   LEDR[3:0]  piece on the cursor square: {colour, type}
//   LEDR[4]    reset is active
//   LEDR[5]    a piece is selected
//   LEDR[6]    the selected piece may move to the cursor square
//   LEDR[7]    game over
//   LEDR[8]    winner (0 = white, 1 = black), valid when LEDR[7] is on
//   LEDR[9]    side to move (0 = white)
module chess #(
    parameter DEBOUNCE_BITS = 20   // made small in simulation so button presses are quick
) (
    input  wire        CLOCK_50,   // 50 MHz clock on the board
    input  wire [3:0]  KEY,        // push buttons (active low)
    input  wire [9:0]  SW,         // not used at the moment
    output wire [9:0]  LEDR,
    output wire [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5   // 7-segment displays (active low)
);

    wire board_reset;
    reset_sync reset_control (.clk(CLOCK_50), .reset_request(~KEY[0]), .reset_out(board_reset));

    // One clean pulse per button press.
    wire right_pressed, up_pressed, confirm_pressed;
    button_press #(.DEBOUNCE_BITS(DEBOUNCE_BITS)) right_button
        (.clock(CLOCK_50), .reset(board_reset), .button_n(KEY[3]), .pressed(right_pressed));
    button_press #(.DEBOUNCE_BITS(DEBOUNCE_BITS)) up_button
        (.clock(CLOCK_50), .reset(board_reset), .button_n(KEY[2]), .pressed(up_pressed));
    button_press #(.DEBOUNCE_BITS(DEBOUNCE_BITS)) confirm_button
        (.clock(CLOCK_50), .reset(board_reset), .button_n(KEY[1]), .pressed(confirm_pressed));

    // Board <-> game connections.
    wire [255:0] all_squares_flat;
    wire         side_to_move;
    wire [3:0]   castling_rights;
    wire [7:0]   halfmove_clock;

    wire         write_square_enable;
    wire [5:0]   write_square_index;
    wire [3:0]   write_square_piece;
    wire         write_game_info_enable;
    wire         new_side_to_move;
    wire [3:0]   new_castling_rights;
    wire         new_en_passant_available;
    wire [2:0]   new_en_passant_file;
    wire [7:0]   new_halfmove_clock;

    // Game status. legal_targets is not shown anywhere yet; it is for the VGA highlight later.
    wire [5:0]   cursor_square;
    wire         piece_selected;
    wire [5:0]   selected_square;
    wire         move_legal;
    wire [63:0]  legal_targets;
    wire         game_over;
    wire         winner;

    wire [3:0]   piece_on_cursor_square;

    chess_board board (
        .clock(CLOCK_50),
        .reset(board_reset),  // synchronized release; board reset remains synchronous

        .write_square_enable(write_square_enable),
        .write_square_index(write_square_index),
        .write_square_piece(write_square_piece),
        .write_game_info_enable(write_game_info_enable),
        .new_side_to_move(new_side_to_move),
        .new_castling_rights(new_castling_rights),
        .new_en_passant_available(new_en_passant_available),
        .new_en_passant_file(new_en_passant_file),
        .new_halfmove_clock(new_halfmove_clock),

        //the cursor chooses the square, board tells us the piece on it.
        .read_square_index(cursor_square),
        .read_square_piece(piece_on_cursor_square),

        .all_squares_flat(all_squares_flat),
        .side_to_move(side_to_move),
        .castling_rights(castling_rights),
        .en_passant_available(),
        .en_passant_file(),
        .halfmove_clock(halfmove_clock)
    );

    chess_game game (
        .clock(CLOCK_50),
        .reset(board_reset),

        .move_right(right_pressed),
        .move_up(up_pressed),
        .confirm(confirm_pressed),

        .all_squares_flat(all_squares_flat),
        .side_to_move(side_to_move),
        .castling_rights(castling_rights),
        .halfmove_clock(halfmove_clock),

        .write_square_enable(write_square_enable),
        .write_square_index(write_square_index),
        .write_square_piece(write_square_piece),
        .write_game_info_enable(write_game_info_enable),
        .new_side_to_move(new_side_to_move),
        .new_castling_rights(new_castling_rights),
        .new_en_passant_available(new_en_passant_available),
        .new_en_passant_file(new_en_passant_file),
        .new_halfmove_clock(new_halfmove_clock),

        .cursor_square(cursor_square),
        .piece_selected(piece_selected),
        .selected_square(selected_square),
        .move_legal(move_legal),
        .legal_targets(legal_targets),
        .game_over(game_over),
        .winner(winner)
    );

    assign LEDR[3:0] = piece_on_cursor_square;
    assign LEDR[4]   = board_reset;             // reset active indicator
    assign LEDR[5]   = piece_selected;
    assign LEDR[6]   = move_legal;
    assign LEDR[7]   = game_over;
    assign LEDR[8]   = winner;
    assign LEDR[9]   = side_to_move;

    // ---- 7-segment displays: segments are {g,f,e,d,c,b,a}, 0 = lit ----
    localparam [6:0] SEGMENTS_BLANK = 7'b1111111;

    // Column 0-7 shown as A b C d E F G H.
    function [6:0] file_letter_segments;
        input [2:0] file_column;
        begin
            case (file_column)
                3'd0: file_letter_segments = 7'b0001000;   // A
                3'd1: file_letter_segments = 7'b0000011;   // b
                3'd2: file_letter_segments = 7'b1000110;   // C
                3'd3: file_letter_segments = 7'b0100001;   // d
                3'd4: file_letter_segments = 7'b0000110;   // E
                3'd5: file_letter_segments = 7'b0001110;   // F
                3'd6: file_letter_segments = 7'b1000010;   // G
                default: file_letter_segments = 7'b0001001; // H
            endcase
        end
    endfunction

    // Row 0-7 shown as 1-8.
    function [6:0] rank_digit_segments;
        input [2:0] rank_row;
        begin
            case (rank_row)
                3'd0: rank_digit_segments = 7'b1111001;    // 1
                3'd1: rank_digit_segments = 7'b0100100;    // 2
                3'd2: rank_digit_segments = 7'b0110000;    // 3
                3'd3: rank_digit_segments = 7'b0011001;    // 4
                3'd4: rank_digit_segments = 7'b0010010;    // 5
                3'd5: rank_digit_segments = 7'b0000010;    // 6
                3'd6: rank_digit_segments = 7'b1111000;    // 7
                default: rank_digit_segments = 7'b0000000; // 8
            endcase
        end
    endfunction

    assign HEX5 = file_letter_segments(cursor_square[2:0]);
    assign HEX4 = rank_digit_segments(cursor_square[5:3]);
    assign HEX3 = piece_selected ? file_letter_segments(selected_square[2:0]) : SEGMENTS_BLANK;
    assign HEX2 = piece_selected ? rank_digit_segments(selected_square[5:3])  : SEGMENTS_BLANK;
    assign HEX1 = SEGMENTS_BLANK;
    assign HEX0 = SEGMENTS_BLANK;

endmodule
