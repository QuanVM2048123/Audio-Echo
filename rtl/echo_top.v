`timescale 1ns / 1ps

module echo_top #(
    parameter DATA_WIDTH = 16,
    parameter DELAY      = 4800
)(
    input  wire                         i_clk,
    input  wire                         i_rst_n,
    input  wire                         i_valid,
    input  wire signed [DATA_WIDTH-1:0] i_sample,
    output wire                         o_valid,
    output wire signed [DATA_WIDTH-1:0] o_sample
);

    //=============================
    // INTERNAL WIRES
    //=============================
    wire                         w_delay_valid;
    wire signed [DATA_WIDTH-1:0] w_current;
    wire signed [DATA_WIDTH-1:0] w_delayed;

    //=============================
    // DELAY MODULE
    //=============================
    delay_line #(
        .DATA_WIDTH (DATA_WIDTH),
        .DELAY      (DELAY)
    ) u_delay_line (
        .i_clk     (i_clk),
        .i_rst_n   (i_rst_n),
        .i_valid   (i_valid),
        .i_sample  (i_sample),
        .o_valid   (w_delay_valid),
        .o_current (w_current),
        .o_delayed (w_delayed)
    );


    //=============================
    // ECHO MODULE
    //=============================
    echo #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_echo (
        .i_clk     (i_clk),
        .i_rst_n   (i_rst_n),
        .i_valid   (w_delay_valid),
        .i_current (w_current),
        .i_delayed (w_delayed),
        .o_valid   (o_valid),
        .o_sample  (o_sample)
    );

endmodule
