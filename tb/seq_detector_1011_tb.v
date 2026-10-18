`timescale 1ns/1ps
// Self-checking testbench: DUT output is compared with a reference model
module seq_detector_1011_tb;

    reg  clk = 0, rst, din;
    wire detected;

    integer errors     = 0;
    integer checks     = 0;
    integer detections = 0;
    integer k;

    seq_detector_1011 dut (.clk(clk), .rst(rst), .din(din), .detected(detected));

    // 100 MHz clock
    always #5 clk = ~clk;

    // ---------- Reference model: shift register of the last 4 bits ----------
    reg [3:0] hist;
    always @(posedge clk) begin
        if (rst) hist <= 4'b0000;
        else     hist <= {hist[2:0], din};
    end
    wire expected = (hist == 4'b1011);

    // ---------- Checker: compare DUT with reference at every negedge ----------
    always @(negedge clk) begin
        checks = checks + 1;
        if (expected) detections = detections + 1;
        if (detected !== expected) begin
            errors = errors + 1;
            $display("FAIL t=%0t last4=%b expected=%b got=%b",
                     $time, hist, expected, detected);
        end
    end

    // ---------- Task: drive one bit (change inputs on negedge, no race) ----------
    task send_bit(input b);
        begin
            @(negedge clk);
            din = b;
        end
    endtask

    // ---------- Task: send an n-bit pattern, MSB first ----------
    task send_pattern(input [15:0] p, input integer n);
        integer i;
        begin
            for (i = n - 1; i >= 0; i = i - 1) send_bit(p[i]);
        end
    endtask

    initial begin
        $dumpfile("sim/waveform.vcd");
        $dumpvars(0, seq_detector_1011_tb);

        // Reset
        rst = 1; din = 0;
        repeat (3) @(negedge clk);
        rst = 0;

        // Test 1: simple detection            -> 1011
        send_pattern(16'b1011, 4);
        // Test 2: overlapping detection       -> 1011011 (detects twice)
        send_pattern(16'b1011011, 7);
        // Test 3: near misses (no detection)  -> 1010, 1001, 0111
        send_pattern(16'b1010, 4);
        send_pattern(16'b1001, 4);
        send_pattern(16'b0111, 4);
        // Test 4: reset in the middle of a pattern ("101" then reset then "1")
        send_pattern(16'b101, 3);
        @(negedge clk); rst = 1; din = 1;
        @(negedge clk); rst = 0; din = 1;
        // Test 5: random stream with occasional random resets
        for (k = 0; k < 500; k = k + 1) begin
            @(negedge clk);
            rst = ($urandom_range(0, 49) == 0);
            din = $urandom_range(0, 1);
        end

        repeat (3) @(negedge clk);

        $display("-----------------------------------------------");
        $display("Checks: %0d | Detections seen: %0d | Errors: %0d",
                 checks, detections, errors);
        if (errors == 0 && detections > 0) $display("RESULT: PASS");
        else                                $display("RESULT: FAIL");
        $display("-----------------------------------------------");
        $finish;
    end

endmodule
