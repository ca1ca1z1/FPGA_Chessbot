// button_press.v
// Turns one DE1-SoC push button into a clean one-clock pulse per press.
//
// The KEY buttons are active low (pressed = 0) and not synchronized to the
// clock. This module synchronizes the input, waits until it has held a new
// value for 2^DEBOUNCE_BITS clocks, and pulses `pressed` for one clock when
// the stable value changes from released to pressed.

module button_press #(
    parameter DEBOUNCE_BITS = 20          // 2^20 clocks at 50 MHz is about 21 ms
) (
    input  wire clock,
    input  wire reset,
    input  wire button_n,                 // raw button, active low
    output reg  pressed                   // 1 for one clock per press
);

    (* preserve, altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [1:0] sync_ff;                    // two-stage synchronizer
    reg       stable_level;               // debounced button level (1 = released)
    reg [DEBOUNCE_BITS-1:0] hold_counter;

    always @(posedge clock) begin
        sync_ff <= {sync_ff[0], button_n};
        pressed <= 1'b0;

        if (reset) begin
            stable_level <= 1'b1;
            hold_counter <= {DEBOUNCE_BITS{1'b0}};
        end else if (sync_ff[1] == stable_level) begin
            hold_counter <= {DEBOUNCE_BITS{1'b0}};          // no change pending
        end else begin
            hold_counter <= hold_counter + 1'b1;
            if (&hold_counter) begin                        // new level held long enough
                stable_level <= sync_ff[1];
                pressed      <= (sync_ff[1] == 1'b0);
            end
        end
    end

endmodule
