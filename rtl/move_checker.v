// move_checker.v
// Pure combinational check: "may the piece on from_square move to to_square?"
//
// Only the basic moves are covered:
//   - each piece moves in its normal pattern
//   - bishops, rooks and queens (and the pawn's double step) cannot jump over pieces
//   - a piece cannot land on a piece of its own colour
//   - landing on an enemy piece is a capture (pawns capture diagonally only)
// NOT covered: castling, en passant, promotion, and check. A move that leaves
// the king attacked is still "legal" here; the game ends when a king is captured.

module move_checker (
    input  wire [255:0] all_squares_flat,   // whole board, square N at bits [4*N+3 : 4*N]
    input  wire [5:0]   from_square,    // 0(A1) ~ 63(H8)
    input  wire [5:0]   to_square,
    input  wire         side_to_move,       // 0 = white, 1 = black
    output wire         move_legal
);

    localparam [2:0] PIECE_EMPTY  = 3'd0;
    localparam [2:0] PIECE_PAWN   = 3'd1;
    localparam [2:0] PIECE_KNIGHT = 3'd2;
    localparam [2:0] PIECE_BISHOP = 3'd3;
    localparam [2:0] PIECE_ROOK   = 3'd4;
    localparam [2:0] PIECE_QUEEN  = 3'd5;
    localparam [2:0] PIECE_KING   = 3'd6;

    localparam COLOR_WHITE = 1'b0;

    // The pieces on the two squares.
    wire [3:0] from_piece = all_squares_flat[4*from_square +: 4];
    wire [3:0] to_piece   = all_squares_flat[4*to_square   +: 4];

    wire       from_color = from_piece[3];
    wire [2:0] from_type  = from_piece[2:0];
    wire       to_color   = to_piece[3];
    wire       to_occupied = (to_piece[2:0] != PIECE_EMPTY);

    // One bit per square: 1 = something is standing there.
    wire [63:0] square_occupied;
    genvar square_number;
    generate
        for (square_number = 0; square_number < 64; square_number = square_number + 1) begin : find_occupied_squares
            assign square_occupied[square_number] = (all_squares_flat[4*square_number +: 3] != PIECE_EMPTY);
        end
    endgenerate

    // Split both squares into row (rank) and column (file).
    wire [2:0] from_row = from_square[5:3];
    wire [2:0] from_col = from_square[2:0];
    wire [2:0] to_row   = to_square[5:3];
    wire [2:0] to_col   = to_square[2:0];

    wire row_increases = (to_row > from_row);
    wire row_decreases = (to_row < from_row);
    wire col_increases = (to_col > from_col);
    wire col_decreases = (to_col < from_col);

    // How far the move goes in each direction (always positive).
    wire [2:0] row_distance = row_increases ? (to_row - from_row) : (from_row - to_row);
    wire [2:0] col_distance = col_increases ? (to_col - from_col) : (from_col - to_col);

    wire straight_line = (row_distance == 3'd0) != (col_distance == 3'd0);       // along a row or a column
    wire diagonal_line = (row_distance == col_distance) && (row_distance != 3'd0);

    // Number of steps along a straight or diagonal line.
    wire [2:0] line_distance = (row_distance > col_distance) ? row_distance : col_distance;

    // Path check for sliding moves. A line has at most 6 squares strictly
    // between its two ends. Step k looks at the square k steps away from
    // from_square; it only counts if it is before the destination.
    wire [6:1] path_step_blocked;
    genvar step_number;
    generate
        for (step_number = 1; step_number <= 6; step_number = step_number + 1) begin : check_path_step
            localparam [2:0] STEP = step_number;
            wire [2:0] step_row = row_increases ? (from_row + STEP) :
                                  row_decreases ? (from_row - STEP) : from_row;
            wire [2:0] step_col = col_increases ? (from_col + STEP) :
                                  col_decreases ? (from_col - STEP) : from_col;
            assign path_step_blocked[step_number] =
                (STEP < line_distance) && square_occupied[{step_row, step_col}];
        end
    endgenerate

    wire path_clear = ~(|path_step_blocked);

    // ---- Rules for each piece type ----

    // Pawns: white moves up the board (row increases), black moves down.
    wire pawn_moves_forward = (from_color == COLOR_WHITE) ? row_increases : row_decreases;
    wire pawn_on_start_row  = (from_color == COLOR_WHITE) ? (from_row == 3'd1) : (from_row == 3'd6);

    wire pawn_single_step = pawn_moves_forward && (row_distance == 3'd1) && (col_distance == 3'd0) && !to_occupied;
    wire pawn_double_step = pawn_moves_forward && (row_distance == 3'd2) && (col_distance == 3'd0) && !to_occupied
                            && pawn_on_start_row && path_clear;
    wire pawn_capture     = pawn_moves_forward && (row_distance == 3'd1) && (col_distance == 3'd1) && to_occupied;

    wire pawn_move_ok   = pawn_single_step || pawn_double_step || pawn_capture;

    wire knight_move_ok = ((row_distance == 3'd1) && (col_distance == 3'd2)) ||
                          ((row_distance == 3'd2) && (col_distance == 3'd1));

    wire bishop_move_ok = diagonal_line && path_clear;
    wire rook_move_ok   = straight_line && path_clear;
    wire queen_move_ok  = (diagonal_line || straight_line) && path_clear;

    wire king_move_ok   = (line_distance == 3'd1);

    reg piece_move_ok;
    always @(*) begin
        case (from_type)
            PIECE_PAWN:   piece_move_ok = pawn_move_ok;
            PIECE_KNIGHT: piece_move_ok = knight_move_ok;
            PIECE_BISHOP: piece_move_ok = bishop_move_ok;
            PIECE_ROOK:   piece_move_ok = rook_move_ok;
            PIECE_QUEEN:  piece_move_ok = queen_move_ok;
            PIECE_KING:   piece_move_ok = king_move_ok;
            default:      piece_move_ok = 1'b0;      // empty square: nothing to move
        endcase
    end

    // You can only move your own piece, and never onto your own piece.
    wire moving_own_piece    = (from_color == side_to_move);
    wire landing_on_own_piece = to_occupied && (to_color == from_color);

    assign move_legal = piece_move_ok && moving_own_piece && !landing_on_own_piece;

endmodule
