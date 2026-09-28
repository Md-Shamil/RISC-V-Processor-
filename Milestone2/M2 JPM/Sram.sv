module SRAM(
    input  logic        clk     ,
    input  logic        rst_n   ,
    input  logic [31:0] addr    ,
    input  logic [31:0] data_in ,
    input  logic [3 :0] write_en,
    input  logic        read_en ,
    output logic [31:0] data_out,
    output logic        mem_ready
);

logic       ena;
logic [3:0] wea;

sram sram_inst (
  .clka (clk       ), // input wire clka
  .ena  (ena       ), // input wire ena
  .wea  (wea       ), // input wire [3 : 0] wea
  .addra(addr[15:2]), // input wire [13 : 0] addra
  .dina (data_in   ), // input wire [31 : 0] dina
  .douta(data_out  )  // output wire [31 : 0] douta
);

control control_inst(
    .clk      (clk      ),
    .rst_n    (rst_n    ),
    .write_en (write_en ),
    .read_en  (read_en  ),
    .ena      (ena      ),
    .wea      (wea      ),
    .mem_ready(mem_ready)
);
endmodule