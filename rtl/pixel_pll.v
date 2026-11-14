// Cyclone V PLL primitive. The same parameters drive synthesis and Intel's
// precompiled altera_lnsim_ver simulation model. User RTL remains Verilog-2001.
module pixel_pll(input wire refclk, input wire reset, output wire pixel_clk, output wire locked);
    altera_pll #(
        .reference_clock_frequency("50.0 MHz"), .number_of_clocks(1),
        .output_clock_frequency0("25.2 MHz"), .phase_shift0("0 ps"),
        .duty_cycle0(50), .pll_type("General"), .operation_mode("direct"),
        .fractional_vco_multiplier("false")
    ) pll (
        .refclk(refclk), .rst(reset), .outclk(pixel_clk), .locked(locked),
        .refclk1(1'b0), .fbclk(1'b0), .phase_en(1'b0), .updn(1'b0),
        .num_phase_shifts(3'b0), .scanclk(1'b0), .cntsel(5'b0),
        .reconfig_to_pll(64'b0), .extswitch(1'b0), .adjpllin(1'b0), .cclk(1'b0),
        .fboutclk(), .phase_done(), .reconfig_from_pll(), .activeclk(),
        .clkbad(), .phout(), .lvds_clk(), .loaden(), .extclk_out(), .cascade_out(), .zdbfbclk()
    );
endmodule
