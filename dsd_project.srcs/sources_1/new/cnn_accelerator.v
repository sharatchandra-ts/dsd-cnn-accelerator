// -----------------------------------------------------------------------------
// cnn_accelerator.v  (Person 3) -- integrates cnn_controller + cnn_buffers + mac_unit
// Register-bank friendly: plain addr/data/enable load ports, sticky done,
// level busy, 1-cycle-latency readback (set out_raddr, read out_rdata next cycle).
// Load ports are ignored while busy so a running computation cannot be corrupted.
// MAC adaptation point: only the mac_unit instance below needs editing.
// -----------------------------------------------------------------------------
module cnn_accelerator #(
    parameter integer MAC_LATENCY = 1
)(
    input  wire               clk,
    input  wire               rst,
    input  wire               start,
    output wire               busy,
    output wire               done,

    input  wire               in_load_en,
    input  wire        [5:0]  in_load_addr,
    input  wire signed [7:0]  in_load_data,

    input  wire               wt_load_en,
    input  wire        [3:0]  wt_load_addr,
    input  wire signed [7:0]  wt_load_data,

    input  wire        [5:0]  out_raddr,
    output wire signed [31:0] out_rdata
);

    wire        [5:0]  in_raddr;
    wire        [3:0]  wt_raddr;
    wire signed [7:0]  in_rdata, wt_rdata;
    wire               mac_clear, mac_en, mac_valid;
    wire signed [31:0] mac_result;
    wire               out_we;
    wire        [5:0]  out_waddr;
    wire signed [31:0] out_wdata;

    cnn_controller #(.MAC_LATENCY(MAC_LATENCY)) u_ctrl (
        .clk       (clk),
        .rst       (rst),
        .start     (start),
        .busy      (busy),
        .done      (done),
        .in_raddr  (in_raddr),
        .wt_raddr  (wt_raddr),
        .mac_clear (mac_clear),
        .mac_en    (mac_en),
        .mac_result(mac_result),
        .out_we    (out_we),
        .out_waddr (out_waddr),
        .out_wdata (out_wdata)
    );

    cnn_buffers u_buf (
        .clk         (clk),
        .in_load_en  (in_load_en & ~busy),
        .in_load_addr(in_load_addr),
        .in_load_data(in_load_data),
        .wt_load_en  (wt_load_en & ~busy),
        .wt_load_addr(wt_load_addr),
        .wt_load_data(wt_load_data),
        .in_raddr    (in_raddr),
        .in_rdata    (in_rdata),
        .wt_raddr    (wt_raddr),
        .wt_rdata    (wt_rdata),
        .out_we      (out_we),
        .out_waddr   (out_waddr),
        .out_wdata   (out_wdata),
        .out_raddr   (out_raddr),
        .out_rdata   (out_rdata)
    );

    // ---- MAC instance: adapted to Person 2's module ports ----
    mac_unit u_mac (
        .clk       (clk),
        .rst_n     (~rst),       // Invert accelerator's active-high rst to match mac_unit's active-low rst_n
        .clear     (mac_clear),
        .en        (mac_en),
        .a         (in_rdata),
        .b         (wt_rdata),
        .acc_out   (mac_result), // Changed from .result to .acc_out
        .valid_out (mac_valid)   // Changed from .valid to .valid_out
    );

endmodule
