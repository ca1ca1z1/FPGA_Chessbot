// 25.2 MHz / (800 * 525) = exactly 60 Hz. Negative HS and VS.
module vga_timing(
    input wire clk, input wire reset,
    output reg [9:0] x, output reg [9:0] y,
    output wire visible, output wire hs_n, output wire vs_n,
    output wire vblank_start
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin x <= 0; y <= 0; end
        else if (x == 799) begin
            x <= 0;
            if (y == 524) y <= 0;
            else y <= y + 1'b1;
        end else x <= x + 1'b1;
    end
    assign visible = (x < 640) && (y < 480);
    assign hs_n = !((x >= 656) && (x < 752));
    assign vs_n = !((y >= 490) && (y < 492));
    assign vblank_start = (x == 0) && (y == 480);
endmodule
