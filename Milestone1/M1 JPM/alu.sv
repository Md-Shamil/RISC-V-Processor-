module alu #(
    parameter BW = 4
)(
    input logic [BW-1:0] in_a, in_b,
    input logic [3:0] opcode,
    output logic [BW-1:0] out,
    output logic [2:0] flags
);
    logic overflow, negative, zero;
    logic signed [BW-1:0] s_a, s_b;
    assign s_a = in_a;
    assign s_b = in_b;
    assign flags = {overflow, negative, zero};
    typedef enum logic[3:0]{
        ADD   = 4'b0000,
        SUB   = 4'b0001,
        SLL   = 4'b0010,
        SLT   = 4'b0100,
        SLTU  = 4'b0110,
        XOR   = 4'b1000,
        SRL   = 4'b1010,
        SRA   = 4'b1011,
        OR    = 4'b1100,
        AND   = 4'b1110,
        PASSB = 4'b1111
    } ops;
    always_comb begin
        out = {BW{1'b0}};
        case (opcode)
            ADD  : out = s_a+s_b;
            SUB  : out = s_a-s_b;
            SLL  : out = in_a << in_b[$clog2(BW)-1:0];
            SLT  : out = (s_a<s_b)? {{BW-1{1'b0}},1'b1} : {BW{1'b0}};
            SLTU : out = (in_a<in_b)? {{BW-1{1'b0}},1'b1} : {BW{1'b0}};
            XOR  : out = in_a ^ in_b;
            SRL  : out = in_a >> in_b[$clog2(BW)-1:0];
            SRA  : out = s_a >>> in_b[$clog2(BW)-1:0];
            OR   : out = in_a | in_b;
            AND  : out = in_a & in_b;
            PASSB: out = in_b;
            default: out = {BW{1'b0}};
        endcase
    end
    always_comb begin: overflow_logic
        overflow = 1'b0;  
        if (opcode == ADD) begin
            overflow = (in_a[BW-1] & in_b[BW-1] & ~out[BW-1]) || (~in_a[BW-1] & ~in_b[BW-1] & out[BW-1]);
        end
        else if (opcode == SUB) begin
            overflow = (in_a[BW-1] & ~in_b[BW-1] & ~out[BW-1]) || (~in_a[BW-1] & in_b[BW-1] & out[BW-1]);
        end
    end
    assign negative = out[BW-1];
    assign zero     = ~|out;
endmodule