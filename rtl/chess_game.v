// chess_game.v
// Cursor, piece selection and move execution.
//
// Buttons (one-clock pulses):
//   move_right : cursor one column right, wraps from h back to a
//   move_up    : cursor one row up, wraps from row 8 back to row 1
//   confirm    : - nothing selected: select the piece under the cursor
//                  (only a piece of the side to move can be selected)
//                - cursor on the selected square: cancel the selection
//                - cursor on a legal destination: make the move
//                - anything else: ignored, the selection stays
//
// After a piece is selected, move_checker is run once for each of the 64
// squares (one per clock) to fill legal_targets. That takes 64 clocks, far
// faster than a button press.
//
// A move is written to chess_board in two clocks: clear the "from" square,
// then put the piece on the "to" square. Capturing a king ends the game.

module chess_game (
    input  wire         clock,
    input  wire         reset,

    input  wire         move_right,
    input  wire         move_up,
    input  wire         confirm,

    // Board state read from chess_board.
    input  wire [255:0] all_squares_flat,
    input  wire         side_to_move,
    input  wire [3:0]   castling_rights,
    input  wire [7:0]   halfmove_clock,

    // Writes into chess_board.
    output wire         write_square_enable,
    output wire [5:0]   write_square_index,
    output wire [3:0]   write_square_piece,
    output wire         write_game_info_enable,
    output wire         new_side_to_move,
    output wire [3:0]   new_castling_rights,
    output wire         new_en_passant_available,
    output wire [2:0]   new_en_passant_file,
    output wire [7:0]   new_halfmove_clock,

    // Status, for LEDs now and the VGA display later.
    output reg  [5:0]   cursor_square,
    output reg          piece_selected,     // 1 = a piece is picked up
    output reg  [5:0]   selected_square,    // only meaningful when piece_selected = 1
    output wire         move_legal,         // 1 = selected piece may move to the cursor square
    output reg  [63:0]  legal_targets,      // bit N = selected piece may move to square N
    output reg          game_over,
    output reg          winner              // 0 = white, 1 = black; only meaningful when game_over = 1
);

    localparam [2:0] PIECE_EMPTY = 3'd0;
    localparam [2:0] PIECE_PAWN  = 3'd1;
    localparam [2:0] PIECE_KING  = 3'd6;

    localparam [1:0] STATE_IDLE  = 2'd0;   // waiting for buttons
    localparam [1:0] STATE_SCAN  = 2'd1;   // filling legal_targets
    localparam [1:0] STATE_CLEAR = 2'd2;   // move, clock 1: empty the "from" square
    localparam [1:0] STATE_PLACE = 2'd3;   // move, clock 2: fill the "to" square

    reg [1:0] state;
    reg [5:0] scan_square;       // square being tested during STATE_SCAN
    reg [5:0] target_square;     // destination of the move in progress
    reg [3:0] moving_piece;      // piece being moved
    reg [3:0] captured_piece;    // what stood on the destination (empty if nothing)

    wire [3:0] cursor_piece   = all_squares_flat[4*cursor_square   +: 4];
    wire [3:0] selected_piece = all_squares_flat[4*selected_square +: 4];

    wire cursor_has_own_piece = (cursor_piece[2:0] != PIECE_EMPTY) && (cursor_piece[3] == side_to_move);

    wire scan_move_legal;
    move_checker checker (
        .all_squares_flat(all_squares_flat),
        .from_square(selected_square),
        .to_square(scan_square),
        .side_to_move(side_to_move),
        .move_legal(scan_move_legal)
    );

    assign move_legal = piece_selected && (state == STATE_IDLE) && legal_targets[cursor_square];

    always @(posedge clock) begin
        if (reset) begin
            state           <= STATE_IDLE;
            cursor_square   <= 6'd0;
            piece_selected  <= 1'b0;
            selected_square <= 6'd0;
            legal_targets   <= 64'd0;
            game_over       <= 1'b0;
            winner          <= 1'b0;
            scan_square     <= 6'd0;
            target_square   <= 6'd0;
            moving_piece    <= 4'd0;
            captured_piece  <= 4'd0;
        end else begin

            // The cursor can always move. Adding 1 to a 3-bit value wraps 7 -> 0.
            if (move_right) cursor_square[2:0] <= cursor_square[2:0] + 3'd1;
            if (move_up)    cursor_square[5:3] <= cursor_square[5:3] + 3'd1;

            case (state)
                STATE_IDLE: begin
                    if (confirm && !game_over) begin
                        if (!piece_selected) begin
                            if (cursor_has_own_piece) begin
                                piece_selected  <= 1'b1;
                                selected_square <= cursor_square;
                                legal_targets   <= 64'd0;
                                scan_square     <= 6'd0;
                                state           <= STATE_SCAN;
                            end
                        end else if (cursor_square == selected_square) begin
                            piece_selected <= 1'b0;             // confirm twice = cancel
                            legal_targets  <= 64'd0;
                        end else if (legal_targets[cursor_square]) begin
                            target_square  <= cursor_square;
                            moving_piece   <= selected_piece;
                            captured_piece <= cursor_piece;
                            state          <= STATE_CLEAR;
                        end
                    end
                end

                STATE_SCAN: begin
                    legal_targets[scan_square] <= scan_move_legal;
                    scan_square <= scan_square + 6'd1;
                    if (scan_square == 6'd63)
                        state <= STATE_IDLE;
                end

                STATE_CLEAR: begin
                    state <= STATE_PLACE;
                end

                default: begin   // STATE_PLACE
                    piece_selected <= 1'b0;
                    legal_targets  <= 64'd0;
                    if (captured_piece[2:0] == PIECE_KING) begin
                        game_over <= 1'b1;
                        winner    <= side_to_move;              // the side that just moved
                    end
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

    // ---- Writes into chess_board ----
    assign write_square_enable = (state == STATE_CLEAR) || (state == STATE_PLACE);
    assign write_square_index  = (state == STATE_CLEAR) ? selected_square : target_square;
    assign write_square_piece  = (state == STATE_CLEAR) ? 4'd0            : moving_piece;

    // Game info changes together with the second write.
    wire pawn_move_or_capture = (moving_piece[2:0] == PIECE_PAWN) || (captured_piece[2:0] != PIECE_EMPTY);

    assign write_game_info_enable   = (state == STATE_PLACE);
    assign new_side_to_move         = ~side_to_move;
    assign new_castling_rights      = castling_rights;   // castling is not implemented yet
    assign new_en_passant_available = 1'b0;              // en passant is not implemented yet
    assign new_en_passant_file      = 3'd0;
    assign new_halfmove_clock       = pawn_move_or_capture     ? 8'd0 :
                                      (halfmove_clock == 8'd255) ? 8'd255 : halfmove_clock + 8'd1;

endmodule
