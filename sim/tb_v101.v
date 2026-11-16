`timescale 1ns/1ps
module tb_v101;
    reg clk=0;
    always #10 clk=~clk;
    reg [3:0] keys=15;
    reg [9:0] switches=0;
    wire [9:0] leds;
    reg passed=0;
    integer offset, square;
    reg [3:0] expected;
    chess dut(clk,keys,switches,leds);
    task check;
        input ok; input [511:0] message;
        begin if(ok!==1'b1) begin $display("FAIL: %0s",message); $stop; end end
    endtask
    function [3:0] initial_piece;
        input integer index;
        reg [3:0] back;
        begin
            case(index%8)
                0,7:back=4; 1,6:back=2; 2,5:back=3; 3:back=5; default:back=6;
            endcase
            if(index<8) initial_piece=back;
            else if(index<16) initial_piece=1;
            else if(index<48) initial_piece=0;
            else if(index<56) initial_piece=9;
            else initial_piece=back+8;
        end
    endfunction
    initial begin
        // Try release before, on and after clock edges. This checks digital
        // synchronization behavior; RTL simulation cannot model metastability.
        for(offset=0;offset<20;offset=offset+1) begin
            @(negedge clk); #2; keys[0]=0; #1;
            check(dut.board_reset===1,"asynchronous assertion");
            repeat(3) @(negedge clk);
            #(offset); keys[0]<=1;
            @(posedge clk); #1;
            check(dut.board_reset===1,"reset held through first release edge");
            @(posedge clk); #1;
            check(dut.board_reset===0,"reset released after second edge");
            @(posedge clk); #1;
            for(square=0;square<64;square=square+1) begin
                switches[5:0]=square; #1;
                expected=initial_piece(square);
                check(leds[3:0]===expected,"initial piece via top-level switches and LEDs");
                check(leds[9:4]===6'b011110,"initial turn, castling and unused LED");
            end
        end
        passed=1; $display("PASS v1.0.1: reset phase sweep and all 64 top-level reads"); $finish;
    end
    initial begin #100000; $display("FAIL watchdog"); $stop; end
endmodule
