// Active-low key -> one pulse after a stable press. Release must also debounce.
module button_event #(
    parameter integer DEBOUNCE_CYCLES = 252000
)(input wire clk, input wire reset, input wire key_n, output reg pressed);
    function integer clog2;
        input integer value;
        integer n;
        begin
            n = value - 1;
            for (clog2 = 0; n > 0; clog2 = clog2 + 1) n = n >> 1;
        end
    endfunction
    localparam integer COUNT_BITS = DEBOUNCE_CYCLES > 1 ? clog2(DEBOUNCE_CYCLES) : 1;
    localparam integer LAST_COUNT_VALUE = DEBOUNCE_CYCLES - 1;
    localparam [COUNT_BITS-1:0] LAST_COUNT = LAST_COUNT_VALUE[COUNT_BITS-1:0];
    (* altera_attribute = "-name SYNCHRONIZER_IDENTIFICATION FORCED_IF_ASYNCHRONOUS" *)
    reg sync_meta, sync_key;
    reg stable_key;
    reg [COUNT_BITS-1:0] count;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sync_meta <= 1'b1;
            sync_key <= 1'b1;
        end else begin
            sync_meta <= key_n;
            sync_key <= sync_meta;
        end
    end
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stable_key <= 1'b1;
            count <= 0;
            pressed <= 1'b0;
        end else begin
            pressed <= 1'b0;
            if (sync_key == stable_key) count <= 0;
            else if (count == LAST_COUNT) begin
                stable_key <= sync_key;
                count <= 0;
                pressed <= !sync_key;
            end else count <= count + 1'b1;
        end
    end
endmodule
