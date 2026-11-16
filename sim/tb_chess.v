// Based on the FPGAcademy DESim testbench template:
// Copyright (c) 2020 FPGAcademy
// Please see license at https://github.com/fpgacademy/DESim
//
// Plain ModelSim testbench for the top-level "chess" module.
// It only drives the inputs. Look at the waveform to see the results:
//   LEDR[3:0] = piece on the square chosen by SW[5:0]
//   LEDR[8:5] = castling rights, LEDR[9] = side to move

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
    chess DUT (.CLOCK_50(CLOCK_50), .SW(SW), .KEY(KEY), .LEDR(LEDR));

    initial begin
        // Press KEY[0] (active low) for 3 clocks, then release.
        #5;
        KEY[0] = 0;
        repeat (3) @(posedge CLOCK_50);
        @(negedge CLOCK_50); KEY[0] = 1;
        repeat (3) @(posedge CLOCK_50);

        // Step through some squares by changing the switches.
        SW[5:0] = 6'd0;   #40;    // a1
        SW[5:0] = 6'd4;   #40;    // e1
        SW[5:0] = 6'd12;  #40;    // e2
        SW[5:0] = 6'd30;  #40;    // g4
        SW[5:0] = 6'd59;  #40;    // d8
        SW[5:0] = 6'd60;  #40;    // e8
        SW[5:0] = 6'd63;  #40;    // h8

        $stop;   // pauses ModelSim so you can inspect the waveform
    end

endmodule

`default_nettype wire
