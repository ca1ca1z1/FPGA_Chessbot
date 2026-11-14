module reset_sync(input wire clk, input wire async_reset, output wire reset);
    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg [1:0] reset_pipe;
    always @(posedge clk or posedge async_reset) begin
        if (async_reset) reset_pipe <= 2'b11;
        else reset_pipe <= {reset_pipe[0], 1'b0};
    end
    assign reset = reset_pipe[1];
endmodule
