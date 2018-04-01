module FIR_SSE(
    input clk,
    input rst,
    input stop,
    input [31:0] in,
    input [31:0] out_gold,
    output reg next,
    output reg ready,
    output [31:0] out_filt,
    output [31:0] out_sse
);

    logic fir_pause;
    logic fir_next;
    logic fir_ready;

    FIR fir(
        .clk(clk), 
        .rst(rst), 
        .stop(stop),
        .in(in), 
        .pause(fir_pause),
        .next(fir_next),
        .ready(fir_ready),
        .out(out_filt)
    );

    logic sse_pause;
    logic sse_ready;
    logic sse_next;

    SSE sse(
        .clk(clk), 
        .rst(rst), 
        .stop(stop), 
        .A(out_filt), 
        .B(out_gold),
        .pause(sse_pause),
        .ready(sse_ready), 
        .next(sse_next), 
        .Y(out_sse)
    );

    parameter s0 = 2'd0, s1 = 2'd1, s2 = 2'd2, s3 = 2'd3;

    logic [1:0] state;

    always_ff @(posedge clk) begin

        if (rst) begin
            
            fir_pause <= 0;
            sse_pause <= 1;
            state <= s0;

        end
        else begin

            //$display("%d", state);

            case (state)

                s0: begin
                    
                    ready <= 0;
                    fir_pause <= 0;
                    sse_pause <= 1;

                    next <= 1;

                    state <= s1;

                end

                s1: begin
                    
                    next <= 0;
                    if (fir_next) state <= s2;                    

                end

                s2: begin
                    
                    fir_pause <= 1;
                    next <= 0;
                    if (fir_ready) begin
                        
                        sse_pause <= 0;

                        state <= s3;

                    end

                end

                s3: begin
                    
                    if (sse_ready) begin

                        ready <= 1;

                        //$display("setting ready");

                        state <= s0;

                    end

                end

            endcase

        end

    end

endmodule