// -----------------------------------------------------------------------------
// cnn_buffers.v  (Person 3)
// Input (64x s8), weight (9x s8) and output (36x s32) memories.
// All reads are SYNCHRONOUS: data appears 1 clock after the address is presented.
// Load/write ports are synchronous, 1 clock write latency.
// No resets on memory arrays (simulation-only initial block clears them).
// -----------------------------------------------------------------------------
module cnn_buffers (
    input  wire               clk,

    // Input matrix load port (register-bank side)
    input  wire               in_load_en,
    input  wire        [5:0]  in_load_addr,   // 0..63
    input  wire signed [7:0]  in_load_data,

    // Weight load port (register-bank side)
    input  wire               wt_load_en,
    input  wire        [3:0]  wt_load_addr,   // 0..8
    input  wire signed [7:0]  wt_load_data,

    // Compute-side read ports (1-cycle latency)
    input  wire        [5:0]  in_raddr,
    output reg  signed [7:0]  in_rdata,
    input  wire        [3:0]  wt_raddr,
    output reg  signed [7:0]  wt_rdata,

    // Output write port (controller side)
    input  wire               out_we,
    input  wire        [5:0]  out_waddr,      // 0..35
    input  wire signed [31:0] out_wdata,

    // Output readback port (register-bank side, 1-cycle latency)
    input  wire        [5:0]  out_raddr,      // 0..35
    output reg  signed [31:0] out_rdata
);

    reg signed [7:0]  in_mem  [0:63];
    reg signed [7:0]  wt_mem  [0:8];
    reg signed [31:0] out_mem [0:35];

    // Simulation-only initialisation (avoids X before first write; no hardware reset cost)
    integer init_i;
    initial begin
        for (init_i = 0; init_i < 64; init_i = init_i + 1) in_mem[init_i]  = 8'sd0;
        for (init_i = 0; init_i < 9;  init_i = init_i + 1) wt_mem[init_i]  = 8'sd0;
        for (init_i = 0; init_i < 36; init_i = init_i + 1) out_mem[init_i] = 32'sd0;
        in_rdata  = 8'sd0;
        wt_rdata  = 8'sd0;
        out_rdata = 32'sd0;
    end

    // Input memory: write on load, synchronous read
    always @(posedge clk) begin
        if (in_load_en)
            in_mem[in_load_addr] <= in_load_data;
        in_rdata <= in_mem[in_raddr];
    end

    // Weight memory: out-of-range writes ignored, out-of-range reads return 0
    always @(posedge clk) begin
        if (wt_load_en && (wt_load_addr < 4'd9))
            wt_mem[wt_load_addr] <= wt_load_data;
        wt_rdata <= (wt_raddr < 4'd9) ? wt_mem[wt_raddr] : 8'sd0;
    end

    // Output memory: out-of-range writes ignored, out-of-range reads return 0
    always @(posedge clk) begin
        if (out_we && (out_waddr < 6'd36))
            out_mem[out_waddr] <= out_wdata;
        out_rdata <= (out_raddr < 6'd36) ? out_mem[out_raddr] : 32'sd0;
    end

endmodule
