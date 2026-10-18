// 1011 overlapping sequence detector (Moore FSM)
// Output "detected" is high while the FSM is in the state that follows the last bit of 1011
module seq_detector_1011 (
    input  wire clk,
    input  wire rst,       // synchronous, active high
    input  wire din,       // serial input bit
    output wire detected   // Moore output: depends only on state
);

    // State encoding: each state = how much of "1011" matched so far
    localparam S0 = 3'd0,  // nothing matched
               S1 = 3'd1,  // "1"
               S2 = 3'd2,  // "10"
               S3 = 3'd3,  // "101"
               S4 = 3'd4;  // "1011" detected

    reg [2:0] state, next_state;

    // 1) State register (sequential)
    always @(posedge clk) begin
        if (rst) state <= S0;
        else     state <= next_state;
    end

    // 2) Next-state logic (combinational)
    always @(*) begin
        next_state = S0;                 // default avoids latch
        case (state)
            S0: next_state = din ? S1 : S0;
            S1: next_state = din ? S1 : S2;
            S2: next_state = din ? S3 : S0;
            S3: next_state = din ? S4 : S2;  // "1010" -> keep "10"
            S4: next_state = din ? S1 : S2;  // overlap: "1011"+1 -> "1", +0 -> "10"
            default: next_state = S0;
        endcase
    end

    // 3) Output logic (Moore)
    assign detected = (state == S4);

endmodule
