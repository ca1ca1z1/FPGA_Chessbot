//chess_board.v
//this stores the chess board and all the extra info (whose turn, castling, en passant, 50-move rule)
//also can reset the board

//sqaures are numbered from 0 to 63
//    square_index = rank_row * 8 + file_column
//    in binary, this just means that the the square_index is {rank_row, file_coloumn}
//    for example a1 = 0, b1 = 1, ... h1 = 7,   a2 = 8, ... h2 = 15,   ...   h8 = 63
//    rank: row 1-8 stored as 0-7
//    file = column a-h stored as 0-7
//
//each square needs 4 bits:
//    bit 3     = colour:  0 = white, 1 = black
//    bits 2:0  = peice_type:   0 = empty, 1 = pawn, 2 = knight, 3 = bishop, 4 = rook,  5 = queen, 6 = king
//    so a square is given by {colour, piece_type}
//    example: black queen = 1_101 = 4'b1101
//
//Note: in code we used reset as active high (reset = 1 means "reset now").
//     The keys on the FPGA are active low (pressed = 0), so will need to do reset(~KEY[0])

module chess_board (
    //clock and reset
	 
    //use the CLOCK_50 for clock. Registers update on clock edges.
    input  wire clock,
    // When 1, the board and game info are set back to the starting position.
    input  wire reset,

	 
    //Info of one square

    //a move changes 2 squares (clear the "from" square, fill the "to" square),
    //we can only write one square per clock cycle.
    input  wire         write_square_enable,   // 1 = write this clock cycle
    input  wire [5:0]   write_square_index,    // which square to change (0-63)
    input  wire [3:0]   write_square_piece,    // what piece to put there

    //WRITE the game info
    //used LATER after each move to update turn, castling, etc.
    input  wire         write_game_info_enable,       // 1 = load the new values below
    input  wire         new_side_to_move,             // 0 = white, 1 = black
    input  wire [3:0]   new_castling_rights,          // see castling_rights below
    input  wire         new_en_passant_available,		//1 = en_passant in available
    input  wire [2:0]   new_en_passant_file,				
    input  wire [7:0]   new_halfmove_clock,				//checks if 50 moves have passed without pawn push or a capture

    //READ one square
    //"what is on square X?"
    //the square number and it tells you the piece there (instantly, no clock).
    input  wire [5:0]   read_square_index,
    output wire [3:0]   read_square_piece,

    //whole board at once
    // All 64 squares side by side in one 256-bit wire (64 squares x 4 bits).
    // Square N lives at bits [4*N+3 : 4*N]. Used later by the display, the AI, and attack detection.
    output wire [255:0] all_squares_flat,

    // ---------------- Game info (stored values) ----------------
    // Whose turn: 0 = white to move, 1 = black to move.
    output reg side_to_move,
    // Who may still castle (1 = still allowed):
    //   bit 0 = white kingside,  bit 1 = white queenside,
    //   bit 2 = black kingside,  bit 3 = black queenside
    // Lost when the king or that rook moves. Needed because the board alone
    // can't tell you whether a king/rook has moved earlier in the game.
    output reg  [3:0] castling_rights,
    // En passant: right after a pawn moves 2 squares, an enemy pawn may capture
    // it "in passing", but ONLY on the very next move.
    //   en_passant_available = 1 means that capture is possible right now
    //   en_passant_file      = which column (0 = a ... 7 = h) the capturable pawn is on
    output reg en_passant_available,
    output reg  [2:0] en_passant_file,
    // Counts moves since the last pawn move or capture. At 100 (50 full moves)
    // the game can be drawn (the "50-move rule").
    output reg  [7:0] halfmove_clock
);

    //make code easier to read
    //localparam is a named constant. It does not create any hardware.
    localparam [2:0] PIECE_EMPTY  = 3'd0;
    localparam [2:0] PIECE_PAWN   = 3'd1;
    localparam [2:0] PIECE_KNIGHT = 3'd2;
    localparam [2:0] PIECE_BISHOP = 3'd3;
    localparam [2:0] PIECE_ROOK   = 3'd4;
    localparam [2:0] PIECE_QUEEN  = 3'd5;
    localparam [2:0] PIECE_KING   = 3'd6;

    localparam COLOR_WHITE = 1'b0;
    localparam COLOR_BLACK = 1'b1;


	 //Hardcoded starter board, starting_peice_for_square tells you what peice is on this square
    //code further down calls it once for each of the 64 squares.
    function [3:0] starting_piece_for_square;
        input [5:0] square_index;          // which square (0-63) we are asking about

        reg [2:0] rank_row;                // 0-7 = rows 1 to 8
        reg [2:0] file_column;             // 0-7 = columns a to h
        reg [2:0] back_rank_piece;         // the piece that belongs in this column on row 1 or 8

        begin
            // Split the square number into row and column.
            rank_row = square_index[5:3];
            file_column = square_index[2:0];

            // Step 1: pick the back-rank piece for this column.
            case (file_column)
                3'd0, 3'd7: back_rank_piece = PIECE_ROOK;     // a and h
                3'd1, 3'd6: back_rank_piece = PIECE_KNIGHT;   // b and g
                3'd2, 3'd5: back_rank_piece = PIECE_BISHOP;   // c and f
                3'd3:       back_rank_piece = PIECE_QUEEN;    // d
                default:    back_rank_piece = PIECE_KING;     // e
            endcase

            // Step 2: pick what goes on this square based on which row it is on.
            case (rank_row)
                3'd0:    starting_piece_for_square = {COLOR_WHITE, back_rank_piece}; // row 1: white back rank
                3'd1:    starting_piece_for_square = {COLOR_WHITE, PIECE_PAWN};      // row 2: white pawns
                3'd6:    starting_piece_for_square = {COLOR_BLACK, PIECE_PAWN};      // row 7: black pawns
                3'd7:    starting_piece_for_square = {COLOR_BLACK, back_rank_piece}; // row 8: black back rank
                default: starting_piece_for_square = {COLOR_WHITE, PIECE_EMPTY};     // rows 3-6: empty
            endcase
        end
    endfunction

    // -------------------------------------------------------------------------
    // THE BOARD: 64 registers, each 4 bits wide. board_squares[12] is the
    // piece on square 12 (e2). Registers = memory that holds its value.
    // -------------------------------------------------------------------------
    reg [3:0] board_squares [0:63];

    integer loop_index;   // only used to count 0..63 inside the reset loop

    // -------------------------------------------------------------------------
    // This block runs on every rising edge of the clock (50 million times per
    // second on the DE1-SoC). It is where the registers actually change.
    // -------------------------------------------------------------------------
    always @(posedge clock) begin

        if (reset) begin
            // RESET: set all 64 squares to the starting position.
            // This looks like a software loop, but the synthesizer unrolls it
            // into 64 separate assignments, so ALL squares are set on the
            // SAME clock edge. Nothing happens one after another.
            for (loop_index = 0; loop_index < 64; loop_index = loop_index + 1)
                board_squares[loop_index] <= starting_piece_for_square(loop_index[5:0]);

            // Reset the game info too.
            side_to_move         <= COLOR_WHITE;  // white moves first
            castling_rights      <= 4'b1111;      // everyone can still castle
            en_passant_available <= 1'b0;         // no en passant possible at the start
            en_passant_file      <= 3'd0;
            halfmove_clock       <= 8'd0;

        end else begin
            // Normal operation (not resetting).

            // Change one square if asked to.
            if (write_square_enable)
                board_squares[write_square_index] <= write_square_piece;

            // Load new game info if asked to.
            if (write_game_info_enable) begin
                side_to_move         <= new_side_to_move;
                castling_rights      <= new_castling_rights;
                en_passant_available <= new_en_passant_available;
                en_passant_file      <= new_en_passant_file;
                halfmove_clock       <= new_halfmove_clock;
            end
        end
    end

    // -------------------------------------------------------------------------
    // READ SIDE: these lines continuously output board contents.
    // They have no clock; the outputs follow the registers immediately.
    // -------------------------------------------------------------------------

    // Look up one square by its number.
    assign read_square_piece = board_squares[read_square_index];

    // Copy all 64 squares into one wide 256-bit output.
    // "generate" makes 64 copies of the assign line below, one per square.
    genvar square_number;
    generate
        for (square_number = 0; square_number < 64; square_number = square_number + 1) begin : copy_square_to_flat_output
            assign all_squares_flat[4*square_number +: 4] = board_squares[square_number];
        end
    endgenerate

endmodule
