# V1.0.0

## Current Features

- Initialize and reset the board to the standard starting position.
- Read or write one square at a time, and output the full board as a 256-bit signal.
- Store the side to move, castling rights, en passant information, and halfmove counter.
- Select a square using switches and display its piece code on LEDs.
- Include ModelSim testbenches for board reads, writes, and reset.

## Board and Piece Representation

The board contains 64 squares, numbered from **A1 = 0** to **H8 = 63**:

`square_index = row * 8 + column`

Each square uses 4 bits:

- **Bit 3:** color — `0` for white, `1` for black.
- **Bits 2–0:** piece type — `0` empty, `1` pawn, `2` knight, `3` bishop, `4` rook, `5` queen, `6` king.

For example, a white pawn is `0001`, and a black king is `1110`.
