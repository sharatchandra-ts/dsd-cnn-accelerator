`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2026 09:30:40 AM
// Design Name: 
// Module Name: conv_datapath
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


module conv_datapath (
    input  wire         clk,
    input  wire         rst_n,      // Active-low reset
    input  wire         clear,      // Result clear
    input  wire         start,      // Trigger calculation cycle
    input  wire [71:0]  data,       // Flattened 9 x 8-bit input window (9 * 8 = 72 bits)
    input  wire [71:0]  weight,     // Flattened 9 x 8-bit weights (9 * 8 = 72 bits)
    output reg  [31:0]  result,     // Signed 32-bit convolution output
    output reg          valid_out   // Valid flag when result is ready
);

    // Unpack flattened input vectors into internal 9-element unpacked arrays
    wire [7:0] data_arr   [0:8];
    wire [7:0] weight_arr [0:8];

    genvar j;
    generate
        for (j = 0; j < 9; j = j + 1) begin : unpack_gen
            assign data_arr[j]   = data[(j+1)*8 - 1 : j*8];
            assign weight_arr[j] = weight[(j+1)*8 - 1 : j*8];
        end
    endgenerate

    // Generate 9 signed multipliers (Combinational)
    wire signed [15:0] prod [0:8];
    genvar i;
    generate
        for (i = 0; i < 9; i = i + 1) begin : mult_gen
            assign prod[i] = $signed(data_arr[i]) * $signed(weight_arr[i]);
        end
    endgenerate

    // Reduction adder tree summing all 9 products (Combinational)
    wire signed [31:0] sum_tree;
    assign sum_tree = $signed(prod[0]) + $signed(prod[1]) + $signed(prod[2]) +
                      $signed(prod[3]) + $signed(prod[4]) + $signed(prod[5]) +
                      $signed(prod[6]) + $signed(prod[7]) + $signed(prod[8]);

    // -------------------------------------------------------------
    // Segment 1: Combinational Logic for Next-State / Next-Data
    // -------------------------------------------------------------
    reg signed [31:0]   next_result;
    reg                 next_valid_out;

    always @(*) begin
        if (clear) begin
            next_result    = 32'sd0;
            next_valid_out = 1'b0;
        end else if (start) begin
            next_result    = sum_tree;
            next_valid_out = 1'b1;
        end else begin
            next_result    = result;
            next_valid_out = 1'b0;
        end
    end

    // -------------------------------------------------------------
    // Segment 2: Sequential Logic for Register Updates
    // -------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result    <= 32'sd0;
            valid_out <= 1'b0;
        end else begin
            result    <= next_result;
            valid_out <= next_valid_out;
        end
    end

endmodule
