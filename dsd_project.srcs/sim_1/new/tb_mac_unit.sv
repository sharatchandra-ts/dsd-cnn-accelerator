`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2026 09:34:38 AM
// Design Name: 
// Module Name: tb_mac_unit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps

module tb_mac;
    reg clk;
    reg rst_n;
    reg clear;
    reg en;
    reg [7:0] a;
    reg [7:0] b;
    wire [31:0] acc_out;
    wire valid_out;

    // Instantiate MAC unit
    mac_unit uut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .en(en),
        .a(a),
        .b(b),
        .acc_out(acc_out),
        .valid_out(valid_out)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        clear = 0;
        en = 0;
        a = 0;
        b = 0;

        #12;
        rst_n = 1;
        #10;

        // Test 1: Positive operands
        $display("--- Test 1: Positive Operands ---");
        clear = 1; #10;
        clear = 0;
        en = 1;
        a = 8'd5; b = 8'd10; #10; // Acc = 50
        a = 8'd3; b = 8'd4;  #10; // Acc = 50 + 12 = 62
        en = 0; #10;
        $display("Acc Out: %0d (Expected: 62)", $signed(acc_out));
        assert($signed(acc_out) == 62) else $error("Test 1 Failed");

        // Test 2: Negative and Zero operands
        $display("--- Test 2: Negative & Zero Operands ---");
        clear = 1; #10;
        clear = 0;
        en = 1;
        a = -8'sd5; b = 8'd10; #10; // Acc = -50
        a = 8'sd0;  b = -8'sd128; #10; // Acc = -50 + 0 = -50
        en = 0; #10;
        $display("Acc Out: %0d (Expected: -50)", $signed(acc_out));
        assert($signed(acc_out) == -50) else $error("Test 2 Failed");

        // Test 3: Boundary-value operands (Max Positive / Max Negative)
        $display("--- Test 3: Boundary Values (-128, 127) ---");
        clear = 1; #10;
        clear = 0;
        en = 1;
        a = 8'h7F;  // +127
        b = 8'h80;  // -128
        #10; // Acc = 127 * (-128) = -16256
        en = 0; #10;
        $display("Acc Out: %0d (Expected: -16256)", $signed(acc_out));
        assert($signed(acc_out) == -16256) else $error("Test 3 Failed");

        $display("All MAC tests passed successfully!");
        $finish;
    end
endmodule
