`timescale 1ns/1ps
module tb_button;
    reg clk=0, reset=1, key_n=1;
    always #5 clk=~clk;
    wire pressed;
    integer count=0;
    reg previous=0, passed=0;
    button_event #(.DEBOUNCE_CYCLES(4)) dut(clk,reset,key_n,pressed);
    task check;
        input condition; input [511:0] message;
        begin if(condition!==1'b1) begin $display("FAIL tb_button: %0s",message); $stop; end end
    endtask
    always @(negedge clk) begin
        if(!reset) begin
            if(pressed) count=count+1;
            check(!(pressed && previous),"press pulse lasts only one clock");
        end
        previous=pressed;
    end
    task cycles;
        input integer n;
        begin repeat(n) @(posedge clk); #1; end
    endtask
    initial begin
        #2; reset=0; #2; reset=1; cycles(3); reset=0;
        cycles(4); key_n=0; cycles(1); key_n=1; cycles(1);
        key_n=0; cycles(2); key_n=1; cycles(10);
        check(count==0,"short bouncing presses are ignored");
        key_n=0; cycles(12); check(count==1,"stable press produces one event");
        cycles(100); check(count==1,"holding never auto-repeats");
        key_n=1; cycles(1); key_n=0; cycles(12);
        check(count==1,"release bounce does not rearm");
        key_n=1; cycles(12); key_n=0; cycles(12);
        check(count==2,"debounced release allows next press");
        reset=1; cycles(3); check(!pressed,"reset clears pulse");
        key_n=1; reset=0; cycles(12); check(count==2,"reset/release does not create a press");
        passed=1; $display("PASS tb_button: bounce, hold, release, repeat press, reset"); $finish;
    end
    initial begin #100000; $display("FAIL tb_button watchdog"); $stop; end
endmodule
