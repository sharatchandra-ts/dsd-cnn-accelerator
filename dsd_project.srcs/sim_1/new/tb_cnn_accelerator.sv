`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// tb_cnn_accelerator.sv
// Test 1: spec vector (1..64, all-ones kernel) vs hard-coded expected values.
// Test 2: random signed data vs golden model, with start-while-busy and
//         load-while-busy glitches injected (must have no effect).
// -----------------------------------------------------------------------------
module tb_cnn_accelerator;

    localparam integer TIMEOUT_CYCLES = 5000;

    reg clk = 1'b0;
    always #5 clk = ~clk;

    reg               rst;
    reg               start;
    reg               in_load_en;
    reg        [5:0]  in_load_addr;
    reg signed [7:0]  in_load_data;
    reg               wt_load_en;
    reg        [3:0]  wt_load_addr;
    reg signed [7:0]  wt_load_data;
    reg        [5:0]  out_raddr;
    wire              busy, done;
    wire signed [31:0] out_rdata;

    cnn_accelerator dut (
        .clk(clk), .rst(rst), .start(start), .busy(busy), .done(done),
        .in_load_en(in_load_en), .in_load_addr(in_load_addr), .in_load_data(in_load_data),
        .wt_load_en(wt_load_en), .wt_load_addr(wt_load_addr), .wt_load_data(wt_load_data),
        .out_raddr(out_raddr), .out_rdata(out_rdata)
    );

    reg signed [7:0] in_val  [0:63];
    reg signed [7:0] k_val   [0:8];
    integer          exp_val [0:35];
    integer          errors;
    integer          cycle_cnt;
    integer          i;

    task do_reset;
        begin
            rst = 1; start = 0; in_load_en = 0; wt_load_en = 0;
            in_load_addr = 0; in_load_data = 0; wt_load_addr = 0; wt_load_data = 0;
            out_raddr = 0;
            repeat (4) @(negedge clk);
            rst = 0;
            repeat (2) @(negedge clk);
        end
    endtask

    task load_all;
        integer n;
        begin
            for (n = 0; n < 64; n = n + 1) begin
                @(negedge clk);
                in_load_en = 1; in_load_addr = n[5:0]; in_load_data = in_val[n];
            end
            @(negedge clk);
            in_load_en = 0;
            for (n = 0; n < 9; n = n + 1) begin
                @(negedge clk);
                wt_load_en = 1; wt_load_addr = n[3:0]; wt_load_data = k_val[n];
            end
            @(negedge clk);
            wt_load_en = 0;
        end
    endtask

    task compute_golden;
        integer oy, ox, ky, kx, acc;
        begin
            for (oy = 0; oy < 6; oy = oy + 1)
                for (ox = 0; ox < 6; ox = ox + 1) begin
                    acc = 0;
                    for (ky = 0; ky < 3; ky = ky + 1)
                        for (kx = 0; kx < 3; kx = kx + 1)
                            acc = acc + in_val[(oy+ky)*8 + (ox+kx)] * k_val[ky*3 + kx];
                    exp_val[oy*6 + ox] = acc;
                end
        end
    endtask

    // glitch=1: pulse start and write to the load ports while busy
    task run_and_check(input integer glitch, input integer test_id);
        integer n;
        reg signed [31:0] got;
        integer local_err;
        begin
            local_err = 0;
            @(negedge clk); start = 1;
            @(negedge clk); start = 0;

            cycle_cnt = 0;
            if (glitch) begin
                repeat (20) @(negedge clk);
                cycle_cnt = cycle_cnt + 20;
                if (!busy) begin $display("T%0d ERROR: busy low mid-run", test_id); local_err = local_err + 1; end
                start = 1;                                   // start while busy
                in_load_en = 1; in_load_addr = 6'd0; in_load_data = 8'sd127;   // load while busy
                wt_load_en = 1; wt_load_addr = 4'd0; wt_load_data = 8'sd127;
                @(negedge clk);
                start = 0; in_load_en = 0; wt_load_en = 0;
                cycle_cnt = cycle_cnt + 1;
            end

            while (!done && cycle_cnt < TIMEOUT_CYCLES) begin
                @(negedge clk);
                cycle_cnt = cycle_cnt + 1;
            end

            if (!done) begin
                $display("T%0d ERROR: TIMEOUT - FSM did not finish in %0d cycles", test_id, TIMEOUT_CYCLES);
                local_err = local_err + 1;
            end else begin
                $display("T%0d: done after ~%0d cycles", test_id, cycle_cnt);
                if (busy) begin $display("T%0d ERROR: busy still high with done", test_id); local_err = local_err + 1; end
                repeat (3) @(negedge clk);
                if (busy) begin $display("T%0d ERROR: restarted by glitch start", test_id); local_err = local_err + 1; end

                for (n = 0; n < 36; n = n + 1) begin
                    @(negedge clk); out_raddr = n[5:0];
                    @(posedge clk); #1;
                    got = out_rdata;
                    if (got !== exp_val[n]) begin
                        $display("T%0d MISMATCH O[%0d][%0d] (addr %0d): got %0d expected %0d",
                                 test_id, n/6, n%6, n, got, exp_val[n]);
                        local_err = local_err + 1;
                    end
                end
            end
            errors = errors + local_err;
            $display("T%0d: %s (%0d errors)", test_id, (local_err == 0) ? "ok" : "failed", local_err);
        end
    endtask

    initial begin
        errors = 0;
        do_reset;
        if (busy !== 1'b0 || done !== 1'b0) begin
            $display("ERROR: busy/done not low after reset"); errors = errors + 1;
        end

        // ---------------- Test 1: spec vector ----------------
        for (i = 0; i < 64; i = i + 1) in_val[i] = i + 1;
        for (i = 0; i < 9;  i = i + 1) k_val[i]  = 8'sd1;
        exp_val[0]=90;  exp_val[1]=99;  exp_val[2]=108; exp_val[3]=117; exp_val[4]=126; exp_val[5]=135;
        exp_val[6]=162; exp_val[7]=171; exp_val[8]=180; exp_val[9]=189; exp_val[10]=198; exp_val[11]=207;
        exp_val[12]=234; exp_val[13]=243; exp_val[14]=252; exp_val[15]=261; exp_val[16]=270; exp_val[17]=279;
        exp_val[18]=306; exp_val[19]=315; exp_val[20]=324; exp_val[21]=333; exp_val[22]=342; exp_val[23]=351;
        exp_val[24]=378; exp_val[25]=387; exp_val[26]=396; exp_val[27]=405; exp_val[28]=414; exp_val[29]=423;
        exp_val[30]=450; exp_val[31]=459; exp_val[32]=468; exp_val[33]=477; exp_val[34]=486; exp_val[35]=495;
        load_all;
        run_and_check(0, 1);

        // ---------------- Test 2: random signed + glitches ----------------
        for (i = 0; i < 64; i = i + 1) in_val[i] = $random;
        for (i = 0; i < 9;  i = i + 1) k_val[i]  = $random;
        in_val[0] = -8'sd128; k_val[0] = -8'sd128;      // corner case: (-128)*(-128)
        compute_golden;
        load_all;
        run_and_check(1, 2);

        $display("------------------------------------------");
        if (errors == 0) $display("PASS: all checks passed");
        else             $display("FAIL: %0d errors", errors);
        $display("------------------------------------------");
        $finish;
    end

    // global watchdog
    initial begin
        #5_000_000;
        $display("FAIL: global watchdog expired");
        $finish;
    end

endmodule
