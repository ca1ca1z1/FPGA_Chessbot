`timescale 1ns/1ps
module tb_pll;
    reg refclk=0, async_reset=1, pll_reset=1;
    always #10 refclk=~refclk;
    wire pixel_clk,locked,reset;
    reg passed=0;
    real first_edge, period_ns;
    pixel_pll dut(refclk,pll_reset,pixel_clk,locked);
    reset_sync rst(pixel_clk,async_reset | !locked,reset);
    initial begin
        #2; async_reset=0; #2; async_reset=1;
        #100; pll_reset=0;
        wait(locked===1'b1);
        repeat(5) @(negedge pixel_clk);
        #1; async_reset=0;
        @(posedge pixel_clk); #1;
        if(reset!==1) begin $display("FAIL tb_pll: reset released too early"); $stop; end
        @(posedge pixel_clk); #1;
        if(reset!==0) begin $display("FAIL tb_pll: reset not released on second edge"); $stop; end
        @(posedge pixel_clk); first_edge=$realtime;
        repeat(100) @(posedge pixel_clk);
        period_ns=($realtime-first_edge)/100.0;
        if(period_ns<39.67 || period_ns>39.70) begin
            $display("FAIL tb_pll: expected 25.2 MHz, period=%f ns",period_ns); $stop;
        end
        #3; async_reset=1; #1;
        if(reset!==1) begin $display("FAIL tb_pll: asynchronous reset assertion"); $stop; end
        passed=1; $display("PASS tb_pll: vendor PLL locked, period=%f ns, reset synchronization",period_ns); $finish;
    end
    initial begin #200000; $display("FAIL tb_pll watchdog: no PLL lock"); $stop; end
endmodule
