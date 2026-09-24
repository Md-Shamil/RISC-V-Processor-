`timescale 1ns/1ps

module alu #(parameter BW=4)(input logic [BW-1:0] in_a,in_b, input logic [3:0] opcode, output logic [BW-1:0] out, output logic [2:0] flags);

   logic [$clog2(BW)-1:0]shamt;
   assign shamt=in_b[$clog2(BW)-1:0];

   logic signed [BW-1:0] signed_a,signed_b, signed_out;
   logic overflow, negative, zero;

   assign signed_a=$signed(in_a);
   assign signed_b=$signed(in_b);

   always_comb begin
    out = '0;
    signed_out = '0;
    overflow = 1'b0;
    case(opcode)
            4'b0000:begin
                signed_out = signed_a + signed_b;
                out = signed_out;

                overflow =
                    (~in_a[BW-1] & ~in_b[BW-1] &  out[BW-1]) |
                    ( in_a[BW-1] &  in_b[BW-1] & ~out[BW-1]);
            end

            4'b0001: begin
                signed_out = signed_a - signed_b;
                out = signed_out;

                overflow =
                    (~in_a[BW-1] &  in_b[BW-1] &  out[BW-1]) |
                    ( in_a[BW-1] & ~in_b[BW-1] & ~out[BW-1]);
            end

            4'b0010: out = in_a << shamt;

            4'b0100: begin
                out = '0;
                out[0] = (signed_a < signed_b);
            end

            4'b0110: begin
                out = '0;
                out[0] = (in_a < in_b);
            end

            4'b1000: out = in_a ^ in_b;

            4'b1010: out = in_a >> shamt;

            4'b1011: out = signed_a >>> shamt;

            4'b1100: out = in_a | in_b;

            4'b1110: out = in_a & in_b;

            4'b1111: out = in_b;

            default: begin
                out      = '0;
                overflow = 1'b0;
            end

        endcase
    end

    always_comb begin
        flags[2] = overflow;
        flags[1] = out[BW-1];
        flags[0] = (out == '0);
    end

endmodule

