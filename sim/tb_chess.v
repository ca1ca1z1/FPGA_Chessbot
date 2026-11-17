// Based on the FPGAcademy DESim testbench template:
// Copyright (c) 2020 FPGAcademy
// Please see license at https://github.com/fpgacademy/DESim
//
// Plain ModelSim testbench for the top-level "chess" module.
// It only drives the inputs. Look at the waveform to see the results:
//   LEDR[3:0] = piece on the cursor square, LEDR[5] = piece selected,
//   LEDR[6] = move legal, LEDR[9] = side to move
// It plays e2-e4 with the buttons: KEY[3] right, KEY[2] up, KEY[1] confirm.

`timescale 1ns / 1ns
`default_nettype none

module tb_chess();

    reg        CLOCK_50 = 0;          // DE-series 50 MHz clock
    reg  [9:0] SW       = 0;          // DE-series SW switches
    reg  [3:0] KEY      = 4'b1111;    // DE-series pushbutton keys (1 = not pressed)
    wire [9:0] LEDR;                  // DE-series LEDs

    // create the 50 MHz clock signal
    always #10
        CLOCK_50 <= ~CLOCK_50;

    // the design being tested (the Quartus top-level entity)
    // Short debounce so each button press only needs a few clocks.
    chess #(.DEBOUNCE_BITS(2)) DUT (.CLOCK_50(CLOCK_50), .SW(SW), .KEY(KEY), .LEDR(LEDR),
                                    .HEX0(), .HEX1(), .HEX2(), .HEX3(), .HEX4(), .HEX5());

    // Press and release one button.
    task press;
        input integer key_number;
        begin
            @(negedge CLOCK_50); KEY[key_number] = 0;
            repeat (12) @(negedge CLOCK_50);
            KEY[key_number] = 1;
            repeat (12) @(negedge CLOCK_50);
        end
    endtask

    initial begin
        // Press KEY[0] (active low) for 3 clocks, then release.
        #5;
        KEY[0] = 0;
        repeat (3) @(posedge CLOCK_50);
        @(negedge CLOCK_50); KEY[0] = 1;
        repeat (3) @(posedge CLOCK_50);

        // Move the cursor from a1 to e2, select the pawn, go up to e4, confirm.
        repeat (4) press(3);                      // a1 -> e1
        press(2);                                 // e1 -> e2
        press(1);                                 // select the e2 pawn
        repeat (80) @(negedge CLOCK_50);          // legal targets are filled in (64 clocks)
        repeat (2) press(2);                      // e2 -> e4, LEDR[6] turns on
        press(1);                                 // make the move
        repeat (20) @(negedge CLOCK_50);

        $stop;   // pauses ModelSim so you can inspect the waveform
    end

endmodule

`default_nettype wire
