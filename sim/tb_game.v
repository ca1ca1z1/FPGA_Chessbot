`timescale 1ns/1ps
module tb_game;
    reg clk=0, reset=1, up=0, right=0, confirm=0, cancel=0;
    always #5 clk=~clk;
    wire [255:0] board_state;
    wire [5:0] cursor, source, last_from, last_to;
    wire selected, blocked, last_valid;
    reg passed=0;
    integer i, r, c;
    reg [255:0] saved;
    reg [3:0] expected_piece;
    chess_game dut(clk,reset,up,right,confirm,cancel,board_state,cursor,source,
        selected,blocked,last_from,last_to,last_valid);
    task check;
        input condition; input [511:0] message;
        begin if (condition !== 1'b1) begin $display("FAIL tb_game: %0s",message); $stop; end end
    endtask
    task event_key;
        input [3:0] keys;
        begin
            @(negedge clk); {up,right,confirm,cancel}=keys;
            @(negedge clk); {up,right,confirm,cancel}=0;
        end
    endtask
    task go_to;
        input [5:0] target;
        integer guard;
        begin
            guard=0;
            while(cursor[5:3] != target[5:3] && guard<8) begin event_key(4'b1000); guard=guard+1; end
            guard=0;
            while(cursor[2:0] != target[2:0] && guard<8) begin event_key(4'b0100); guard=guard+1; end
            check(cursor===target,"navigation reaches target");
        end
    endtask
    function [3:0] back_piece;
        input integer column;
        begin
            case(column)
                0,7: back_piece=4; 1,6: back_piece=2; 2,5: back_piece=3;
                3: back_piece=5; default: back_piece=6;
            endcase
        end
    endfunction
    initial begin
        #2; reset=0; #2; reset=1;
        repeat(3) @(negedge clk); reset=0;
        check(cursor==52 && !selected && !last_valid,"reset UI is e2, unselected");
        for(i=0;i<64;i=i+1) begin
            if(i<8) expected_piece=back_piece(i)+8;
            else if(i<16) expected_piece=9;
            else if(i<48) expected_piece=0;
            else if(i<56) expected_piece=1;
            else expected_piece=back_piece(i-56);
            check(board_state[i*4+:4]===expected_piece,"all 64 initial squares and orientation");
        end
        saved=board_state;
        for(r=0;r<8;r=r+1) for(c=0;c<8;c=c+1) begin
            go_to(r*8+c);
            event_key(4'b1000);
            check(cursor==(((r+7)%8)*8+c),"up wraps without changing file");
            go_to(r*8+c);
            event_key(4'b0100);
            check(cursor==(r*8+(c+1)%8),"right wraps without changing rank");
        end
        check(board_state===saved,"navigation never edits the board");
        go_to(28); event_key(4'b0010);
        check(!selected && board_state===saved,"empty square cannot become source");
        go_to(52); event_key(4'b0010); check(selected && source==52,"select e2 pawn");
        event_key(4'b0010); check(!selected && board_state===saved,"same-square confirm does not erase");
        event_key(4'b0010); go_to(53); event_key(4'b0010);
        check(selected && blocked && board_state===saved,"friendly overwrite is rejected");
        event_key(4'b0001); check(!selected && !blocked && cursor==53,"cancel preserves cursor and board");
        go_to(52); event_key(4'b0010); go_to(36); event_key(4'b0010);
        check(board_state[52*4+:4]==0 && board_state[36*4+:4]==1,"e2-e4 moves pawn");
        check(!selected && last_valid && last_from==52 && last_to==36,"last-move metadata");
        // No turn/rule engine yet: a white pawn can immediately capture e7.
        event_key(4'b0010); go_to(12); event_key(4'b0010);
        check(board_state[12*4+:4]==1 && board_state[36*4+:4]==0,"sandbox capture replaces opponent");
        go_to(0); event_key(4'b0010); go_to(24); event_key(4'b0010);
        check(board_state[0+:4]==0 && board_state[24*4+:4]==12,"black pieces can also move");
        saved=board_state;
        event_key(4'b0010); event_key(4'b1111);
        check(!selected && cursor==24 && board_state===saved,"cancel wins simultaneous events");
        event_key(4'b1010);
        check(selected && cursor==24,"confirm wins over movement");
        event_key(4'b0001); event_key(4'b1100);
        check(cursor==16,"up wins over right");
        reset=1; @(negedge clk); reset=0;
        check(cursor==52 && !selected && !last_valid && !blocked,"reset clears all interaction state");
        check(board_state[0+:4]==12 && board_state[52*4+:4]==1,"reset restores moved and captured pieces");
        passed=1; $display("PASS tb_game: initial board, all-square wraps, moves/captures/cancel/reset/priority"); $finish;
    end
    initial begin #1000000; $display("FAIL tb_game watchdog"); $stop; end
endmodule
