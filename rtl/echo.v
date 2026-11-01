`timescale 1ns / 1ps

module echo #(
    parameter DATA_WIDTH = 16
)(
    input  wire                         i_clk,
    input  wire                         i_rst_n,
    input  wire                         i_valid,
    input  wire signed [DATA_WIDTH-1:0] i_current,
    input  wire signed [DATA_WIDTH-1:0] i_delayed,
    output reg                          o_valid,
    output reg  signed [DATA_WIDTH-1:0] o_sample
);
    // Sum width for addition between i_current and w_delayed_half
    localparam SUM_W = DATA_WIDTH + 1;

    // Signed 16-bit limit
    localparam [DATA_WIDTH-1:0] MAX_VAL = {1'b0, {(DATA_WIDTH-1){1'b1}}};   // 0x7FFF
    localparam [DATA_WIDTH-1:0] MIN_VAL = {1'b1, {(DATA_WIDTH-1){1'b0}}};   // 0x8000

    // The delayed sample is arithmetically right-shifted to half the value
    wire signed [DATA_WIDTH-1:0] w_delayed_half = i_delayed >>> 1;

    // Extend the sign to 17 bits before adding to prevent overflow
    wire signed [SUM_W-1:0] w_sum = {i_current[DATA_WIDTH-1], i_current} + {w_delayed_half[DATA_WIDTH-1],  w_delayed_half};
    
    // Saturation
    // 2'b01 -> overflow  -> MAX_VAL
    // 2'b10 -> underflow -> MIN_VAL
    reg [DATA_WIDTH-1:0] r_saturated;

    always @(*) begin
        if (w_sum[SUM_W-1:SUM_W-2] == 2'b01) begin
            r_saturated = MAX_VAL;
        end 
        else if (w_sum[SUM_W-1:SUM_W-2] == 2'b10) begin
            r_saturated = MIN_VAL;
        end 
        else begin
            r_saturated = w_sum[DATA_WIDTH-1:0];
        end
    end

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            o_valid <= 1'b0;
        end else begin
            o_valid <= i_valid;
        end
    end

    always @(posedge i_clk) begin
        if (i_valid)
            o_sample <= r_saturated;
    end

    initial o_sample = 0;

endmodule