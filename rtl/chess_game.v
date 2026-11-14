`include "chess_defs.vh"
// Stage 1 is a board interaction sandbox, not a chess rules engine.
// Event priority: cancel > confirm > up > right. Simultaneous actions never move
// the cursor and commit a move on the same cycle.
module chess_game(
    input wire clk, input wire reset,
    input wire up, input wire right, input wire confirm, input wire cancel,
    output reg [255:0] board_state,
    output reg [5:0] cursor, output reg [5:0] source,
    output reg selected, output reg blocked,
    output reg [5:0] last_from, output reg [5:0] last_to,
    output reg last_valid
);
    wire [3:0] at_cursor = board_state[{cursor, 2'b00} +: 4];
    wire [3:0] at_source = board_state[{source, 2'b00} +: 4];
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            board_state <= `CHESS_INITIAL_POSITION;
            cursor <= 6'd52; // e2
            source <= 0;
            selected <= 0;
            blocked <= 0;
            last_from <= 0;
            last_to <= 0;
            last_valid <= 0;
        end else if (cancel) begin
            selected <= 0;
            blocked <= 0;
        end else if (confirm) begin
            blocked <= 0;
            if (!selected) begin
                if (at_cursor != 0) begin
                    source <= cursor;
                    selected <= 1;
                end
            end else if (cursor == source) begin
                selected <= 0; // Never erase a piece by confirming its own square.
            end else if (at_cursor != 0 && at_cursor[3] == at_source[3]) begin
                blocked <= 1; // Keep the source selected; choose another target.
            end else begin
                board_state[{cursor, 2'b00} +: 4] <= at_source;
                board_state[{source, 2'b00} +: 4] <= 0;
                selected <= 0;
                last_from <= source;
                last_to <= cursor;
                last_valid <= 1;
            end
        end else if (up) begin
            cursor[5:3] <= cursor[5:3] - 1'b1;
            blocked <= 0;
        end else if (right) begin
            cursor[2:0] <= cursor[2:0] + 1'b1;
            blocked <= 0;
        end
    end
endmodule
