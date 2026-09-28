module urbana_top (
    output logic [2:0]LED    ,
    output logic [7 :0] D1_SEG,
    output logic [3 :0] D1_AN ,
    input  logic [15:0] SW    ,
    input  logic [3 :0] BTN   ,
    input  logic        CLK_100MHZ
    );

    logic [6:0] bcd_out;
    logic [3:0] bcd_in, alu_out;
    logic clk_1KHZ;
    logic show_signed;
    logic [1:0] select_display;
    assign show_signed = SW[9];

    // instantiate clock divider
    clock_divider #(
        .DIVISOR(50000)
        ) clock_divider_inst (
        .rst_n(~BTN[0]),
        .clk_in(CLK_100MHZ),
        .clk_out(clk_1KHZ)
    );
    
    alu #(
        .BW(4)
    ) alu_inst (
        .in_a(SW[3:0]),
        .in_b(SW[7:4]),
        .opcode(SW[15:12]),
        .out(alu_out),
        .flags(LED)
    );

    bcd27s bcd27s_inst (
        .bcd(bcd_in),
        .seg(D1_SEG[6:0])
    );
    // assign D1_SEG[0]= 1'b1;
    
    always_ff @(posedge clk_1KHZ or posedge BTN[0]) begin
        if (BTN[0]) begin
            select_display <= '0;
        end
        else if (select_display< 2'b10) begin
            select_display <= select_display + 2'b01;
        end else begin
            select_display <= '0;
        end 
    end

    always_comb begin
        case (select_display)
            2'b00: begin
                D1_AN = 4'b1110;
                if (show_signed) begin
                    bcd_in = SW[3]? ~SW[3:0]+1'b1 : SW[3:0];
                    D1_SEG[7] = !SW[3];
                end
                else begin
                    bcd_in = SW[3:0];
                    D1_SEG[7] = 1'b1;
                end 
            end
            2'b01: begin
                D1_AN = 4'b1101;
                if (show_signed) begin
                    bcd_in = SW[7]? ~SW[7:4]+1'b1 : SW[7:4];
                    D1_SEG[7] = !SW[7];
                end
                else begin
                    bcd_in = SW[7:4];
                    D1_SEG[7] = 1'b1;
                end 
            end
            2'b10: begin
                D1_AN = 4'b1011;
                if (show_signed) begin
                    bcd_in = alu_out[3]? ~alu_out[3:0] + 1'b1 : alu_out[3:0];
                    D1_SEG[7] = !alu_out[3];
                end
                else begin
                    bcd_in = alu_out[3:0];
                    D1_SEG[7] = 1'b1;
                end 
            end
            default: begin
                bcd_in = SW[3:0];
                D1_AN = 4'b1110;
                D1_SEG[7]=1'b0;
            end
        endcase 
    end

endmodule