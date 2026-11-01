`timescale 1ns / 1ps

module tb_echo_top;
    parameter DATA_WIDTH    = 16;
    parameter DELAY         = 4800;
    parameter MAX_SAMPLES   = 262144;
    parameter INPUT_FILE    = "input.hex";
    parameter OUTPUT_FILE   = "rtl_output.hex";
    parameter EXPECTED_FILE = "expected_output.hex";

    reg                          i_clk    = 1'b0;
    reg                          i_rst_n  = 1'b0;
    reg                          i_valid  = 1'b0;
    reg  signed [DATA_WIDTH-1:0] i_sample = 0;
    wire                         o_valid;
    wire signed [DATA_WIDTH-1:0] o_sample;

    always #5 i_clk = ~i_clk;

    echo_top #(
        .DATA_WIDTH (DATA_WIDTH),
        .DELAY      (DELAY)
    ) u_dut (
        .i_clk    (i_clk),
        .i_rst_n  (i_rst_n),
        .i_valid  (i_valid),
        .i_sample (i_sample),
        .o_valid  (o_valid),
        .o_sample (o_sample)
    );


    // ============================================================
    // Memories
    // ============================================================

    reg [15:0] r_input    [0:MAX_SAMPLES-1];
    reg [15:0] r_expected [0:MAX_SAMPLES-1];

    integer fout;
    integer i;
    integer in_count   = 0;
    integer exp_count  = 0;
    integer out_count  = 0;
    integer mismatches = 0;
    reg     compare_en = 1'b0;


    // ============================================================
    // Helpers
    // ============================================================

    // Convert a 4-bit value to an uppercase ASCII hex character
    function [7:0] hexchar(input [3:0] n);
        begin
            if (n < 10) hexchar = "0" + n;
            else        hexchar = "A" + (n - 10);
        end
    endfunction

    // Write one sample as 4 hex digits followed by a newline
    task write_hex16(input integer fd, input [15:0] v);
        begin
            $fwrite(fd, "%c%c%c%c\n", hexchar(v[15:12]), hexchar(v[11:8]), hexchar(v[7:4]), hexchar(v[3:0]));
        end
    endtask


    // ============================================================
    // Checker
    // ============================================================

    always @(posedge i_clk) begin
        if (o_valid === 1'b1) begin

            // Write the RTL sample to the output file
            write_hex16(fout, o_sample[15:0]);

            // Compare with the golden model output
            if (compare_en) begin
                if (out_count >= exp_count) begin
                    mismatches = mismatches + 1;

                    if (mismatches <= 10)
                        $display("MISMATCH: RTL has output #%0d but %s has no such line",
                                 out_count, EXPECTED_FILE);
                end
                else if (r_expected[out_count] !== o_sample[15:0]) begin
                    mismatches = mismatches + 1;

                    if (mismatches <= 10)
                        $display("MISMATCH at sample %0d: RTL=%04h expected=%04h",
                                 out_count, o_sample[15:0], r_expected[out_count]);
                end
            end

            out_count = out_count + 1;
        end
    end

    // ============================================================
    // Main test
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // Load input and expected output files
        // --------------------------------------------------------

        $readmemh(INPUT_FILE, r_input);

        // Count the samples: stop at the first entry that is still X
        while (in_count < MAX_SAMPLES && (^r_input[in_count] !== 1'bx))
            in_count = in_count + 1;

        if (in_count == 0) begin
            $display("ERROR: %s is missing or empty (put it in the simulator working directory)", INPUT_FILE);
            $finish;
        end

        if (in_count == MAX_SAMPLES)
            $display("WARNING: input may be longer than MAX_SAMPLES=%0d, increase it", MAX_SAMPLES);

        $readmemh(EXPECTED_FILE, r_expected);

        while (exp_count < MAX_SAMPLES && (^r_expected[exp_count] !== 1'bx))
            exp_count = exp_count + 1;

        compare_en = (exp_count != 0);

        if (!compare_en)
            $display("INFO: %s not found, skipping comparison with golden model", EXPECTED_FILE);

        // --------------------------------------------------------
        // Open output file
        // --------------------------------------------------------

        fout = $fopen(OUTPUT_FILE, "w");

        if (fout == 0) begin
            $display("ERROR: cannot create %s", OUTPUT_FILE);
            $finish;
        end

        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        repeat (4)
            @(posedge i_clk);

        @(negedge i_clk);
        i_rst_n = 1'b1;

        // --------------------------------------------------------
        // Send all samples, one per clock cycle
        // --------------------------------------------------------

        for (i = 0; i < in_count; i = i + 1) begin
            @(negedge i_clk);
            i_valid  = 1'b1;
            i_sample = r_input[i];
        end

        @(negedge i_clk);
        i_valid = 1'b0;

        // --------------------------------------------------------
        // Flush pipeline
        // --------------------------------------------------------

        repeat (10)
            @(posedge i_clk);

        $fclose(fout);

        // --------------------------------------------------------
        // Summary
        // --------------------------------------------------------

        if (compare_en && exp_count > out_count) begin
            mismatches = mismatches + 1;

            $display("MISMATCH: %s has %0d samples, RTL produced only %0d",
                     EXPECTED_FILE, exp_count, out_count);
        end

        $display("");
        $display("Input samples  : %0d", in_count);
        $display("Output samples : %0d (written to %s)", out_count, OUTPUT_FILE);
        $display("DELAY (D)      : %0d", DELAY);

        if (in_count != out_count)
            $display("FAIL: output count differs from input count");
        else if (compare_en && mismatches != 0)
            $display("FAIL: %0d mismatches vs %s", mismatches, EXPECTED_FILE);
        else if (compare_en)
            $display("PASS: RTL output matches %s", EXPECTED_FILE);
        else
            $display("DONE: compare rtl_output.hex with expected_output.hex yourself");
        $display("");
        
        $finish;
    end
endmodule
