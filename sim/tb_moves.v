// tb_moves.v
// Self-checking test for piece movement.
//
// Part 1: move_checker alone, on random boards. Every from/to pair for both
//         sides is compared against a separately written reference model.
// Part 2: a short game played through the top level with the KEY buttons:
//         cursor wrap, select / cancel, illegal attempts, moves, captures,
//         capturing a king (game over) and reset.
`timescale 1ns/1ps

module tb_moves;

    reg clk = 0;
    always #10 clk = ~clk;

    reg  [3:0] keys = 4'b1111;
    wire [9:0] leds;
    wire [6:0] hex2, hex3, hex4, hex5;
    reg        passed = 0;

    // Short debounce so a button press only needs a few clocks.
    chess #(.DEBOUNCE_BITS(2)) dut (
        .CLOCK_50(clk), .KEY(keys), .SW(10'd0), .LEDR(leds),
        .HEX0(), .HEX1(), .HEX2(hex2), .HEX3(hex3), .HEX4(hex4), .HEX5(hex5)
    );

    // Stand-alone move_checker for the random board test.
    reg  [255:0] unit_board = 0;
    reg  [5:0]   unit_from = 0, unit_to = 0;
    reg          unit_side = 0;
    wire         unit_legal;
    move_checker unit (
        .all_squares_flat(unit_board), .from_square(unit_from), .to_square(unit_to),
        .side_to_move(unit_side), .move_legal(unit_legal)
    );

    task check;
        input ok; input [511:0] message;
        begin if (ok !== 1'b1) begin $display("FAIL: %0s (time %0t)", message, $time); $stop; end end
    endtask

    // ---------------- Reference model ----------------
    reg [3:0] ref_board [0:63];

    function ref_legal;
        input integer from_sq, to_sq;
        input side;
        integer from_r, from_c, to_r, to_c, dr, dc, step_r, step_c, r, c, forward;
        reg [3:0] mover, target, between;
        reg ok, diagonal, straight;
        begin
            mover  = ref_board[from_sq];
            target = ref_board[to_sq];
            from_r = from_sq / 8;  from_c = from_sq % 8;
            to_r   = to_sq / 8;    to_c   = to_sq % 8;
            dr = to_r - from_r;    dc = to_c - from_c;
            ok = 0;
            if (mover[2:0] != 0 && mover[3] == side && from_sq != to_sq &&
                !(target[2:0] != 0 && target[3] == mover[3])) begin
                case (mover[2:0])
                    3'd1: begin   // pawn
                        forward = mover[3] ? -1 : 1;
                        if (dc == 0 && dr == forward && target[2:0] == 0) ok = 1;
                        if (dc == 0 && dr == 2*forward && from_r == (mover[3] ? 6 : 1) && target[2:0] == 0) begin
                            between = ref_board[from_sq + 8*forward];
                            if (between[2:0] == 0) ok = 1;
                        end
                        if ((dc == 1 || dc == -1) && dr == forward && target[2:0] != 0) ok = 1;
                    end
                    3'd2: if (dr*dr + dc*dc == 5) ok = 1;            // knight
                    3'd6: if (dr*dr <= 1 && dc*dc <= 1) ok = 1;      // king
                    3'd3, 3'd4, 3'd5: begin                          // bishop, rook, queen
                        diagonal = (dr*dr == dc*dc);
                        straight = (dr == 0 || dc == 0);
                        if ((mover[2:0] == 3'd3 && diagonal) || (mover[2:0] == 3'd4 && straight) ||
                            (mover[2:0] == 3'd5 && (diagonal || straight))) begin
                            step_r = (dr > 0) ? 1 : (dr < 0) ? -1 : 0;
                            step_c = (dc > 0) ? 1 : (dc < 0) ? -1 : 0;
                            ok = 1;
                            r = from_r + step_r;  c = from_c + step_c;
                            while (r != to_r || c != to_c) begin     // walk the squares in between
                                between = ref_board[r*8 + c];
                                if (between[2:0] != 0) ok = 0;
                                r = r + step_r;  c = c + step_c;
                            end
                        end
                    end
                    default: ok = 0;
                endcase
            end
            ref_legal = ok;
        end
    endfunction

    // ---------------- Helpers for the game test ----------------
    integer i, board_number, from_index, to_index, side_index, mismatches;
    reg [31:0] random_bits;
    reg [2:0]  random_type;

    function [3:0] square;                    // piece on a square of the real board
        input [5:0] index;
        begin square = dut.all_squares_flat[4*index +: 4]; end
    endfunction

    task press;                               // press and release one KEY
        input integer key_number;
        begin
            @(negedge clk); keys[key_number] = 0;
            repeat (12) @(negedge clk);
            keys[key_number] = 1;
            repeat (12) @(negedge clk);
        end
    endtask

    task confirm;                             // KEY[1], then wait for the 64-clock target scan
        begin press(1); repeat (80) @(negedge clk); end
    endtask

    task move_cursor_to;                      // only right / up exist, so wrap around
        input [5:0] target;
        begin
            while (dut.cursor_square[2:0] != target[2:0]) press(3);
            while (dut.cursor_square[5:3] != target[5:3]) press(2);
        end
    endtask

    task check_legal_targets;                 // compare the highlight mask with the reference
        begin
            for (i = 0; i < 64; i = i + 1) ref_board[i] = square(i[5:0]);
            for (i = 0; i < 64; i = i + 1)
                check(dut.legal_targets[i] === ref_legal(dut.selected_square, i, dut.side_to_move),
                      "legal_targets matches reference model");
        end
    endtask

    reg [3:0] piece_before;
    reg       side_before;
    task play;                                // select from_sq, move to to_sq, check the result
        input [5:0] from_sq, to_sq;
        begin
            side_before  = dut.side_to_move;
            piece_before = square(from_sq);
            move_cursor_to(from_sq);
            confirm;
            check(dut.piece_selected === 1'b1 && dut.selected_square === from_sq, "piece selected");
            check_legal_targets;
            move_cursor_to(to_sq);
            check(leds[6] === 1'b1, "move_legal is 1 on a legal destination");
            confirm;
            check(square(from_sq) === 4'd0,         "from square is empty after the move");
            check(square(to_sq)   === piece_before, "piece arrived on the to square");
            check(dut.side_to_move === ~side_before, "turn passed to the other side");
            check(dut.piece_selected === 1'b0 && dut.legal_targets === 64'd0, "selection cleared after the move");
        end
    endtask

    initial begin
        // ================= Part 1: random boards =================
        mismatches = 0;
        for (board_number = 0; board_number < 60; board_number = board_number + 1) begin
            for (i = 0; i < 64; i = i + 1) begin
                random_bits = $random;
                // About 40% of squares get a random piece of a random colour.
                random_type = 1 + random_bits[20:11] % 6;      // 1..6
                if (random_bits[9:0] < 10'd410)
                    ref_board[i] = {random_bits[10], random_type};
                else
                    ref_board[i] = 4'd0;
                unit_board[4*i +: 4] = ref_board[i];
            end
            for (side_index = 0; side_index < 2; side_index = side_index + 1)
                for (from_index = 0; from_index < 64; from_index = from_index + 1)
                    for (to_index = 0; to_index < 64; to_index = to_index + 1) begin
                        unit_side = side_index; unit_from = from_index; unit_to = to_index;
                        #1;
                        if (unit_legal !== ref_legal(from_index, to_index, unit_side)) begin
                            mismatches = mismatches + 1;
                            if (mismatches <= 10)
                                $display("MISMATCH board %0d side %0d from %0d (piece %h) to %0d (piece %h): checker %b",
                                         board_number, side_index, from_index, ref_board[from_index],
                                         to_index, ref_board[to_index], unit_legal);
                        end
                    end
        end
        check(mismatches == 0, "move_checker matches reference on random boards");
        $display("Part 1 done: 60 random boards, every from/to pair, both sides");

        // ================= Part 2: play through the top level =================
        @(negedge clk); keys[0] = 0; repeat (3) @(negedge clk); keys[0] = 1; repeat (4) @(negedge clk);
        check(dut.cursor_square === 6'd0 && dut.piece_selected === 1'b0 && dut.game_over === 1'b0, "state after reset");
        check(leds === 10'b0000000100, "LEDs after reset: white rook under the cursor on a1");

        // Cursor wrap-around.
        repeat (7) press(3);
        check(dut.cursor_square === 6'd7, "seven presses right: a1 -> h1");
        press(3);
        check(dut.cursor_square === 6'd0, "right from h1 wraps to a1");
        repeat (7) press(2);
        check(dut.cursor_square === 6'd56, "seven presses up: a1 -> a8");
        press(2);
        check(dut.cursor_square === 6'd0, "up from a8 wraps to a1");

        // Select the a1 rook: it is boxed in, so no targets. Confirm again cancels.
        confirm;
        check(dut.piece_selected === 1'b1 && dut.selected_square === 6'd0, "a1 rook selected");
        check(dut.legal_targets === 64'd0, "boxed-in rook has no legal targets");
        check(leds[5] === 1'b1, "LEDR[5] shows the selection");
        confirm;
        check(dut.piece_selected === 1'b0, "confirming the same square cancels");

        // Squares that must not be selectable for white.
        move_cursor_to(6'd28); confirm;
        check(dut.piece_selected === 1'b0, "empty square cannot be selected");
        move_cursor_to(6'd52); confirm;
        check(dut.piece_selected === 1'b0, "black piece cannot be selected on white's turn");

        // e2 pawn: exactly e3 and e4.
        move_cursor_to(6'd12);
        check(hex5 === 7'b0000110 && hex4 === 7'b0100100, "HEX5 HEX4 show E2");
        check(hex3 === 7'b1111111 && hex2 === 7'b1111111, "HEX3 HEX2 blank with nothing selected");
        confirm;
        check(dut.legal_targets === ((64'd1 << 20) | (64'd1 << 28)), "e2 pawn may go to e3 and e4 only");
        check(hex3 === 7'b0000110 && hex2 === 7'b0100100, "HEX3 HEX2 show the selected square E2");
        check_legal_targets;

        // Illegal destination (e5): flag is 0, confirm does nothing, selection stays.
        move_cursor_to(6'd36);
        check(leds[6] === 1'b0, "move_legal is 0 on an illegal destination");
        confirm;
        check(dut.piece_selected === 1'b1 && square(6'd12) === 4'h1 && square(6'd36) === 4'h0 && dut.side_to_move === 1'b0,
              "illegal move is ignored");

        // Legal destination (e4).
        move_cursor_to(6'd28);
        check(leds[6] === 1'b1, "move_legal is 1 on e4");
        confirm;
        check(square(6'd12) === 4'h0 && square(6'd28) === 4'h1 && dut.side_to_move === 1'b1, "1. e4 played");

        // Black to move: white pieces are not selectable.
        move_cursor_to(6'd1); confirm;
        check(dut.piece_selected === 1'b0, "white piece cannot be selected on black's turn");

        play(6'd51, 6'd35);                                   // 1... d5
        play(6'd28, 6'd35);                                   // 2. exd5  (pawn captures diagonally)
        check(square(6'd35) === 4'h1, "white pawn captured on d5");
        check(dut.halfmove_clock === 8'd0, "halfmove clock is 0 after a capture");
        play(6'd59, 6'd35);                                   // 2... Qxd5 (queen slides down the open d file)
        check(square(6'd35) === 4'hD, "black queen captured on d5");
        play(6'd4, 6'd12);                                    // 3. Ke2
        check(dut.halfmove_clock === 8'd1, "halfmove clock counts a quiet move");
        play(6'd35, 6'd28);                                   // 3... Qe4
        check(dut.halfmove_clock === 8'd2, "halfmove clock counts a second quiet move");
        play(6'd8, 6'd16);                                    // 4. a3
        check(dut.halfmove_clock === 8'd0, "halfmove clock is 0 after a pawn move");
        check(dut.game_over === 1'b0, "game still running");
        play(6'd28, 6'd12);                                   // 4... Qxe2, capturing the king
        check(dut.game_over === 1'b1 && dut.winner === 1'b1, "black wins by capturing the king");
        check(leds[7] === 1'b1 && leds[8] === 1'b1, "LEDs show game over and black as winner");

        // Nothing can be selected after the game ended.
        move_cursor_to(6'd16); confirm;
        check(dut.piece_selected === 1'b0, "no selection after game over");

        // KEY[0] starts a new game.
        @(negedge clk); keys[0] = 0; repeat (3) @(negedge clk); keys[0] = 1; repeat (4) @(negedge clk);
        check(dut.game_over === 1'b0 && dut.side_to_move === 1'b0 && dut.cursor_square === 6'd0, "reset clears the game state");
        check(square(6'd12) === 4'h1 && square(6'd28) === 4'h0 && square(6'd4) === 4'h6 && square(6'd59) === 4'hD,
              "reset restores the starting position");

        passed = 1;
        $display("PASS tb_moves: move rules, selection, captures, king capture and reset");
        $finish;
    end

    initial begin #100000000; $display("FAIL watchdog"); $stop; end

endmodule
