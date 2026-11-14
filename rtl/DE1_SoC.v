module DE1_SoC(
    input wire CLOCK_50, input wire [3:0] KEY, input wire [9:0] SW,
    output wire [9:0] LEDR,
    output wire [7:0] VGA_R, output wire [7:0] VGA_G, output wire [7:0] VGA_B,
    output wire VGA_HS, output wire VGA_VS, output wire VGA_CLK,
    output wire VGA_BLANK_N, output wire VGA_SYNC_N
);
    wire pixel_clk, locked, reset;
    wire [5:0] cursor;
    wire selected, blocked;
    pixel_pll u_pixel_pll(.refclk(CLOCK_50), .reset(SW[9]), .pixel_clk(pixel_clk), .locked(locked));
    reset_sync u_reset(.clk(pixel_clk), .async_reset(SW[9] | !locked), .reset(reset));
    chess_core u_core(.clk(pixel_clk), .reset(reset), .key_n(KEY),
        .red(VGA_R), .green(VGA_G), .blue(VGA_B),
        .hs_n(VGA_HS), .vs_n(VGA_VS), .blank_n(VGA_BLANK_N),
        .cursor(cursor), .selected(selected), .blocked(blocked));
    assign VGA_CLK = pixel_clk;
    assign VGA_SYNC_N = 1'b0; // Separate HS/VS; no sync-on-green.
    assign LEDR = {locked, reset, blocked, selected, cursor};
endmodule
