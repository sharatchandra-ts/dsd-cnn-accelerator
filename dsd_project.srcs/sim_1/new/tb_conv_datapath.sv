`timescale 1ns/1ps

module tb_conv_datapath;
    reg clk;
    reg rst_n;
    reg clear;
    reg start;
    
    // Flattened 72-bit wires/regs to match conv_datapath port definition
    reg  [71:0] data_flat;
    reg  [71:0] weight_flat;
    
    wire [31:0] result;
    wire valid_out;

    // Local unpacked arrays for convenient test stimulus writing in procedural blocks
    reg  [7:0]  data   [0:8];
    reg  [7:0]  weight [0:8];

    // Combinational packing of unpacked arrays into 72-bit vectors
    always @* begin
        data_flat   = {data[8], data[7], data[6], data[5], data[4], data[3], data[2], data[1], data[0]};
        weight_flat = {weight[8], weight[7], weight[6], weight[5], weight[4], weight[3], weight[2], weight[1], weight[0]};
    end

    // Instantiate Conv Datapath with flattened ports
    conv_datapath uut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .start(start),
        .data(data_flat),
        .weight(weight_flat),
        .result(result),
        .valid_out(valid_out)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    integer i;
    initial begin
        clk = 0;
        rst_n = 0;
        clear = 0;
        start = 0;
        for (i = 0; i < 9; i = i + 1) begin
            data[i] = 0;
            weight[i] = 0;
        end

        #12;
        rst_n = 1;
        #10;

        // Test 1: Uniform constant inputs (all ones)
        $display("--- Test 1: All Ones Window ---");
        clear = 1; #10;
        clear = 0;
        for (i = 0; i < 9; i = i + 1) begin
            data[i]   = 8'sd1;
            weight[i] = 8'sd1;
        end
        start = 1; #10;
        start = 0; #10;
        $display("Result: %0d (Expected: 9)", $signed(result));
        assert($signed(result) == 9) else $error("Test 1 Failed");

        // Test 2: Mixed positive and negative operands
        $display("--- Test 2: Mixed Positive/Negative Window ---");
        clear = 1; #10;
        clear = 0;
        data[0] = 8'sd2;   weight[0] = 8'sd3;   //  6
        data[1] = -8'sd4;  weight[1] = 8'sd2;   // -8
        data[2] = 8'sd0;   weight[2] = 8'sd10;  //  0
        data[3] = 8'sd5;   weight[3] = -8'sd2;  // -10
        data[4] = -8'sd3;  weight[4] = -8'sd3;  //  9
        data[5] = 8'sd1;   weight[5] = 8'sd1;   //  1
        data[6] = 8'sd2;   weight[6] = 8'sd2;   //  4
        data[7] = -8'sd1;  weight[7] = 8'sd4;   // -4
        data[8] = 8'sd4;   weight[8] = -8'sd1;  // -4
        // Expected sum: 6 + (-8) + 0 + (-10) + 9 + 1 + 4 + (-4) + (-4) = -6
        
        start = 1; #10;
        start = 0; #10;
        $display("Result: %0d (Expected: -6)", $signed(result));
        assert($signed(result) == -6) else $error("Test 2 Failed");

        // Test 3: Boundary values (Max Positive 8-bit limits)
        $display("--- Test 3: Boundary Values (Max Signed 8-bit) ---");
        clear = 1; #10;
        clear = 0;
        for (i = 0; i < 9; i = i + 1) begin
            data[i]   = 8'h7F;   // +127
            weight[i] = 8'h01;   // +1
        end
        // Expected sum: 9 * 127 = 1143
        start = 1; #10;
        start = 0; #10;
        $display("Result: %0d (Expected: 1143)", $signed(result));
        assert($signed(result) == 1143) else $error("Test 3 Failed");

        $display("All Convolution Datapath tests passed successfully!");
        $finish;
    end
endmodule