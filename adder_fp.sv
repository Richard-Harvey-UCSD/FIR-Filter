module p_encoder_32_5(input [31:0]in, output reg [4:0] out);

    integer i;
    
    always @ (in)
    begin
        out = 0;
        for (i = 0; i < 32; i++)
            if (in[i]) out = i;
    end

endmodule

module floating_point(input [31:0] fp, output sign, output reg [7:0] exponent, output reg [23:0] significand);

    assign sign = fp[31];

    always @(fp) begin

        if (fp == 0) begin

            exponent = 0;
            significand = 0;

        end
        else begin

            exponent = fp[30:23] - 127;
            significand = {8'b0, 1'b1, fp[22:0]};

        end

    end

endmodule

module normalizer(input [7:0] in_exponent, input [31:0] in_significand, output reg [7:0] out_exponent, output reg [31:0] out_significand);
    
    logic [4:0] index;
    logic [31:0] significand;

    assign significand = {2'b0, in_significand[31:2]};

    bit round = 0;

	p_encoder_32_5 max_finder(
		.in(significand),
		.out(index)
    );

    always @(in_exponent, in_significand, index) begin

        if (in_significand[1]) round = 1;
        else round = 0;

        out_exponent = index - 23;
        out_significand = (significand + round) << out_exponent;
        out_exponent = out_exponent + in_exponent + 127;

    end

endmodule

module NaN_checker(input [7:0] exponent, input [23:0] significand, output result);

    assign result = (exponent == 128 && significand[22:0] != 0);

endmodule

module inf_checker(input [7:0] exponent, input [23:0] significand, output result);

    assign result = (exponent == 128 && significand[22:0] == 0);

endmodule

module adder_fp(input clk, input start, input op, input [31:0] A, input [31:0] B, output reg ready, output reg busy, output reg [31:0] Y);
    
    logic a_sign;
    logic [7:0] a_exponent;
    logic [23:0] a_significand;
    
    logic b_sign;
    logic [7:0] b_exponent;
    logic [23:0] b_significand;
    
    logic [31:0] m_a_significand;
    logic [31:0] m_b_significand;
    
    logic [31:0] y_significand;
    logic [31:0] n_y_significand;
    
    logic [7:0] max_exponent;
    
    logic [8:0] exp_diff;
    
    logic has_started = 0;

    logic is_a_nan;
    logic is_b_nan;

    logic is_a_inf;
    logic is_b_inf;
    
    logic [7:0] normal_exponent;
    
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

    normalizer n(
        .in_exponent(max_exponent),
        .in_significand(y_significand),
        .out_exponent(normal_exponent),
        .out_significand(n_y_significand)
    );

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
        
            busy <= 1;
        
            case (state)
            
                s0: begin // match exponents
                
                    m_b_significand = {1'b1, B[22:0]};
                    
                    // Handle negative numbers and subtraction
                    if (a_sign) m_a_significand = -a_significand;
                    else m_a_significand = a_significand;
                    
                    if (b_sign) m_b_significand = -b_significand;
                    else m_b_significand = b_significand;

                    if (op) m_b_significand = -m_b_significand;

                    exp_diff = $signed(a_exponent) - $signed(b_exponent);
                    
                    if ($signed(exp_diff) > 0) m_b_significand = $signed(m_b_significand) >>> (exp_diff);
                    else m_a_significand = $signed(m_a_significand) >>> (-exp_diff);
                                        
                    if ($signed(a_exponent) > $signed(b_exponent)) max_exponent = a_exponent;
                    else max_exponent = b_exponent;

                    state <= s1;
                
                end
                
                s1: begin // add significants
                
                    y_significand = {m_a_significand, 2'b0} + {m_b_significand, 2'b0};
                    
                    state <= s2;
                
                end
                
                s2: begin // normalize significants
                
                    if ($signed(y_significand) < 0) begin
                    
                        Y[31] = 1;
                        y_significand = -y_significand;
                    
                    end
                    else Y[31] = 0;

                    state <= s3;

                end

                s3: begin
                
                    Y[30:23] = normal_exponent;
                    Y[22:0] = n_y_significand[22:0];

                    // NaN
                    if (is_a_nan || is_b_nan) begin

                        Y[30:23] = 8'hFF;

                        // Ensure thate Y != 0
                        Y[22:0] = 1;

                    end
                    else if (op && is_a_inf && is_b_inf && ((a_sign && b_sign) || (~a_sign && ~b_sign))) Y = 32'hff800001;
                    else if (~op && is_a_inf && is_b_inf && ((a_sign && ~b_sign) || (~a_sign && b_sign))) Y = 32'hff800001;
                    else if (y_significand == 0) Y[31:0] = 0;
                    else if (is_a_inf) Y = A;
                    else if (is_b_inf) begin

                        Y = {1'b0, B[30:0]};

                        if (b_sign || op) Y[31] = 1;

                    end

                    ready <= 1;
                    
                    state <= s4;
                
                end
                
                s4: begin // return result
                
                    ready <= 0;
                    busy <= 0;
                    has_started <= 0;
                
                end
                
                default: state <= s0;
                
            endcase
        
        end
    
    end

endmodule