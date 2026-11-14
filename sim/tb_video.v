`timescale 1ns/1ps
module tb_video;
    reg clk=0, reset=1;
    always #5 clk=~clk;
    wire [9:0] x,y;
    wire visible,hs_n,vs_n,vblank_start;
    integer frame, px, py, visible_count, hs_count, vs_count, blank_events;
    reg passed=0;
    vga_timing dut(clk,reset,x,y,visible,hs_n,vs_n,vblank_start);
    task check;
        input condition; input [511:0] message;
        begin if(condition!==1'b1) begin $display("FAIL tb_video: %0s at %d,%d",message,x,y); $stop; end end
    endtask
    initial begin
        #2; reset=0; #2; reset=1; @(negedge clk); #1; reset=0;
        for(frame=0;frame<2;frame=frame+1) begin
            visible_count=0; hs_count=0; vs_count=0; blank_events=0;
            for(py=0;py<525;py=py+1) for(px=0;px<800;px=px+1) begin
                check(x==px && y==py,"raster coordinates and frame wrap");
                check(visible===((px<640)&&(py<480)),"active-video boundaries");
                check(hs_n===!((px>=656)&&(px<752)),"96-pixel HS pulse and porches");
                check(vs_n===!((py>=490)&&(py<492)),"2-line VS pulse and porches");
                visible_count=visible_count+visible;
                hs_count=hs_count+!hs_n; vs_count=vs_count+!vs_n;
                blank_events=blank_events+vblank_start;
                @(negedge clk); #1;
            end
            check(visible_count==307200,"640x480 active pixels");
            check(hs_count==50400 && vs_count==1600 && blank_events==1,"frame pulse totals");
        end
        passed=1; $display("PASS tb_video: two full 800x525 frames, porches, pulses, visible area"); $finish;
    end
    initial begin #10000000; $display("FAIL tb_video watchdog"); $stop; end
endmodule
