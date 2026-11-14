// Procedural tile renderer. No framebuffer or external RAM is needed.
module chess_renderer(
    input wire [9:0] x, input wire [9:0] y,
    input wire [255:0] board_state,
    input wire [5:0] cursor, input wire [5:0] source,
    input wire selected, input wire blocked,
    input wire [5:0] last_from, input wire [5:0] last_to,
    input wire last_valid, output reg [23:0] rgb
);
    function [15:0] piece_row;
        input [2:0] kind;
        input [3:0] row;
        reg [255:0] shape;
        begin
            case (kind)
                1: shape = {16'h0000,16'h0180,16'h03C0,16'h07E0,
                    16'h07E0,16'h03C0,16'h0180,16'h03C0,
                    16'h03C0,16'h03C0,16'h07E0,16'h07E0,
                    16'h0FF0,16'h1FF8,16'h1FF8,16'h0000};
                2: shape = {16'h0000,16'h0300,16'h0780,16'h0FC0,
                    16'h1BE0,16'h3FE0,16'h3FF0,16'h3CF0,
                    16'h00F0,16'h01E0,16'h03E0,16'h07C0,
                    16'h0FF0,16'h1FF8,16'h1FF8,16'h0000};
                3: shape = {16'h0000,16'h0180,16'h03C0,16'h0760,
                    16'h0E70,16'h0C70,16'h07E0,16'h03C0,
                    16'h07E0,16'h0180,16'h03C0,16'h03C0,
                    16'h07E0,16'h1FF8,16'h1FF8,16'h0000};
                4: shape = {16'h0000,16'h1998,16'h1998,16'h1FF8,
                    16'h1FF8,16'h0FF0,16'h07E0,16'h07E0,
                    16'h07E0,16'h07E0,16'h07E0,16'h0FF0,
                    16'h0FF0,16'h1FF8,16'h1FF8,16'h0000};
                5: shape = {16'h0000,16'h2184,16'h33CC,16'h3FFC,
                    16'h1FF8,16'h1FF8,16'h0FF0,16'h0FF0,
                    16'h07E0,16'h03C0,16'h03C0,16'h07E0,
                    16'h0FF0,16'h1FF8,16'h1FF8,16'h0000};
                6: shape = {16'h0180,16'h0180,16'h07E0,16'h0180,
                    16'h0180,16'h0DB0,16'h1FF8,16'h1FF8,
                    16'h0FF0,16'h07E0,16'h03C0,16'h07E0,
                    16'h0FF0,16'h1FF8,16'h1FF8,16'h0000};
                default: shape = 0;
            endcase
            piece_row = shape[255 - row * 16 -: 16];
        end
    endfunction

    function [4:0] font_row;
        input [7:0] ch;
        input [2:0] row;
        reg [34:0] bits;
        begin
            case (ch)
                "A": bits = {5'b01110,5'b10001,5'b10001,5'b11111,5'b10001,5'b10001,5'b10001};
                "B": bits = {5'b11110,5'b10001,5'b10001,5'b11110,5'b10001,5'b10001,5'b11110};
                "C": bits = {5'b01111,5'b10000,5'b10000,5'b10000,5'b10000,5'b10000,5'b01111};
                "D": bits = {5'b11110,5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b11110};
                "E": bits = {5'b11111,5'b10000,5'b10000,5'b11110,5'b10000,5'b10000,5'b11111};
                "F": bits = {5'b11111,5'b10000,5'b10000,5'b11110,5'b10000,5'b10000,5'b10000};
                "G": bits = {5'b01111,5'b10000,5'b10000,5'b10111,5'b10001,5'b10001,5'b01111};
                "H": bits = {5'b10001,5'b10001,5'b10001,5'b11111,5'b10001,5'b10001,5'b10001};
                "I": bits = {5'b11111,5'b00100,5'b00100,5'b00100,5'b00100,5'b00100,5'b11111};
                "J": bits = {5'b00111,5'b00010,5'b00010,5'b00010,5'b10010,5'b10010,5'b01100};
                "K": bits = {5'b10001,5'b10010,5'b10100,5'b11000,5'b10100,5'b10010,5'b10001};
                "L": bits = {5'b10000,5'b10000,5'b10000,5'b10000,5'b10000,5'b10000,5'b11111};
                "M": bits = {5'b10001,5'b11011,5'b10101,5'b10101,5'b10001,5'b10001,5'b10001};
                "N": bits = {5'b10001,5'b11001,5'b11001,5'b10101,5'b10011,5'b10011,5'b10001};
                "O": bits = {5'b01110,5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b01110};
                "P": bits = {5'b11110,5'b10001,5'b10001,5'b11110,5'b10000,5'b10000,5'b10000};
                "Q": bits = {5'b01110,5'b10001,5'b10001,5'b10001,5'b10101,5'b10010,5'b01101};
                "R": bits = {5'b11110,5'b10001,5'b10001,5'b11110,5'b10100,5'b10010,5'b10001};
                "S": bits = {5'b01111,5'b10000,5'b10000,5'b01110,5'b00001,5'b00001,5'b11110};
                "T": bits = {5'b11111,5'b00100,5'b00100,5'b00100,5'b00100,5'b00100,5'b00100};
                "U": bits = {5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b01110};
                "V": bits = {5'b10001,5'b10001,5'b10001,5'b10001,5'b10001,5'b01010,5'b00100};
                "W": bits = {5'b10001,5'b10001,5'b10001,5'b10101,5'b10101,5'b10101,5'b01010};
                "X": bits = {5'b10001,5'b10001,5'b01010,5'b00100,5'b01010,5'b10001,5'b10001};
                "Y": bits = {5'b10001,5'b10001,5'b01010,5'b00100,5'b00100,5'b00100,5'b00100};
                "Z": bits = {5'b11111,5'b00001,5'b00010,5'b00100,5'b01000,5'b10000,5'b11111};
                "0": bits = {5'b01110,5'b10001,5'b10011,5'b10101,5'b11001,5'b10001,5'b01110};
                "1": bits = {5'b00100,5'b01100,5'b00100,5'b00100,5'b00100,5'b00100,5'b01110};
                "2": bits = {5'b01110,5'b10001,5'b00001,5'b00010,5'b00100,5'b01000,5'b11111};
                "3": bits = {5'b11110,5'b00001,5'b00001,5'b01110,5'b00001,5'b00001,5'b11110};
                "4": bits = {5'b00010,5'b00110,5'b01010,5'b10010,5'b11111,5'b00010,5'b00010};
                "5": bits = {5'b11111,5'b10000,5'b10000,5'b11110,5'b00001,5'b00001,5'b11110};
                "6": bits = {5'b01110,5'b10000,5'b10000,5'b11110,5'b10001,5'b10001,5'b01110};
                "7": bits = {5'b11111,5'b00001,5'b00010,5'b00100,5'b01000,5'b01000,5'b01000};
                "8": bits = {5'b01110,5'b10001,5'b10001,5'b01110,5'b10001,5'b10001,5'b01110};
                "9": bits = {5'b01110,5'b10001,5'b10001,5'b01111,5'b00001,5'b00001,5'b01110};
                default: bits = 0;
            endcase
            font_row = row < 7 ? bits[34 - row * 5 -: 5] : 5'b0;
        end
    endfunction

    integer i;
    reg [2:0] col, row;
    reg [5:0] lx, ly, square;
    reg [3:0] piece, sx, sy;
    reg [15:0] sprite;
    reg [127:0] line_text;
    reg text_active;
    reg [9:0] tx, ty;
    reg [7:0] character;
    reg [4:0] glyph;
    reg [3:0] char_index;
    reg [2:0] glyph_x, glyph_y;
    reg [23:0] ink;
    reg [9:0] dx, dy, text_column, text_remainder;
    reg [5:0] sprite_dx, sprite_dy;
    always @* begin
        rgb = 24'h101923;
        col = 0; row = 0; lx = 0; ly = 0; square = 0;
        piece = 0; sx = 0; sy = 0; sprite = 0;
        line_text = 0; text_active = 0; tx = 0; ty = 0;
        character = 0; glyph = 0; char_index = 0; glyph_x = 0; glyph_y = 0;
        ink = 24'hDCE7EC;
        dx = 0; dy = 0; text_column = 0; text_remainder = 0;
        sprite_dx = 0; sprite_dy = 0;

        if (x >= 440 && x < 624 && y >= 64 && y < 448) rgb = 24'h1C2A38;
        if (x >= 29 && x < 419 && y >= 61 && y < 451) rgb = 24'h354957;

        if (x >= 32 && x < 416 && y >= 64 && y < 448) begin
            for (i = 0; i < 8; i = i + 1) begin
                if (x >= 32 + i * 48) col = i[2:0];
                if (y >= 64 + i * 48) row = i[2:0];
            end
            dx = x - (10'd32 + {7'b0,col} * 10'd48);
            dy = y - (10'd64 + {7'b0,row} * 10'd48);
            lx = dx[5:0];
            ly = dy[5:0];
            square = {row, col};
            piece = board_state[{square, 2'b00} +: 4];
            rgb = (row[0] ^ col[0]) ? 24'h648774 : 24'hE5D8B9;
            if (last_valid && (square == last_from || square == last_to) &&
                lx >= 5 && lx < 10 && ly >= 5 && ly < 10) rgb = 24'hE5AF50;
            if (selected && square == source && (lx < 4 || lx >= 44 || ly < 4 || ly >= 44))
                rgb = 24'hFFC857;
            if (square == cursor && (lx < 2 || lx >= 46 || ly < 2 || ly >= 46))
                rgb = blocked ? 24'hFF6978 : 24'h5DE4F2;
            if (lx >= 8 && lx < 40 && ly >= 8 && ly < 40) begin
                sprite_dx = lx - 6'd8;
                sprite_dy = ly - 6'd8;
                sx = sprite_dx[4:1];
                sy = sprite_dy[4:1];
                sprite = piece_row(piece[2:0], sy);
                if (sprite[15 - sx]) rgb = piece[3] ? 24'h172738 : 24'hFFFAEC;
            end
        end

        if (x >= 32 && x < 224 && y >= 24 && y < 38) begin
            line_text = "FPGA CHESS      "; text_active = 1; tx = x - 10'd32; ty = y - 10'd24;
        end
        if (x >= 452 && x < 620) begin
            tx = x - 10'd452;
            if (y >= 88 && y < 102) begin
                line_text = "STAGE 01        "; text_active = 1; ty = y - 10'd88; ink = 24'h5DE4F2;
            end else if (y >= 112 && y < 126) begin
                line_text = "SANDBOX         "; text_active = 1; ty = y - 10'd112;
            end else if (y >= 152 && y < 166) begin
                line_text = "UP    KEY3      "; text_active = 1; ty = y - 10'd152;
            end else if (y >= 176 && y < 190) begin
                line_text = "RIGHT KEY2      "; text_active = 1; ty = y - 10'd176;
            end else if (y >= 200 && y < 214) begin
                line_text = "OK    KEY1      "; text_active = 1; ty = y - 10'd200;
            end else if (y >= 224 && y < 238) begin
                line_text = "BACK  KEY0      "; text_active = 1; ty = y - 10'd224;
            end else if (y >= 264 && y < 278) begin
                line_text = "RESET SW9       "; text_active = 1; ty = y - 10'd264;
            end else if (y >= 304 && y < 318) begin
                line_text = {"CURSOR ", (8'h41 + {5'b0,cursor[2:0]}),
                    (8'h38 - {5'b0,cursor[5:3]}), "       "};
                text_active = 1; ty = y - 10'd304;
            end else if (y >= 344 && y < 358) begin
                line_text = blocked ? "BLOCKED         " :
                    (selected ? "PICK TARGET     " : "PICK PIECE      ");
                text_active = 1; ty = y - 10'd344;
                ink = blocked ? 24'hFF6978 : 24'hFFC857;
            end else if (y >= 392 && y < 406) begin
                line_text = "NO MOVE RULES   "; text_active = 1; ty = y - 10'd392;
            end else if (y >= 416 && y < 430) begin
                line_text = "NO TURN LIMIT   "; text_active = 1; ty = y - 10'd416;
            end
        end
        if (text_active) begin
            text_column = tx / 10'd12;
            text_remainder = tx % 10'd12;
            char_index = text_column[3:0];
            glyph_x = text_remainder[3:1];
            glyph_y = ty[3:1];
            character = line_text[127 - char_index * 8 -: 8];
            glyph = font_row(character, glyph_y);
            if (glyph_x < 5 && glyph[4 - glyph_x]) rgb = ink;
        end
        // Coordinate labels use the same 5x7 font at 2x scale.
        for (i = 0; i < 8; i = i + 1) begin
            if (x >= 50 + i*48 && x < 60 + i*48 && y >= 458 && y < 472) begin
                dy = y - 10'd458;
                dx = x - (10'd50 + i[9:0]*10'd48);
                glyph = font_row(8'h41 + i[7:0], dy[3:1]);
                glyph_x = dx[3:1];
                if (glyph[4 - glyph_x]) rgb = 24'hA6B9C6;
            end
            if (x >= 14 && x < 24 && y >= 81 + i*48 && y < 95 + i*48) begin
                dy = y - (10'd81 + i[9:0]*10'd48);
                dx = x - 10'd14;
                glyph = font_row(8'h38 - i[7:0], dy[3:1]);
                glyph_x = dx[3:1];
                if (glyph[4 - glyph_x]) rgb = 24'hA6B9C6;
            end
        end
    end
endmodule
