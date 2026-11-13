`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2026 10:11:03 AM
// Design Name: 
// Module Name: tb_cnn_top
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

module tb_cnn_top;
    reg         clk;
    reg         rst_n;
    reg         s_wr_en;
    reg  [7:0]  s_addr;
    reg  [31:0] s_wr_data;
    wire [31:0] s_rd_data;
    wire        led_busy;
    wire        led_done;

    // Instantiate the Top-Level Accelerator Wrapper
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

    // 100 MHz Clock Generation (10ns period)
    always #5 clk = ~clk;

    integer i;

    initial begin
        // Initialize Signals
        clk       = 0;
        rst_n     = 0;
        s_wr_en   = 0;
        s_addr    = 0;
        s_wr_data = 0;

        // Apply Reset
        #25;
        rst_n = 1;
        #20;

        $display("--- Step 1: Loading Kernel Weights ---");
        // Load weights (e.g., set weight[0] = 2, weight[1] = 3, etc.)
        // Register Address 0x0C: Weight Write Port {addr[3:0], data[7:0]}
        for (i = 0; i < 9; i = i + 1) begin
            @(posedge clk);
            s_wr_en   = 1;
            s_addr    = 8'h0C;
            s_wr_data = {8'd0, i[3:0], 4'b0000, 8'sd1}; // Load value 1 into all 9 weights for simplicity
            @(posedge clk);
            s_wr_en   = 0;
        end

        $display("--- Step 2: Loading Input Feature Window ---");
        // Load input pixels (e.g., load value 5 into all 64 input slots)
        for (i = 0; i < 9; i = i + 1) begin
            @(posedge clk);
            s_wr_en   = 1;
            s_addr    = 8'h08;
            s_wr_data = {8'd0, i[5:0], 2'b00, 8'sd5}; // Load value 5 into input buffer
            @(posedge clk);
            s_wr_en   = 0;
        end

        $display("--- Step 3: Triggering CNN Accelerator Start ---");
        @(posedge clk);
        s_wr_en   = 1;
        s_addr    = 8'h00;          // Control Register
        s_wr_data = 32'h0000_0001;  // Bit 0 = start
        @(posedge clk);
        s_wr_en   = 0;

        // Wait for computation to complete (observe led_busy then led_done)
        $display("Accelerator running... waiting for done signal.");
        @(posedge led_busy);
        @(posedge led_done);
        $display("Computation complete! led_done asserted.");

        $display("--- Step 4: Reading Back Output Results ---");
        // Read back output position 0
        @(posedge clk);
        s_wr_en   = 1;
        s_addr    = 8'h10;          // Output Read Address Register
        s_wr_data = 32'd0;          // Address 0
        @(posedge clk);
        s_wr_en   = 0;

        // Wait 1 cycle for memory readback latency, then read data from 0x14
        @(posedge clk);
        s_addr    = 8'h14;          // Output Read Data Register
        #1;
        $display("Output Result at Index [0] = %0d (Expected: 9 * (5*1) = 45)", $signed(s_rd_data));
        assert($signed(s_rd_data) == 45) else $error("Top-level verification mismatch on output [0]!");

        #50;
        $display("All top-level CNN tests passed successfully!");
        $finish;
    end

endmodule
