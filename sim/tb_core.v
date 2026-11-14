`timescale 1ns/1ps
module tb_core;
    reg clk=0, reset=1;
    always #20 clk=~clk; // Functional core simulation; PLL frequency tested separately.
    reg [3:0] key_n=15;
    wire [7:0] red,green,blue;
    wire hs_n,vs_n,blank_n;
    wire [5:0] cursor;
    wire selected,blocked;
    reg passed=0;
    reg [255:0] initial_board;
    integer f,px,py;
    chess_core #(.DEBOUNCE_CYCLES(4)) dut(clk,reset,key_n,
        red,green,blue,hs_n,vs_n,blank_n,cursor,selected,blocked);
    task check;
        input condition; input [511:0] message;
        begin if(condition!==1'b1) begin $display("FAIL tb_core: %0s",message); $stop; end end
    endtask
    task press;
        input integer key;
        begin
            @(negedge clk); #1; key_n[key]=0;
            repeat(12) @(negedge clk); #1; key_n[key]=1;
            repeat(12) @(negedge clk); #1;
        end
    endtask
    task capture;
        input [511:0] filename;
        begin
            // Wait for a complete frame boundary, then sample the real registered
            // VGA outputs while their corresponding timing coordinates are stable.
            @(negedge clk); #1;
            // The output pipeline is exactly one pixel behind the raster counter.
            while(dut.x!=1 || dut.y!=0) begin @(negedge clk); #1; end
            f=$fopen(filename,"wb");
            check(f!=0,"frame file opens");
            $fwrite(f,"P6\n640 480\n255\n");
            for(py=0;py<525;py=py+1) for(px=0;px<800;px=px+1) begin
                check(blank_n===((px<640)&&(py<480)),"registered BLANK tracks pixel");
                check(hs_n===!((px>=656)&&(px<752)),"registered HS tracks pixel");
                check(vs_n===!((py>=490)&&(py<492)),"registered VS tracks pixel");
                check((^{red,green,blue})!==1'bx,"RGB has no X/Z");
                if(blank_n) $fwrite(f,"%c%c%c",red,green,blue);
                else check({red,green,blue}==0,"RGB is black throughout blanking");
                if(px==45 && py==75) check({red,green,blue}==24'hE5D8B9,"a8 is a light square");
                if(px==93 && py==75) check({red,green,blue}==24'h648774,"b8 is a dark square");
                @(negedge clk); #1;
            end
            $fclose(f);
        end
    endtask
    initial begin
        #2; reset=0; #2; reset=1;
        repeat(4) @(negedge clk); #1; reset=0;
        initial_board=dut.board_state;
        capture("initial.ppm");
        press(1); check(selected,"KEY1 selects e2");
        check(!dut.view_selected,"selection snapshot stays unchanged during active video");
        capture("selected.ppm");
        check(dut.view_selected,"selection appears in next frame");
        press(3); press(3); check(cursor==36,"KEY3 twice reaches e4");
        press(1); check(!selected && dut.board_state[36*4+:4]==1,"physical key path commits e2-e4");
        check(dut.view_board===initial_board,"board snapshot stays stable until vblank");
        capture("moved.ppm");
        check(dut.view_board===dut.board_state,"display catches up at vblank");
        press(1); press(0); check(!selected,"KEY0 cancels");
        press(2); check(cursor==37,"KEY2 moves right");
        reset=1; repeat(3) @(negedge clk); #1; reset=0;
        check(dut.board_state===initial_board && cursor==52,"core reset restores initial position");
        passed=1; $display("PASS tb_core: debounced inputs, atomic snapshots, RGB/HS/VS/BLANK, 3 frame captures"); $finish;
    end
    initial begin #150000000; $display("FAIL tb_core watchdog"); $stop; end
endmodule
