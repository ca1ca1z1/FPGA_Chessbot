`ifndef CHESS_DEFS_VH
`define CHESS_DEFS_VH
// Square = {row[2:0], column[2:0]}; a8=0, h1=63. White is at the bottom.
// Piece[3] = black; piece[2:0] = empty, pawn, knight, bishop, rook, queen, king.
`define CHESS_INITIAL_POSITION {32'h42365324, 32'h11111111, 128'b0, 32'h99999999, 32'hCABEDBAC}
`endif
