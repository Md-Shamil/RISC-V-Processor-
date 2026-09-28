module RF_tb;

localparam BW = 4;
localparam DEPTH = 4;

logic                     clk         ;
logic                     rst_n       ;
logic [BW-1           :0] data_in     ;
logic [$clog2(DEPTH)-1:0] read_addr_1 ;
logic [$clog2(DEPTH)-1:0] read_addr_2 ;
logic [$clog2(DEPTH)-1:0] write_addr  ;
logic                     write_en_n  ;
logic                     chip_en     ;
logic [BW-1           :0] data_out_1  ;
logic [BW-1           :0] data_out_2  ;

RF #( .BW   (BW   ),
      .DEPTH(DEPTH)
) DUT (
    .clk         (clk        ),
    .rst_n       (rst_n      ),
    .data_in     (data_in    ),
    .read_addr_1 (read_addr_1),
    .read_addr_2 (read_addr_2),
    .write_addr  (write_addr ),
    .write_en_n  (write_en_n ),
    .chip_en     (chip_en    ),
    .data_out_1  (data_out_1 ),
    .data_out_2  (data_out_2 )
);
initial clk = 1'b0;
always #5ns clk = ~clk;

logic [BW-1:0] internal_reg [DEPTH-1:0];
logic [$clog2(DEPTH)-1:0] rnd_addr_wr, rnd_addr_1, rnd_addr_2;
logic [DEPTH-1:0] rnd_data;

task verify();
    if(chip_en) begin
        if ((internal_reg[read_addr_1] == data_out_1)&& (internal_reg[read_addr_2] == data_out_2)) begin
            $display ("PASS");
        end else begin
            $display ("FAIL, read: %d and %d, correct outuputs: %d and %d", internal_reg[read_addr_1], internal_reg[read_addr_2], data_out_1, data_out_2);
            $stop;
        end
    end
    else begin
        if ((data_out_1 == '0)&& (data_out_2 == '0)) begin
            $display ("PASS");
        end else begin
            $display ("FAIL chip_en = 0, outuputs: %d and %d", data_out_1, data_out_2);
            $stop;
        end
    end 
endtask


initial begin
    //Initial State
    for(int i=0; i<DEPTH; i=i+1) begin
        internal_reg[i] <= {BW{1'b0}};
    end
    rnd_addr_wr = '0;
    rnd_addr_1  = '0;
    rnd_addr_2  = '0;
    rst_n = 1'b1;
    chip_en = 1'b0;
    write_en_n =1'b1;
    read_addr_1 = 'b00;
    read_addr_2 <= 'b00;
    #10ns
    rst_n = 1'b0;
    #7ns
    rst_n = 1'b1;
    chip_en    = 1'b1;
    write_en_n = 1'b0;
    #10ns
    // Random write and read
    for (int i=0; i<50; i=i+1) begin
        rnd_addr_1 = rnd_addr_wr;
        rnd_addr_2 = rnd_addr_1;
        rnd_data = $urandom_range(0, (2**BW)-1);
        rnd_addr_wr = $urandom_range(1, DEPTH-1);
        
        write_addr = rnd_addr_wr;
        data_in = rnd_data; 
        internal_reg[rnd_addr_wr] = rnd_data;
        read_addr_1 = rnd_addr_1;
        read_addr_2 = rnd_addr_2;
        #10;
        verify();
    end
    data_in = (2**BW)-1;
    write_addr = '0;
    read_addr_1 = '0;
    read_addr_2 = '0;
    #10
    verify();
    
    write_en_n = 1'b1;
    write_addr=rnd_addr_1;
    data_in = $urandom_range(0, (2**BW)-1);
    #10
    write_addr=rnd_addr_2;
    data_in = $urandom_range(0, (2**BW)-1);
    #10
    verify();
    #10
    chip_en = 1'b0;
    write_addr=rnd_addr_1;
    data_in = $urandom_range(0, (2**BW)-1);
    #10
    write_addr=rnd_addr_2;
    data_in = $urandom_range(0, (2**BW)-1);
    #10
    verify();
    $finish;
end
endmodule