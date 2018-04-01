module Queue (
    input clk,
    input rst,
    input start,
    input [31:0] in,
    input pause,
    output reg ready,
    output reg [31:0] all_inputs [199:0]
);

    parameter s0 = 2'd0, s1 = 2'd1, s2 = 2'd2, s3 = 2'd3;

    logic [1:0] state;

    genvar i;

    generate

        for (i = 0; i < 200; i = i + 1) begin

            always_ff @(posedge clk)
                if (rst) all_inputs[i] = 0;

        end

    endgenerate

    always_ff @(posedge clk) begin

        if (rst) begin

            state <= s0;

        end
        else begin

            case (state)

                s0: begin

                    ready <= 0;
                    if (start) state <= s1;

                end

                s1: begin

                    for (integer j = 199; j > 0; j = j - 1) begin

                        all_inputs[j] = all_inputs[j - 1];

                    end

                    state = s2;

                end

                s2: begin

                    all_inputs[0] = in;

                    state <= s3;

                end

                s3: begin
                    
                    ready <= 1;
                    state <= s0;

                end

            endcase

        end

    end

endmodule

module mass_multiplier_fp_10(
    input clk, 
    input start, 
    input [31:0] A [9:0], 
    input [31:0] B [9:0],
    output ready, 
    output busy, 
    output [31:0] Y [9:0]
);

    logic [9:0] b_ready;
    logic [9:0] b_busy;

    genvar i;

    generate

        for (i = 0; i < 10; i = i + 1) begin

            multiplier_fp multiplier(
                .clk(clk),
                .start(start),
                .A(A[i]),
                .B(B[i]),
                .ready(b_ready[i]),
                .busy(b_busy[i]),
                .Y(Y[i])
            );

        end

    endgenerate

    assign ready = &b_ready;
    assign busy = |b_busy;

endmodule

module mass_adder_fp_10(
    input clk,
    input start,
    input [31:0] in [9:0],
    output ready,
    output busy,
    output [31:0] Y [4:0]
);

    logic [4:0] b_ready;
    logic [4:0] b_busy;

    genvar i;

    generate

        for (i = 0; i < 10; i = i + 2) begin

            adder_fp adder(
                .clk(clk),
                .start(start),
                .op(0),
                .A(in[i]),
                .B(in[i + 1]),
                .ready(b_ready[i / 2]),
                .busy(b_busy[i / 2]),
                .Y(Y[i / 2])
            );

        end

    endgenerate

    assign ready = &b_ready;
    assign busy = |b_busy;

endmodule

module mass_adder_fp_5(
    input clk,
    input start,
    input [31:0] in [4:0],
    output ready,
    output busy,
    output [31:0] Y [2:0]
);

    logic [1:0] b_ready;
    logic [1:0] b_busy;

    genvar i;

    generate

        for (i = 0; i < 2; i = i + 1) begin

            adder_fp adder(
                .clk(clk),
                .start(start),
                .op(0),
                .A(in[i * 2]),
                .B(in[i * 2 + 1]),
                .ready(b_ready[i]),
                .busy(b_busy[i]),
                .Y(Y[i])
            );

        end

    endgenerate

    assign Y[2] = in[4];

    assign ready = &b_ready;
    assign busy = |b_busy;

endmodule

module mass_adder_fp_3(
    input clk,
    input start,
    input [31:0] in [2:0],
    output reg ready,
    output reg busy,
    output reg [31:0] Y
);

    logic adder_start;
    logic [31:0] adder_A;
    logic [31:0] adder_B;
    logic adder_ready;
    logic adder_busy;
    logic [31:0] adder_Y;

    adder_fp adder(
        .clk(clk),
        .start(adder_start),
        .A(adder_A),
        .B(adder_B),
        .ready(adder_ready),
        .busy(adder_busy),
        .Y(adder_Y)
    );

    parameter s0 = 2'd0, s1 = 2'd1, s2 = 2'd2, s3 = 2'd3;

    logic [1:0] state;

    always_ff @(posedge clk) begin

        if (start) begin

            state <= s0;

            adder_A <= in[0];
            adder_B <= in[1];
            adder_start <= 1;

        end
        else begin

            case (state)

                s0: begin

                    ready <= 0;
                    adder_start <= 0;
                    if (adder_ready) begin

                        state <= s1;

                    end

                end

                s1: begin

                    adder_A <= adder_Y;
                    adder_B <= in[2];
                    adder_start <= 1;
                    state <= s2;

                end

                s2: begin

                    adder_start <= 0;
                    if (adder_ready) begin
                       
                       Y <= adder_Y;
                       ready = 1;
                       state <= s3;

                    end

                end

                s3: begin

                    ready <= 0;

                end

            endcase

        end

    end

