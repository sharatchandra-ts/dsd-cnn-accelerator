// -----------------------------------------------------------------------------
// cnn_controller.v  (Person 3)
// FSM: IDLE -> CLEAR -> RUN(9 fetches) -> DRAIN -> WRITE -> (CLEAR | IDLE)
//
// Timing model (all in clock cycles, F = cycle of the LAST tap fetch):
//   cycle t   : in_raddr/wt_raddr valid (from counters)
//   cycle t+1 : buffer rdata valid  -> mac_en = 1 (rd_vld register)
//   MAC accumulates at the end of the en cycle; result is valid MAC_LATENCY
//   cycles after the last en cycle (default mock MAC: MAC_LATENCY = 1).
//   F+1 .. F+MAC_LATENCY : DRAIN,   F+MAC_LATENCY+1 : WRITE (result captured)
// Taps are fetched back-to-back (1 per cycle): 12 cycles per output pixel
// with MAC_LATENCY=1 (1 CLEAR + 9 RUN + 1 DRAIN + 1 WRITE).
//
// Memory read latency is fixed at 1 (cnn_buffers). MAC valid is NOT used for
// sequencing; set MAC_LATENCY to match Person 2's MAC (>=1) instead.
// done is STICKY: cleared when a start is accepted, set when all 36 outputs
// are written. Start while busy is ignored.
// -----------------------------------------------------------------------------
module cnn_controller #(
    parameter integer MAC_LATENCY = 1      // cycles from last en cycle to valid result (>=1)
)(
    input  wire               clk,
    input  wire               rst,         // synchronous, active high
    input  wire               start,
    output wire               busy,
    output reg                done,

    // buffer read addressing
    output wire        [5:0]  in_raddr,
    output wire        [3:0]  wt_raddr,

    // MAC control
    output wire               mac_clear,
    output wire               mac_en,
    input  wire signed [31:0] mac_result,

    // output buffer write
    output wire               out_we,
    output wire        [5:0]  out_waddr,
    output wire signed [31:0] out_wdata
);

    localparam [2:0] S_IDLE  = 3'd0,
                     S_CLEAR = 3'd1,
                     S_RUN   = 3'd2,
                     S_DRAIN = 3'd3,
                     S_WRITE = 3'd4;

    reg [2:0] state;
    reg [2:0] out_x;        // 0..5
    reg [2:0] out_y;        // 0..5
    reg [1:0] kernel_x;     // 0..2
    reg [1:0] kernel_y;     // 0..2
    reg [5:0] out_idx;      // 0..35 = out_y*6 + out_x
    reg [2:0] drain_cnt;
    reg       rd_vld;       // operands on rdata buses are valid this cycle

    // ---- address generation (no physical shifting of the input) ----
    // (out_y+kernel_y) <= 7, (out_x+kernel_x) <= 7  -> {row,col} == row*8+col
    wire [2:0] row_sum = out_y + {1'b0, kernel_y};
    wire [2:0] col_sum = out_x + {1'b0, kernel_x};
    assign in_raddr = {row_sum, col_sum};

    // weight address = kernel_y*3 + kernel_x (max 8)
    wire [3:0] ky3 = {2'b00, kernel_y} + {1'b0, kernel_y, 1'b0};
    assign wt_raddr = ky3 + {2'b00, kernel_x};

    // ---- MAC / output control ----
    assign busy      = (state != S_IDLE);
    assign mac_clear = (state == S_CLEAR);
    assign mac_en    = rd_vld;
    assign out_we    = (state == S_WRITE);
    assign out_waddr = out_idx;
    assign out_wdata = mac_result;

    always @(posedge clk) begin
        if (rst) begin
            state     <= S_IDLE;
            out_x     <= 3'd0;
            out_y     <= 3'd0;
            kernel_x  <= 2'd0;
            kernel_y  <= 2'd0;
            out_idx   <= 6'd0;
            drain_cnt <= 3'd0;
            rd_vld    <= 1'b0;
            done      <= 1'b0;
        end else begin
            rd_vld <= (state == S_RUN);     // data for this fetch arrives next cycle

            case (state)
                S_IDLE: begin
                    if (start) begin
                        done     <= 1'b0;
                        out_x    <= 3'd0;
                        out_y    <= 3'd0;
                        kernel_x <= 2'd0;
                        kernel_y <= 2'd0;
                        out_idx  <= 6'd0;
                        state    <= S_CLEAR;
                    end
                end

                S_CLEAR: begin               // mac_clear asserted this cycle
                    kernel_x <= 2'd0;
                    kernel_y <= 2'd0;
                    state    <= S_RUN;
                end

                S_RUN: begin                 // one tap address per cycle, x fastest
                    if (kernel_x == 2'd2) begin
                        kernel_x <= 2'd0;
                        if (kernel_y == 2'd2) begin
                            kernel_y  <= 2'd0;
                            drain_cnt <= 3'd0;
                            state     <= S_DRAIN;
                        end else begin
                            kernel_y <= kernel_y + 2'd1;
                        end
                    end else begin
                        kernel_x <= kernel_x + 2'd1;
                    end
                end

                S_DRAIN: begin               // last operand reaches MAC, accumulation settles
                    if (drain_cnt == MAC_LATENCY - 1)
                        state <= S_WRITE;
                    else
                        drain_cnt <= drain_cnt + 3'd1;
                end

                S_WRITE: begin               // out_we=1: mac_result -> out_mem[out_idx]
                    if (out_x == 3'd5) begin
                        out_x <= 3'd0;
                        if (out_y == 3'd5) begin
                            out_y   <= 3'd0;
                            out_idx <= 6'd0;
                            done    <= 1'b1;
                            state   <= S_IDLE;
                        end else begin
                            out_y   <= out_y + 3'd1;
                            out_idx <= out_idx + 6'd1;
                            state   <= S_CLEAR;
                        end
                    end else begin
                        out_x   <= out_x + 3'd1;
                        out_idx <= out_idx + 6'd1;
                        state   <= S_CLEAR;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
