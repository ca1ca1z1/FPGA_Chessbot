`timescale 1ns/1ps
// Exercises the actual board top, vendor PLL and production 10 ms debounce value.
module tb_top;
    reg CLOCK_50=0;
    always #10 CLOCK_50=~CLOCK_50;
    reg [3:0] KEY=15;
    reg [9:0] SW=10'b1000000000;
    wire [9:0] LEDR;
    wire [7:0] VGA_R,VGA_G,VGA_B;
    wire VGA_HS,VGA_VS,VGA_CLK,VGA_BLANK_N,VGA_SYNC_N;
    reg passed=0;
    DE1_SoC dut(CLOCK_50,KEY,SW,LEDR,VGA_R,VGA_G,VGA_B,
        VGA_HS,VGA_VS,VGA_CLK,VGA_BLANK_N,VGA_SYNC_N);
    task check;
        input condition; input [511:0] message;
        begin if(condition!==1'b1) begin $display("FAIL tb_top: %0s",message); $stop; end end
    endtask
    initial begin
        #2; SW[9]=0; #2; SW[9]=1;
        #100; SW[9]=0;
        wait(LEDR[9]===1 && LEDR[8]===0);
        repeat(5) @(negedge VGA_CLK); #1;
        check(LEDR[5:0]==52 && !LEDR[6] && !LEDR[7],"board top starts at e2");
        check(VGA_SYNC_N===0,"separate-sync DAC configuration");
        KEY[1]=0;
        repeat(251999) @(negedge VGA_CLK); #1;
        check(!LEDR[6],"production debounce does not accept before 10 ms");
        repeat(16) @(negedge VGA_CLK); #1;
        check(LEDR[6],"production debounce accepts stable KEY1 press");
        repeat(252020) @(negedge VGA_CLK); #1;
        check(LEDR[6],"held confirm does not repeat and deselect");
        SW[9]=1; #5;
        check(LEDR[8] && !LEDR[6] && LEDR[5:0]==52,"SW9 resets game even when PLL clock stops");
        KEY=15; #100; SW[9]=0;
        wait(LEDR[9]===1 && LEDR[8]===0);
        repeat(5) @(negedge VGA_CLK); #1;
        check(LEDR[5:0]==52 && !LEDR[6],"PLL relocks and game restarts after SW9 release");
        passed=1; $display("PASS tb_top: actual top wiring, 10 ms debounce, held key, PLL reset/relock"); $finish;
    end
    initial begin #30000000; $display("FAIL tb_top watchdog"); $stop; end
endmodule