endmodule

module FIR(
    input clk, 
    input rst, 
    input stop,
    input [31:0] in, 
    input pause,
    output reg next, 
    output reg ready,
    output [31:0] out
);

    logic [31:0] coef[199:0];

    initial begin

        coef[0] = 32'hbbcc4aca;
        coef[1] = 32'hbb215c45;
        coef[2] = 32'h3c13004e;
        coef[3] = 32'h3bb3f395;
        coef[4] = 32'h3bc49cac;
        coef[5] = 32'hba75cc87;
        coef[6] = 32'hbc6bffbd;
        coef[7] = 32'h3ab95ba1;
        coef[8] = 32'h3b4ce7c3;
        coef[9] = 32'hbc1191d5;
        coef[10] = 32'h3a4924c0;
        coef[11] = 32'h3b4fd659;
        coef[12] = 32'h3b1bfaf7;
        coef[13] = 32'h3a583d5d;
        coef[14] = 32'h3a2ff173;
        coef[15] = 32'h3bd1822c;
        coef[16] = 32'hba95c705;
        coef[17] = 32'hba17de74;
        coef[18] = 32'h3ad13127;
        coef[19] = 32'hbb3b8b4e;
        coef[20] = 32'hba300412;
        coef[21] = 32'hbb8e35d6;
        coef[22] = 32'hba81833f;
        coef[23] = 32'hba60263a;
        coef[24] = 32'hbb69bfe5;
        coef[25] = 32'h3b36481b;
        coef[26] = 32'hba185a1f;
        coef[27] = 32'h3b2d163a;
        coef[28] = 32'h3b4cedc4;
        coef[29] = 32'h3a58defe;
        coef[30] = 32'h3baeb9a3;
        coef[31] = 32'hba8a434d;
        coef[32] = 32'h3ae7d442;
        coef[33] = 32'hb80472f8;
        coef[34] = 32'hbb87d263;
        coef[35] = 32'h397829f3;
        coef[36] = 32'hbbcca71c;
        coef[37] = 32'hbab6b5da;
        coef[38] = 32'hbb17bd4f;
        coef[39] = 32'hbb6ef600;
        coef[40] = 32'h3b721e18;
        coef[41] = 32'hbafcef0e;
        coef[42] = 32'h3bac992f;
        coef[43] = 32'h3b73d8dd;
        coef[44] = 32'h3af4a46b;
        coef[45] = 32'h3bf75c42;
        coef[46] = 32'hbaeec151;
        coef[47] = 32'h3b7d021a;
        coef[48] = 32'hbae233fe;
        coef[49] = 32'hbba7b545;
        coef[50] = 32'h36a66c39;
        coef[51] = 32'hbc25a059;
        coef[52] = 32'hba83bc02;
        coef[53] = 32'hbba9db30;
        coef[54] = 32'hbb8696f0;
        coef[55] = 32'h3ba264fb;
        coef[56] = 32'hbb5b6573;
        coef[57] = 32'h3c1e6500;
        coef[58] = 32'h3b8166a0;
        coef[59] = 32'h3b9cacd9;
        coef[60] = 32'h3c32aca6;
        coef[61] = 32'hbb46ac4e;
        coef[62] = 32'h3bf8387a;
        coef[63] = 32'hbba4edfc;
        coef[64] = 32'hbbc3108a;
        coef[65] = 32'hbac6b5a5;
        coef[66] = 32'hbc86ba3b;
        coef[67] = 32'hb954c6ee;
        coef[68] = 32'hbc37d138;
        coef[69] = 32'hbb8341c3;
        coef[70] = 32'h3bca3738;
        coef[71] = 32'hbbac4f70;
        coef[72] = 32'h3c9387cb;
        coef[73] = 32'h3b75521f;
        coef[74] = 32'h3c44b41c;
        coef[75] = 32'h3c869945;
        coef[76] = 32'hbb8dfedd;
        coef[77] = 32'h3c7abb09;
        coef[78] = 32'hbc515c26;
        coef[79] = 32'hbbd04b55;
        coef[80] = 32'hbbe1dae6;
        coef[81] = 32'hbcf65064;
        coef[82] = 32'h3a6796ce;
        coef[83] = 32'hbcdfe866;
        coef[84] = 32'hbb166fb5;
        coef[85] = 32'h3be6e50f;
        coef[86] = 32'hbc0cc7b9;
        coef[87] = 32'h3d2cb157;
        coef[88] = 32'h3b49eb83;
        coef[89] = 32'h3d2066e4;
        coef[90] = 32'h3d0b4888;
        coef[91] = 32'hbbb302e0;
        coef[92] = 32'h3d40a3e2;
        coef[93] = 32'hbd4d4da2;
        coef[94] = 32'hbbcaa26f;
        coef[95] = 32'hbd4554bb;
        coef[96] = 32'hbe0660fb;
        coef[97] = 32'h3b063e1a;
        coef[98] = 32'hbe88b191;
        coef[99] = 32'h3d55e7b0;
        coef[100] = 32'h3f2c8d43;
        coef[101] = 32'h3d55e7b0;
        coef[102] = 32'hbe88b191;
        coef[103] = 32'h3b063e1a;
        coef[104] = 32'hbe0660fb;
        coef[105] = 32'hbd4554bb;
        coef[106] = 32'hbbcaa26f;
        coef[107] = 32'hbd4d4da2;
        coef[108] = 32'h3d40a3e2;
        coef[109] = 32'hbbb302e0;
        coef[110] = 32'h3d0b4888;
        coef[111] = 32'h3d2066e4;
        coef[112] = 32'h3b49eb83;
        coef[113] = 32'h3d2cb157;
        coef[114] = 32'hbc0cc7b9;
        coef[115] = 32'h3be6e50f;
        coef[116] = 32'hbb166fb5;
        coef[117] = 32'hbcdfe866;
        coef[118] = 32'h3a6796ce;
        coef[119] = 32'hbcf65064;
        coef[120] = 32'hbbe1dae6;
        coef[121] = 32'hbbd04b55;
        coef[122] = 32'hbc515c26;
        coef[123] = 32'h3c7abb09;
        coef[124] = 32'hbb8dfedd;
        coef[125] = 32'h3c869945;
        coef[126] = 32'h3c44b41c;
        coef[127] = 32'h3b75521f;
        coef[128] = 32'h3c9387cb;
        coef[129] = 32'hbbac4f70;
        coef[130] = 32'h3bca3738;
        coef[131] = 32'hbb8341c3;
        coef[132] = 32'hbc37d138;
        coef[133] = 32'hb954c6ee;
        coef[134] = 32'hbc86ba3b;
        coef[135] = 32'hbac6b5a5;
        coef[136] = 32'hbbc3108a;
        coef[137] = 32'hbba4edfc;
        coef[138] = 32'h3bf8387a;
        coef[139] = 32'hbb46ac4e;
        coef[140] = 32'h3c32aca6;
        coef[141] = 32'h3b9cacd9;
        coef[142] = 32'h3b8166a0;
        coef[143] = 32'h3c1e6500;
        coef[144] = 32'hbb5b6573;
        coef[145] = 32'h3ba264fb;
        coef[146] = 32'hbb8696f0;
        coef[147] = 32'hbba9db30;
        coef[148] = 32'hba83bc02;
        coef[149] = 32'hbc25a059;
        coef[150] = 32'h36a66c39;
        coef[151] = 32'hbba7b545;
        coef[152] = 32'hbae233fe;
        coef[153] = 32'h3b7d021a;
        coef[154] = 32'hbaeec151;
        coef[155] = 32'h3bf75c42;
        coef[156] = 32'h3af4a46b;
        coef[157] = 32'h3b73d8dd;
        coef[158] = 32'h3bac992f;
        coef[159] = 32'hbafcef0e;
        coef[160] = 32'h3b721e18;
        coef[161] = 32'hbb6ef600;
        coef[162] = 32'hbb17bd4f;
        coef[163] = 32'hbab6b5da;
        coef[164] = 32'hbbcca71c;
        coef[165] = 32'h397829f3;
        coef[166] = 32'hbb87d263;
        coef[167] = 32'hb80472f8;
        coef[168] = 32'h3ae7d442;
        coef[169] = 32'hba8a434d;
        coef[170] = 32'h3baeb9a3;
        coef[171] = 32'h3a58defe;
        coef[172] = 32'h3b4cedc4;
        coef[173] = 32'h3b2d163a;
        coef[174] = 32'hba185a1f;
        coef[175] = 32'h3b36481b;
        coef[176] = 32'hbb69bfe5;
        coef[177] = 32'hba60263a;
        coef[178] = 32'hba81833f;
        coef[179] = 32'hbb8e35d6;
        coef[180] = 32'hba300412;
        coef[181] = 32'hbb3b8b4e;
        coef[182] = 32'h3ad13127;
        coef[183] = 32'hba17de74;
        coef[184] = 32'hba95c705;
        coef[185] = 32'h3bd1822c;
        coef[186] = 32'h3a2ff173;
        coef[187] = 32'h3a583d5d;
        coef[188] = 32'h3b1bfaf7;
        coef[189] = 32'h3b4fd659;
        coef[190] = 32'h3a4924c0;
        coef[191] = 32'hbc1191d5;
        coef[192] = 32'h3b4ce7c3;
        coef[193] = 32'h3ab95ba1;
        coef[194] = 32'hbc6bffbd;
        coef[195] = 32'hba75cc87;
        coef[196] = 32'h3bc49cac;
        coef[197] = 32'h3bb3f395;
        coef[198] = 32'h3c13004e;
        coef[199] = 32'hbb215c45;

    end

    logic queue_start;
    logic queue_ready;
    logic [31:0] prev_inputs [199:0];

    Queue queue(
        .clk(clk),
        .rst(rst),
        .start(queue_start),
        .in(in),
        .ready(queue_ready),
        .all_inputs(prev_inputs)
    );

    logic M10_start;
    logic [31:0] M10_A [9:0];
    logic [31:0] M10_B [9:0];
    logic M10_ready;
    logic M10_busy;
    logic [31:0] M10_Y [9:0];

    mass_multiplier_fp_10 M10(
        .clk(clk), 
        .start(M10_start), 
        .A(M10_A),
        .B(M10_B),
        .ready(M10_ready), 
        .busy(M10_busy), 
        .Y(M10_Y)
    );

    logic A10_start;
    logic [31:0] A10_in [9:0];
    logic A10_ready;
    logic A10_busy;
    logic [31:0] A10_Y [4:0];

    mass_adder_fp_10 A10(
        .clk(clk),
        .start(A10_start),
        .in(A10_in),
        .ready(A10_ready),
        .busy(A10_busy),
        .Y(A10_Y)
    );

    logic A5_start;
    logic [31:0] A5_in [4:0];
    logic A5_ready;
    logic A5_busy;
    logic [31:0] A5_Y [2:0];

    mass_adder_fp_5 A5(
        .clk(clk),
        .start(A5_start),
        .in(A5_in),
        .ready(A5_ready),
        .busy(busy),
        .Y(A5_Y)
    );

    logic A3_start;
    logic [31:0] A3_in [2:0];
    logic A3_ready;
    logic A3_busy;
    logic [31:0] A3_Y;

    mass_adder_fp_3 A3(
        .clk(clk),
        .start(A3_start),
        .in(A3_in),
        .ready(A3_ready),
        .busy(A3_busy),
        .Y(A3_Y)
    );

    logic adder_start;
    logic adder_ready;
    logic adder_busy;

    logic [31:0] res [19:0];
    logic [31:0] comb [1:0];

    adder_fp adder(
        .clk(clk),
        .start(adder_start),
        .op(0),
        .A(comb[0]),
        .B(comb[1]),
        .ready(adder_ready),
        .busy(adder_busy),
        .Y(out)
    );

    parameter s0 = 3'd0, s1 = 3'd1, s2 = 3'd2, s3 = 3'd3, s4 = 3'd4, s5 = 3'd5, s6 = 4'd6, s7 = 4'd7, s8 = 4'd8, s9 = 4'd9, s10 = 4'd10, s11 = 4'd11, s12 = 4'd12, s13 = 4'd13, s14 = 4'd14, s15 = 4'd15;

    logic [3:0] state;

    integer M10_i = 0;
    integer A10_i = 0;
    integer A5_i = 0;
    integer A3_i = 0;

    always_ff @(posedge clk) begin

        // Reset the world.
        if (rst) begin

            state <= s0;

            M10_i <= 0;
            A10_i <= -1;
            A5_i <= -2;
            A3_i <= -3;

        end
        else begin

            case (state)

                s0: begin

                    if (~pause) begin
                        
                        ready <= 0;
                        next <= 1;

                        M10_i <= 0;
                        A10_i <= -1;
                        A5_i <= -2;
                        A3_i <= -3;

                        state <= s1;
                    
                    end

                end

                s1: begin

                    next <= 0;

                    if (stop) state <= s7;
                    else begin

                        queue_start <= 1;
                        state <= s2;

                    end

                end

                s2: begin

                    next <= 0;

                    if (stop) state <= s7;
                    else begin

                        queue_start <= 0;
                        if (queue_ready) begin

                            state <= s3;

                        end

                    end

                end

                s3: begin

                    A3_in = A5_Y;

                    A5_in = A10_Y;

                    A10_in = M10_Y;

                    M10_A = prev_inputs[M10_i * 10 +: 10];
                    M10_B = coef[M10_i * 10 +: 10];

                    M10_start <= 1;
                    A10_start <= 1;
                    A5_start <= 1;
                    A3_start <= 1;

                    state <= s4;

                end

                s4: begin

                    M10_start <= 0;
                    A10_start <= 0;
                    A5_start <= 0;
                    A3_start <= 0;
                    if (A3_ready) begin

                        if (A3_i < 20) begin

                            if (A3_i >= 0) begin

                                res[A3_i] <= A3_Y;
                                
                            end

                            state <= s3;

                            M10_i = M10_i + 1;
                            A10_i = A10_i + 1;
                            A5_i = A5_i + 1;
                            A3_i = A3_i + 1;

                        end
                        else begin 

                            A10_i <= 0;
                            A5_i <= -1;
                            A3_i <= -2;

                            state <= s5;

                        end

                    end

                end

                s5: begin 

                    A3_in = A5_Y;

                    A5_in = A10_Y;

                    A10_in = res[A10_i * 10 +: 10];

                    A10_start <= 1;
                    A5_start <= 1;
                    A3_start <= 1;

                    state <= s6;

                end

                s6: begin

                    A10_start <= 0;
                    A5_start <= 0;
                    A3_start <= 0;
                    if (A3_ready) begin

                        if (A3_i < 2) begin

                            if (A3_i >= 0) begin

                                comb[A3_i] <= A3_Y;
                                
                            end

                            A10_i = A10_i + 1;
                            A5_i = A5_i + 1;
                            A3_i = A3_i + 1;

                            state <= s5;

                        end
                        else begin 

                            state <= s7;

                        end

                    end

                end

                s7: begin
                    
                    adder_start <= 1;

                    state <= s8;

                end

                s8: begin
                    
                    adder_start <= 0;
                    if (adder_ready) begin
                        
                        state <= s15;

                    end                    

                end

                s15: begin

                    ready <= 1;
                    state <= s0;

                end

            endcase

        end

    end

endmodule