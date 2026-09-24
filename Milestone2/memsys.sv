module memsys (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [13:0] addr,
    input  logic [31:0] data_in,
    input  logic        read_en,
    input  logic [3:0]  write_en,
    output logic [31:0] data_out,
    output logic        mem_ready
);

    typedef enum logic [1:0] {
        idle,
        read,
        write,
        done
    } state_t;

    state_t state, next_state;

    logic        ena;
    logic [3:0]  wea;
    logic [13:0] addra;
    logic [31:0] dina;
    logic [31:0] douta;


    // SRAM
    blk_mem_gen_0 u_sram (
        .clka  (clk),
        .ena   (ena),
        .wea   (wea),
        .addra (addra),
        .dina  (dina),
        .douta (douta)
    );


    // fsm
    always_comb begin

        next_state = state;

        ena       = 0;
        wea       = 0;
        addra     = addr;
        dina      = data_in;
        data_out  = douta;
        mem_ready = 0;

        case (state)

            idle: begin
                if (read_en)
                    next_state = read;
                else if (|write_en)
                    next_state = write;
            end

            read: begin
                ena = 1'b1;
                wea = 4'b0000;
                next_state = done;
            end

            write: begin
                ena = 1'b1;
                wea = write_en;
                next_state = done;
            end

            done: begin
                mem_ready = 1'b1;
                next_state = idle;
            end

        endcase

    end


    always_ff @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            state <= idle;
        end else begin
            state <= next_state;
        end

    end

endmodule
