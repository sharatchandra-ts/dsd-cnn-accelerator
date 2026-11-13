`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/13/2026 10:06:23 AM
// Design Name: 
// Module Name: cnn_registers
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


module cnn_registers (
    input  wire         clk,
    input  wire         rst_n,      // Active-low asynchronous reset

    // CPU / Host Bus Interface
    input  wire         reg_wr_en,  // Register write enable
    input  wire  [7:0]  reg_addr,   // Register address bus
    input  wire [31:0]  reg_wr_data,// Register write data
    output reg  [31:0]  reg_rd_data,// Register read data

    // Accelerator Control/Status and Loading Ports (going to cnn_accelerator)
    output reg          acc_start,
    input  wire         acc_busy,
    input  wire         acc_done,

    output reg          in_load_en,
    output reg   [5:0]  in_load_addr,
    output reg  signed [7:0] in_load_data,

    output reg          wt_load_en,
    output reg   [3:0]  wt_load_addr,
    output reg  signed [7:0] wt_load_data,

    output reg   [5:0]  out_raddr,
    input  wire signed [31:0] out_rdata
);

    // Register Map Definition:
    // 0x00: Control Register (Bit 0: start, Bit 1: soft_clear)
    // 0x04: Status Register  (Bit 0: busy, Bit 1: done)
    // 0x08: Input Write Port (Bits [7:0] data, Bits [13:8] address)
    // 0x0C: Weight Write Port(Bits [7:0] data, Bits [11:8] address)
    // 0x10: Output Read Port (Bits [5:0] address for readback)
    // 0x14: Output Read Data (Returns out_rdata from accelerator)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_start    <= 1'b0;
            in_load_en   <= 1'b0;
            in_load_addr <= 6'd0;
            in_load_data <= 8'sd0;
            wt_load_en   <= 1'b0;
            wt_load_addr <= 4'd0;
            wt_load_data <= 8'sd0;
            out_raddr    <= 6'd0;
            reg_rd_data  <= 32'd0;
        end else begin
            // Default strobes (1-cycle pulse for load/start)
            acc_start  <= 1'b0;
            in_load_en <= 1'b0;
            wt_load_en <= 1'b0;

            if (reg_wr_en) begin
                case (reg_addr)
                    8'h00: acc_start    <= reg_wr_data[0];
                    8'h08: begin
                        in_load_data <= reg_wr_data[7:0];
                        in_load_addr <= reg_wr_data[13:8];
                        in_load_en   <= 1'b1;
                    end
                    8'h0C: begin
                        wt_load_data <= reg_wr_data[7:0];
                        wt_load_addr <= reg_wr_data[11:8];
                        wt_load_en   <= 1'b1;
                    end
                    8'h10: begin
                        out_raddr    <= reg_wr_data[5:0];
                    end
                    default: ;
                endcase
            end

            // Read multiplexer (combinational/registered)
            case (reg_addr)
                8'h00: reg_rd_data <= {31'd0, acc_start};
                8'h04: reg_rd_data <= {30'd0, acc_done, acc_busy};
                8'h08: reg_rd_data <= {18'd0, in_load_addr, 2'b00, in_load_data};
                8'h0C: reg_rd_data <= {20'd0, wt_load_addr, 4'b0000, wt_load_data};
                8'h10: reg_rd_data <= {26'd0, out_raddr};
                8'h14: reg_rd_data <= out_rdata; // 1-cycle latency data readback
                default: reg_rd_data <= 32'd0;
            endcase
        end
    end

endmodule
