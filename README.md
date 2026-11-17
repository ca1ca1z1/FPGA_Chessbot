# v1.1.2

- Added Milestone1.pdf.

# v1.1.1

- Fixed an issue where ModelSim failed to load the project.
- Fixed an issue where the properties of the chess.mpf file were incomplete and fields were missing.

# v1.1.0

Basic piece movement with the push buttons.

## Controls

- **KEY[3]:** move the cursor one column right; from column h it wraps back to a.
- **KEY[2]:** move the cursor one row up; from row 8 it wraps back to row 1.
- **KEY[1]:** confirm. With nothing selected it selects the piece under the cursor (only a piece of the side to move). On a legal destination it makes the move. On the selected square itself it cancels the selection. Anything else is ignored.
- **KEY[0]:** reset to a new game.

## Display

- **HEX5 HEX4:** cursor square, for example `E2`.
- **HEX3 HEX2:** selected square, blank when nothing is selected.
- **LEDR[3:0]:** piece on the cursor square. **LEDR[4]:** reset active. **LEDR[5]:** piece selected. **LEDR[6]:** `move_legal`. **LEDR[7]:** game over. **LEDR[8]:** winner (0 white, 1 black). **LEDR[9]:** side to move.

## Move Rules

- Every piece moves in its normal pattern. Bishops, rooks, queens and the pawn's double step cannot jump over pieces.
- A piece cannot land on a piece of its own colour; landing on an enemy piece captures it.
- Not implemented: castling, en passant, promotion, and check. A king can be left attacked; the game ends when a king is captured, and the capturing side is the winner.

## Signals for the VGA Display

`chess_game` outputs `cursor_square`, `piece_selected`, `selected_square`, `move_legal` (1 when the selected piece may move to the cursor square), `legal_targets` (64 bits, bit N = the selected piece may move to square N), `game_over` and `winner`.

## New Files

- `rtl/move_checker.v`: combinational legality check for one from/to pair.
- `rtl/chess_game.v`: cursor, selection, legal-target scan and move execution.
- `rtl/button_press.v`: synchronizer, debounce and one pulse per press.
- `sim/tb_moves.v`: self-checking test (random boards against a reference model, then a game played with the buttons).

# v1.0.1

- Added DE1-SoC pin assignments and 50 MHz timing constraints.
- Separated hardware sources (`rtl/`) from testbenches (`sim/`) and updated Quartus and ModelSim paths.
- Added an asynchronous-assert, synchronous-release reset synchronizer; LEDR[4] indicates active reset.
- Moved testbench reset release away from rising clock edges.

# v1.0.0

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
