`include "chess_defs.vh"
// Vendor-independent core. All game logic runs in the pixel clock domain.
module chess_core #(parameter integer DEBOUNCE_CYCLES = 252000)(
    input wire clk, input wire reset, input wire [3:0] key_n,
    output reg [7:0] red, output reg [7:0] green, output reg [7:0] blue,
    output reg hs_n, output reg vs_n, output reg blank_n,
    output wire [5:0] cursor, output wire selected, output wire blocked
);
    wire [3:0] key_press;
    genvar k;
    generate for (k = 0; k < 4; k = k + 1) begin : keys
        button_event #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) u_key(
            .clk(clk), .reset(reset), .key_n(key_n[k]), .pressed(key_press[k]));
    end endgenerate
    wire [255:0] board_state;
    wire [5:0] source, last_from, last_to;
    wire last_valid;
    chess_game u_game(.clk(clk), .reset(reset),
        .up(key_press[3]), .right(key_press[2]), .confirm(key_press[1]), .cancel(key_press[0]),
        .board_state(board_state), .cursor(cursor), .source(source),
        .selected(selected), .blocked(blocked), .last_from(last_from),
        .last_to(last_to), .last_valid(last_valid));

    wire [9:0] x, y;
    wire visible, timing_hs, timing_vs, vblank_start;
    vga_timing u_timing(.clk(clk), .reset(reset), .x(x), .y(y),
        .visible(visible), .hs_n(timing_hs), .vs_n(timing_vs), .vblank_start(vblank_start));

    // Atomic display snapshot: game edits during active video are shown next frame.
    reg [255:0] view_board;
    reg [5:0] view_cursor, view_source, view_last_from, view_last_to;
    reg view_selected, view_blocked, view_last_valid;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            view_board <= `CHESS_INITIAL_POSITION;
            view_cursor <= 52; view_source <= 0;
            view_selected <= 0; view_blocked <= 0;
            view_last_from <= 0; view_last_to <= 0; view_last_valid <= 0;
        end else if (vblank_start) begin
            view_board <= board_state;
            view_cursor <= cursor; view_source <= source;
            view_selected <= selected; view_blocked <= blocked;
            view_last_from <= last_from; view_last_to <= last_to;
            view_last_valid <= last_valid;
        end
    end
    wire [23:0] pixel;
    chess_renderer u_renderer(.x(x), .y(y), .board_state(view_board),
        .cursor(view_cursor), .source(view_source), .selected(view_selected),
        .blocked(view_blocked), .last_from(view_last_from), .last_to(view_last_to),
        .last_valid(view_last_valid), .rgb(pixel));

    // A full-cycle render stage gives tile selection, sprites and text sufficient
    // timing budget. Delay all control signals by the same one-pixel latency.
    reg [23:0] pixel_pipe;
    reg visible_pipe, hs_pipe, vs_pipe;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pixel_pipe <= 0; visible_pipe <= 0; hs_pipe <= 1; vs_pipe <= 1;
        end else begin
            pixel_pipe <= pixel;
            visible_pipe <= visible; hs_pipe <= timing_hs; vs_pipe <= timing_vs;
        end
    end
    // Launch data on falling edges; the external ADV7123 samples rising edges.
    // HS/VS/BLANK travel with the same pixel; no divided fabric clock is used.
    always @(negedge clk or posedge reset) begin
        if (reset) begin
            red <= 0; green <= 0; blue <= 0;
            hs_n <= 1; vs_n <= 1; blank_n <= 0;
        end else begin
            {red, green, blue} <= visible_pipe ? pixel_pipe : 24'b0;
            hs_n <= hs_pipe; vs_n <= vs_pipe; blank_n <= visible_pipe;
        end
    end
endmodule
