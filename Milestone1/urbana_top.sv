`timescale 1ns / 1ps

module urbana_top (
    input  logic        CLK_100MHZ,
    input  logic [15:0] SW,
    output logic [15:0] LED,

    output logic [7:0] D1_SEG,
    output logic [3:0] D1_AN,

    output logic [7:0] D0_SEG,
    output logic [3:0] D0_AN
);

    // ============================================================
    // ALU SIGNALS
    // ============================================================

    logic [3:0] alu_a;
    logic [3:0] alu_b;
    logic [3:0] alu_opcode;

    logic [3:0] alu_out;
    logic [2:0] alu_flags;


    // ============================================================
    // SWITCH MAPPING
    //
    // SW[15:12] = A
    // SW[11:8]  = B
    // SW[7:4]   = unused
    // SW[3:0]   = opcode
    // ============================================================

    assign alu_a      = SW[15:12];
    assign alu_b      = SW[11:8];
    assign alu_opcode = SW[3:0];


    // ============================================================
    // ALU
    // ============================================================

    alu #(
        .BW(4)
    ) alu_0 (
        .in_a   (alu_a),
        .in_b   (alu_b),
        .opcode (alu_opcode),
        .out    (alu_out),
        .flags  (alu_flags)
    );


    // ============================================================
    // LED OUTPUT
    //
    // LED[2] = Overflow
    // LED[1] = Negative
    // LED[0] = Zero
    //
    // All other LEDs OFF
    // ============================================================

    always_comb begin
        LED = 16'b0;
        LED[2:0] = alu_flags;
    end


    // ============================================================
    // OPERATION TYPE
    //
    // Signed operations:
    //   ADD  = 0000
    //   SUB  = 0001
    //   SLT  = 0100
    //   SRA  = 1011
    //
    // Unsigned operations:
    //   SLTU = 0110
    //   SRL  = 1010
    //
    // Other operations are displayed directly as hexadecimal.
    // ============================================================

    logic display_signed;


    always_comb begin

        case (alu_opcode)

            // Signed operations
            4'b0000,     // ADD
            4'b0001,     // SUB
            4'b0100,     // SLT
            4'b1011:     // SRA
                display_signed = 1'b1;

            // Everything else:
            // unsigned/raw hexadecimal display
            default:
                display_signed = 1'b0;

        endcase

    end


    // ============================================================
    // SIGN / MAGNITUDE
    //
    // These values are only used when display_signed = 1.
    //
    // Example:
    //
    // 0111 -> +7
    // 1000 -> -8
    // 1110 -> -2
    // ============================================================

    logic a_negative;
    logic b_negative;
    logic out_negative;

    logic [3:0] a_magnitude;
    logic [3:0] b_magnitude;
    logic [3:0] out_magnitude;


    always_comb begin

        // Default
        a_negative   = 1'b0;
        b_negative   = 1'b0;
        out_negative = 1'b0;

        a_magnitude   = alu_a;
        b_magnitude   = alu_b;
        out_magnitude = alu_out;


        // --------------------------------------------------------
        // Signed display
        // --------------------------------------------------------

        if (display_signed) begin

            // A
            if (alu_a[3]) begin
                a_negative = 1'b1;
                a_magnitude = (~alu_a) + 4'b0001;
            end

            // B
            if (alu_b[3]) begin
                b_negative = 1'b1;
                b_magnitude = (~alu_b) + 4'b0001;
            end

            // Output
            if (alu_out[3]) begin
                out_negative = 1'b1;
                out_magnitude = (~alu_out) + 4'b0001;
            end

        end

    end


    // ============================================================
    // DISPLAY DATA
    //
    // LEFT DISPLAY:
    //
    //       - A - B
    //
    // digit 3 = A sign
    // digit 2 = A value
    // digit 1 = B sign
    // digit 0 = B value
    //
    //
    // RIGHT DISPLAY:
    //
    //       OP = - OUT
    //
    // digit 3 = opcode
    // digit 2 = '='
    // digit 1 = output sign
    // digit 0 = output value
    // ============================================================

    logic [3:0][3:0] display_left;
    logic [3:0][3:0] display_right;

    logic [3:0] special_left;
    logic [3:0] special_right;

    logic [3:0][1:0] special_type_left;
    logic [3:0][1:0] special_type_right;


    // ============================================================
    // SPECIAL SYMBOL TYPES
    //
    // 00 = blank
    // 01 = minus '-'
    // 10 = equal '='
    // 11 = plus '+'
    // ============================================================

    always_comb begin

        // --------------------------------------------------------
        // Defaults
        // --------------------------------------------------------

        display_left       = '0;
        display_right      = '0;

        special_left       = '0;
        special_right      = '0;

        special_type_left  = '0;
        special_type_right = '0;


        // ========================================================
        // LEFT DISPLAY
        // ========================================================

        // --------------------------------------------------------
        // A value
        // --------------------------------------------------------

        if (display_signed)
            display_left[2] = a_magnitude;
        else
            display_left[2] = alu_a;


        // --------------------------------------------------------
        // A sign
        //
        // Signed operation:
        //   negative -> '-'
        //   positive -> blank
        //
        // Unsigned operation:
        //   blank
        // --------------------------------------------------------

        special_left[3] = 1'b1;

        if (display_signed && a_negative)
            special_type_left[3] = 2'b01;     // '-'
        else
            special_type_left[3] = 2'b00;     // blank


        // --------------------------------------------------------
        // B value
        // --------------------------------------------------------

        if (display_signed)
            display_left[0] = b_magnitude;
        else
            display_left[0] = alu_b;


        // --------------------------------------------------------
        // B sign
        // --------------------------------------------------------

        special_left[1] = 1'b1;

        if (display_signed && b_negative)
            special_type_left[1] = 2'b01;     // '-'
        else
            special_type_left[1] = 2'b00;     // blank


        // ========================================================
        // RIGHT DISPLAY
        // ========================================================

        // --------------------------------------------------------
        // Opcode
        //
        // Always hexadecimal
        // --------------------------------------------------------

        display_right[3] = alu_opcode;


        // --------------------------------------------------------
        // Equal sign
        // --------------------------------------------------------

        special_right[2]      = 1'b1;
        special_type_right[2] = 2'b10;         // '='


        // --------------------------------------------------------
        // Output sign
        //
        // Only used for signed operations.
        // --------------------------------------------------------

        special_right[1] = 1'b1;

        if (display_signed && out_negative)
            special_type_right[1] = 2'b01;     // '-'
        else
            special_type_right[1] = 2'b00;     // blank


        // --------------------------------------------------------
        // Output
        //
        // Signed operations:
        //     magnitude
        //
        // Unsigned/other operations:
        //     raw hexadecimal value
        // --------------------------------------------------------

        if (display_signed)
            display_right[0] = out_magnitude;
        else
            display_right[0] = alu_out;

    end


    // ============================================================
    // LEFT 4-DIGIT DISPLAY
    //
    // Physical:
    //
    //       - A - B
    //
    // ============================================================

    kw4281_driver driver_left (
        .rst_n        (1'b1),
        .clk          (CLK_100MHZ),

        .input_bcd    (display_left),

        .special      (special_left),
        .special_type (special_type_left),

        .input_dots   (4'b1111),

        .an           (D0_AN),
        .seg          (D0_SEG)
    );


    // ============================================================
    // RIGHT 4-DIGIT DISPLAY
    //
    // Physical:
    //
    //       OP = - OUT
    //
    // ============================================================

    kw4281_driver driver_right (
        .rst_n        (1'b1),
        .clk          (CLK_100MHZ),

        .input_bcd    (display_right),

        .special      (special_right),
        .special_type (special_type_right),

        .input_dots   (4'b1111),

        .an           (D1_AN),
        .seg           (D1_SEG)
    );

endmodule