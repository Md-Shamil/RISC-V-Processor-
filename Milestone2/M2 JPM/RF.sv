module RF#(
    parameter BW    = 4,
    parameter DEPTH = 8
)(
    input  logic                     clk         ,
    input  logic                     rst_n       ,
    input  logic [BW-1           :0] data_in     ,
    input  logic [$clog2(DEPTH)-1:0] read_addr_1 ,
    input  logic [$clog2(DEPTH)-1:0] read_addr_2 ,
    input  logic [$clog2(DEPTH)-1:0] write_addr  ,
    input  logic                     write_en_n  ,
    input  logic                     chip_en     ,
    output logic [BW-1           :0] data_out_1  ,
    output logic [BW-1           :0] data_out_2
);

logic [BW-1:0] register [DEPTH-1:0];

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for(int i=0; i<DEPTH; i=i+1) begin
            register[i] <= {BW{1'b0}};
        end
    end
    else if (chip_en) begin
        if (!write_en_n && (write_addr != {$clog2(DEPTH){1'b0}})) begin
            register[write_addr] <= data_in;
        end
    end       
end

always_comb begin
    if (rst_n & chip_en) begin
        data_out_1 = register [read_addr_1];
        data_out_2 = register [read_addr_2];
    end 
    else begin  
        data_out_1 = {BW{1'b0}};      
        data_out_2 = {BW{1'b0}};
    end
end 

endmodule
