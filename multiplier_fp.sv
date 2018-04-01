module multiplier_fp(input clk, input start, input [31:0] A, input [31:0] B, output reg ready, output reg busy, output reg [31:0] Y);
                
	logic a_sign;
	logic [7:0] a_exponent;
	logic [23:0] a_significand;
	
	logic b_sign;
	logic [7:0] b_exponent;
	logic [23:0] b_significand;

    floating_point a(
        .fp(A),
        .sign(a_sign),
        .exponent(a_exponent),
        .significand(a_significand)
    );
    
    floating_point b(
        .fp(B),
        .sign(b_sign),
        .exponent(b_exponent),
        .significand(b_significand)
    );
	
	logic [7:0] y_exponent;
	logic [63:0] y_significand;

    logic [63:0] n_y_significand;
    logic [30:23] n_y_exponent;

    normalizer n(
        .in_exponent(y_exponent),
        .in_significand(y_significand),
        .out_exponent(n_y_exponent),
        .out_significand(n_y_significand)
    );

    logic is_a_nan;
    logic is_b_nan;

    NaN_checker a_nan(
        .exponent(a_exponent),
        .significand(a_significand),
        .result(is_a_nan)
    );

    NaN_checker b_nan(
        .exponent(b_exponent),
        .significand(b_significand),
        .result(is_b_nan)
    );

    logic is_a_inf;
    logic is_b_inf;

    inf_checker a_inf(
        .exponent(a_exponent),
        .significand(a_significand),
        .result(is_a_inf)
    );

    inf_checker b_inf(
        .exponent(b_exponent),
        .significand(b_significand),
        .result(is_b_inf)
    );
	
	logic [1:0] sign;

    logic has_started = 0;

    parameter s0 = 3'd0, s1 = 3'd1, s2 = 3'd2, s3 = 3'd3, s4 = 3'd4;

    logic [2:0] state;

    logic has_ever_started = 0;
    
    always_ff @(posedge clk) begin
    
        if (start && (~has_ever_started || ~busy)) begin
            
            state <= s0;
            
            has_ever_started <= 1;
            has_started <= 1;
        
        end
        else if (has_started) begin
        
            case (state)
            
                s0: begin // Sum exponents

                    busy <= 1;

					y_exponent = $signed(a_exponent) + $signed(b_exponent) + 127;

					state <= s1;
                
                end
				
				s1: begin // Multiply Significands

					y_significand = ({a_significand, 2'b0} * {b_significand, 2'b0}) >> 25;

					state <= s2;
				
				end
				
				s2: begin // Normalize

                    Y[22:0] = n_y_significand[22:0];
                    
                    state <= s3;
				
				end
				
				s3: begin // Return result

					sign = a_sign + b_sign;
					
					Y[31] = sign[0];
					Y[30:23] = n_y_exponent - 127;

                    // NaN
                    if (is_a_nan ||
                        is_b_nan ||
                        (A == 0 && is_b_inf) ||
                        (B == 0 && is_a_inf)) begin

                        Y[30:23] = 8'hFF;

                        // Ensure thate Y != 0
                        Y[22:0] = 1;

                    end
                    else if (is_a_inf || is_b_inf) Y[30:0] = 31'h7F800000;
                    else if (n_y_significand == 0) Y[31:0] = 0;

                    ready <= 1;
                    busy <= 0;

                    state <= s4;
				
				end

                s4: begin

                    ready <= 0;

                end
            
            endcase
        
        end
    
    end

endmodule