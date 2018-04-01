module SSE(
    input clk, 
    input rst, 
    input stop, 
    input [31:0] A, 
    input [31:0] B,
    input pause,
    output reg ready, 
    output reg next, 
    output reg [31:0] Y
);

    logic adder_start;
    logic adder_op;
    logic [31:0] adder_A;
    logic [31:0] adder_B;
    logic [31:0] adder_Y;
    logic adder_ready;
    logic adder_busy;

    adder_fp adder(
        .clk(clk),
        .start(adder_start),
        .op(adder_op),
        .A(adder_A),
        .B(adder_B),
        .ready(adder_ready),
        .busy(adder_busy),
        .Y(adder_Y)
    );

    logic square_start;
    logic square_ready;
    logic square_busy;
    logic [31:0] square_Y;

    multiplier_fp square(
        .clk(clk),
        .start(square_start),
        .A(adder_Y),
        .B(adder_Y),
        .ready(square_ready),
        .busy(square_busy),
        .Y(square_Y)
    );

    parameter s0 = 3'd0, s1 = 3'd1, s2 = 3'd2, s3 = 3'd3, s4 = 3'd4, s5 = 3'd5, s6 = 4'd6, s7 = 4'd7;

    logic [2:0] state;

    always_ff @(posedge clk) begin

        // Reset the world.
        if (rst) begin

            state <= s0;
            Y <= 32'b0;

        end
        else begin

            case (state)

                s0: begin

                    if (~pause) begin

                        ready <= 0;
                        next <= 1;

                        state <= s1;

                    end

                end

                s1: begin

                    next <= 0;

                    if (stop) state <= s7;
                    else state <= s2;

                end

                s2: begin

                    next <= 0;

                    if (stop) state <= s7;
                    else begin

                        // Use the adder to do the subtraction
                        adder_A <= A;
                        adder_B <= B;
                        adder_op <= 1;

                        adder_start <= 1;

                        state <= s3;

                    end

                end

                s3: begin 

                    // Wait for adder to finish
                    adder_start <= 0;
                    if (adder_ready) begin

                        // Start squaring
                        square_start <= 1;
                        state <= s4;

                    end

                end

                s4: begin

                    // Wait for squaring to finish
                    square_start <= 0;
                    if (square_ready) begin

                        // Start adding
                        adder_A <= square_Y;
                        adder_B <= Y;
                        adder_op <= 0;

                        adder_start = 1;

                        state <= s5;

                    end

                end

                s5: begin

                    adder_start <= 0;
                    if (adder_ready) begin

                        Y <= adder_Y;

                        state <= s6;

                    end

                end

                s6: begin

                    ready <= 1;
                    state <= s0;

                end

                s7: begin



                end

            endcase

        end

    end

endmodule