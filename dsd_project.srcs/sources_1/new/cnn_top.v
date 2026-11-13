`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2026 10:06:23 AM
// Design Name: 
// Module Name: cnn_top
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


module cnn_top (
    input  wire         clk,        // Board master clock
    input  wire         rst_n,      // Board active-low reset button

    // Simplified external CPU / Test Interface bus
    input  wire         s_wr_en,
    input  wire  [7:0]  s_addr,
    input  wire [31:0]  s_wr_data,
    output wire [31:0]  s_rd_data,

    // Board Status LEDs
    output wire         led_busy,
    output wire         led_done
);

    // Internal inter-module wires
    wire          acc_start;
    wire          acc_busy;
    wire          acc_done;

    wire          in_load_en;
    wire   [5:0]  in_load_addr;
    wire  signed [7:0] in_load_data;

    wire          wt_load_en;
    wire   [3:0]  wt_load_addr;
    wire  signed [7:0] wt_load_data;

    wire   [5:0]  out_raddr;
    wire  signed [31:0] out_rdata;

    // Instantiate Register Bank Interface
    cnn_registers u_regs (
        .clk(clk),
        .rst_n(rst_n),
        .reg_wr_en(s_wr_en),
        .reg_addr(s_addr),
        .reg_wr_data(s_wr_data),
        .reg_rd_data(s_rd_data),
        .acc_start(acc_start),
        .acc_busy(acc_busy),
        .acc_done(acc_done),
        .in_load_en(in_load_en),
        .in_load_addr(in_load_addr),
        .in_load_data(in_load_data),
        .wt_load_en(wt_load_en),
        .wt_load_addr(wt_load_addr),
        .wt_load_data(wt_load_data),
        .out_raddr(out_raddr),
        .out_rdata(out_rdata)
    );

    // Instantiate CNN Accelerator (Person 3 Core)
    cnn_accelerator #(.MAC_LATENCY(1)) u_accelerator (
        .clk(clk),
        .rst(~rst_n), // Accelerator expects active-high reset
        .start(acc_start),
        .busy(acc_busy),
        .done(acc_done),
        .in_load_en(in_load_en),
        .in_load_addr(in_load_addr),
        .in_load_data(in_load_data),
        .wt_load_en(wt_load_en),
        .wt_load_addr(wt_load_addr),
        .wt_load_data(wt_load_data),
        .out_raddr(out_raddr),
        .out_rdata(out_rdata)
    );

    // Drive status LEDs
    assign led_busy = acc_busy;
    assign led_done = acc_done;

endmodule
