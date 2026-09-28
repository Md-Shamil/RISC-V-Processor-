module control (
    input  logic       clk      ,
    input  logic       rst_n    ,
    input  logic [3:0] write_en ,
    input  logic       read_en  ,
    output logic       ena      ,
    output logic [3:0] wea      ,
    output logic       mem_ready
);

    typedef enum logic [1:0] {  
        IDLE  = 2'b00,
        READ  = 2'b01,
        WRITE = 2'b10
    } state_t;

state_t state, n_state;
logic rd_cnt;

always_comb begin
    ena       = 1'b0;
    wea       = 4'b0;
    mem_ready = 1'b0;
    n_state = state;
    case (state)
        IDLE: begin
            if (|write_en) begin
                n_state = WRITE;
                ena     = 1'b1;
                wea     = write_en;
            end else if (read_en) begin
                n_state = READ;
                ena     = 1'b1;
            end 
        end
        READ: begin
            if (!rd_cnt) begin
                ena       = 1'b1;
                n_state   = READ;
            end else begin
                n_state   = IDLE;
                mem_ready = 1'b1;
            end
        end
        WRITE: begin
            mem_ready = 1'b1;
            n_state   = IDLE;
        end
        default: begin
            n_state = IDLE;
        end
    endcase
end 

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state  <= IDLE;
        rd_cnt <= 1'b0;
    end else begin
        state  <= n_state;
        rd_cnt <= ((state == READ) & (!rd_cnt))? 1'b1 : 1'b0;
    end
end

endmodule