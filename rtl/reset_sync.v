// Preserve the two synchronizer stages; LEDR[4] exposes the synchronized reset.
// Assert immediately; release only after two rising clock edges.
module reset_sync(input wire clk, input wire reset_request, output wire reset_out);
    (* preserve, altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [1:0] sync_ff;
    always @(posedge clk or posedge reset_request) begin
        if (reset_request) sync_ff <= 2'b11;
        else sync_ff <= {sync_ff[0], 1'b0};
    end
    assign reset_out = sync_ff[1];
endmodule
