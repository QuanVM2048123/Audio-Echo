`timescale 1ns / 1ps

module delay_line #(
    parameter DATA_WIDTH = 16,
    parameter DELAY      = 4800
)(
    input  wire                         i_clk,
    input  wire                         i_rst_n,
    input  wire                         i_valid,
    input  wire signed [DATA_WIDTH-1:0] i_sample,
    output reg                          o_valid,
    output reg  signed [DATA_WIDTH-1:0] o_current,
    output reg  signed [DATA_WIDTH-1:0] o_delayed
);
    initial begin
        o_current = 0;
        o_delayed = 0;
    end

    generate
        if (DELAY == 0) begin : g_no_delay

            always @(posedge i_clk) begin
                if (!i_rst_n) o_valid <= 1'b0;
                else          o_valid <= i_valid;
            end

            always @(posedge i_clk) begin
                if (i_valid) begin
                    o_current <= i_sample;
                    o_delayed <= i_sample;
                end
            end
        end else begin : g_delay
        
            localparam ADDR_W = (DELAY > 1) ? $clog2(DELAY) : 1;

            reg [DATA_WIDTH-1:0] r_mem [0:DELAY-1];
            reg [ADDR_W-1:0]     r_ptr;
            reg                  r_primed;
            
            always @(posedge i_clk) begin
                if (!i_rst_n) begin
                    r_ptr    <= {ADDR_W{1'b0}};
                    r_primed <= 1'b0;
                    o_valid  <= 1'b0;
                end else begin
                    o_valid  <= i_valid;
                    if (i_valid) begin
                        if (r_ptr == DELAY - 1) begin
                            r_ptr    <= {ADDR_W{1'b0}};
                            r_primed <= 1'b1;
                        end else begin
                            r_ptr <= r_ptr + 1'b1;
                        end
                    end
                end
            end


            always @(posedge i_clk) begin
                if (i_valid) begin
                    o_current    <= i_sample;
                    o_delayed    <= r_primed ? r_mem[r_ptr] : {DATA_WIDTH{1'b0}};
                    r_mem[r_ptr] <= i_sample;
                end
            end
        end
    endgenerate

endmodule
