`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2026 10:07:43 AM
// Design Name: 
// Module Name: tb_cnn_registers
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

module tb_cnn_registers;
    reg clk;
    reg rst_n;
    reg s_wr_en;
    reg [7:0] s_addr;
    reg [31:0] s_wr_data;
    wire [31:0] s_rd_data;
    wire led_busy;
    wire led_done;

    // Instantiate Top Wrapper
    cnn_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .s_wr_en(s_wr_en),
        .s_addr(s_addr),
        .s_wr_data(s_wr_data),
        .s_rd_data(s_rd_data),
        .led_busy(led_busy),
        .led_done(led_done)
    );

    // Clock Generation (10ns period -> 100MHz)
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        s_wr_en = 0;
        s_addr = 0;
        s_wr_data = 0;

        #20;
        rst_n = 1;
        #20;

        $display("--- Loading Test Weights & Inputs via Registers ---");
        // Load weight at address 0 with value 1
        @(posedge clk);
        s_wr_en   = 1;
        s_addr    = 8'h0C; // Weight write register
        s_wr_data = {8'd0, 4'd0, 8'd0, 8'sd1}; // addr=0, data=1
        @(posedge clk);
        s_wr_en   = 0;

        // Load input pixel at address 0 with value 5
        @(posedge clk);
        s_wr_en   = 1;
        s_addr    = 8'h08; // Input write register
        s_wr_data = {8'd0, 6'd0, 8'd0, 8'sd5}; // addr=0, data=5
        @(posedge clk);
        s_wr_en   = 0;

        $display("--- Triggering Accelerator Start ---");
        @(posedge clk);
        s_wr_en   = 1;
        s_addr    = 8'h00; // Control register
        s_wr_data = 32'h0000_0001; // start = 1
        @(posedge clk);
        s_wr_en   = 0;

        // Wait for completion (poll done or busy)
        @(posedge led_done);
        $display("Accelerator finished successfully! Done signal asserted.");

        $display("--- Reading back output at address 0 ---");
        @(posedge clk);
        s_wr_en   = 1;
        s_addr    = 8'h10; // Output read address register
        s_wr_data = 32'd0; // address 0
        @(posedge clk);
        s_wr_en   = 0;

        // Wait 1 cycle for readback latency
        @(posedge clk);
        s_addr    = 8'h14; // Output read data register
        #1;
        $display("Read back output data [0] = %0d", $signed(s_rd_data));

        #50;
        $finish;
    end
endmodule
