`timescale 1ns / 1ps

module kw4281_driver #(
    parameter int CLOCK_FREQUENCY = 100000000
) (
    input logic rst_n,
    input logic clk,

    // 4-bit hexadecimal value for each digit
    input logic [3:0][3:0] input_bcd,

    // Select which digits are special symbols
    // 0 = normal hexadecimal digit
    // 1 = special symbol
    input logic [3:0] special,

    // Special symbol selection
    // 00 = blank
    // 01 = minus
    // 10 = equal
    // 11 = plus
    input logic [3:0][1:0] special_type,

    input logic [3:0] input_dots,

    output logic [3:0] an,
    output logic [7:0] seg
);

    // ============================================================
    // Display refresh clock
    // ============================================================

    logic clk_1000hz;

    clock_divider #(
        .DIVISOR(CLOCK_FREQUENCY / 1000)
    ) clock_divider_0 (
        .rst_n  (rst_n),
        .clk_in (clk),
        .clk_out(clk_1000hz)
    );


    // ============================================================
    // Digit counter
    // ============================================================

    logic [1:0] counter;

    always_ff @(posedge clk_1000hz or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
        end
        else if (counter == 3) begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end


    // ============================================================
    // Digit enable
    // Active LOW
    // ============================================================

    always_comb begin
        case (counter)
            2'b11:   an = 4'b1110;
            2'b10:   an = 4'b1101;
            2'b01:   an = 4'b1011;
            2'b00:   an = 4'b0111;
            default: an = 4'b1111;
        endcase
    end


    // ============================================================
    // Seven segment decoder
    //
    // Active LOW
    //
    // input_bcd[counter] is used for normal hex digits.
    // special_type[counter] is used for -, =, +, blank.
    // ============================================================

    always_comb begin

        if (special[counter]) begin

            case (special_type[counter])

                // ------------------------------------------------
                // Blank
                // ------------------------------------------------
                2'b00:
                    seg[6:0] = 7'b1111111;

                // ------------------------------------------------
                // Minus "-"
                // Only segment G ON
                // ------------------------------------------------
                2'b01:
                    seg[6:0] = 7'b0111111;

                // ------------------------------------------------
                // Equal "="
                // Segments D and G ON
                // ------------------------------------------------
                2'b10:
                    seg[6:0] = 7'b0110111;

                // ------------------------------------------------
                // Plus "+"
                // Approximation using 7-segment
                // ------------------------------------------------
                2'b11:
                    seg[6:0] = 7'b0001000;

                default:
                    seg[6:0] = 7'b1111111;

            endcase

        end
        else begin

            // Normal hexadecimal digit
            case (input_bcd[counter])

                4'h0: seg[6:0] = 7'b1000000;
                4'h1: seg[6:0] = 7'b1111001;
                4'h2: seg[6:0] = 7'b0100100;
                4'h3: seg[6:0] = 7'b0110000;
                4'h4: seg[6:0] = 7'b0011001;
                4'h5: seg[6:0] = 7'b0010010;
                4'h6: seg[6:0] = 7'b0000010;
                4'h7: seg[6:0] = 7'b1111000;
                4'h8: seg[6:0] = 7'b0000000;
                4'h9: seg[6:0] = 7'b0010000;
                4'hA: seg[6:0] = 7'b0001000;
                4'hB: seg[6:0] = 7'b0000011;
                4'hC: seg[6:0] = 7'b1000110;
                4'hD: seg[6:0] = 7'b0100001;
                4'hE: seg[6:0] = 7'b0000110;
                4'hF: seg[6:0] = 7'b0001110;

                default:
                    seg[6:0] = 7'b1111111;

            endcase

        end

        // Decimal point OFF
        seg[7] = input_dots[counter];

    end

endmodule