`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2026 09:33:37 AM
// Design Name: 
// Module Name: mac_unit
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


module mac_unit (
    input  wire         clk,
    input  wire         rst_n,      // Active-low asynchronous reset
    input  wire         clear,      // Accumulator clear signal
    input  wire         en,         // Accumulation enable
    input  wire  [7:0]  a,          // Signed 8-bit operand A
    input  wire  [7:0]  b,          // Signed 8-bit operand B
    output reg  [31:0]  acc_out,    // Signed 32-bit accumulator output
    output reg          valid_out   // Output valid indicator
);

    // Internal signed projections and product computation
    wire signed [7:0]   s_a;
    wire signed [7:0]   s_b;
    wire signed [15:0]  product;
    wire signed [31:0]  extended_product;

    assign s_a = a;
    assign s_b = b;
    assign product = s_a * s_b;
    assign extended_product = $signed(product);

    // -------------------------------------------------------------
    // Segment 1: Combinational Logic for Next-State / Next-Data
    // -------------------------------------------------------------
    reg signed [31:0]   next_acc_out;
    reg                 next_valid_out;

    always @(*) begin
        if (clear) begin
            next_acc_out   = 32'sd0;
            next_valid_out = 1'b0;
        end else if (en) begin
            next_acc_out   = acc_out + extended_product;
            next_valid_out = 1'b1;
        end else begin
            next_acc_out   = acc_out;
            next_valid_out = 1'b0;
        end
    end

    // -------------------------------------------------------------
    // Segment 2: Sequential Logic for Register Updates
    // -------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_out   <= 32'sd0;
            valid_out <= 1'b0;
        end else begin
            acc_out   <= next_acc_out;
            valid_out <= next_valid_out;
        end
    end

endmodule