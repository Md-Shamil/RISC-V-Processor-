module memsys_tb;

    logic        clk;
    logic        rst_n;
    logic [13:0] addr;
    logic [31:0] data_in;
    logic        read_en;
    logic [3:0]  write_en;

    logic [31:0] data_out;
    logic        mem_ready;


    // DUT
    memsys dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .addr      (addr),
        .data_in   (data_in),
        .read_en   (read_en),
        .write_en  (write_en),
        .data_out  (data_out),
        .mem_ready (mem_ready)
    );


    // clock
    always #5 clk = ~clk;


    initial begin

        clk      = 0;
        rst_n    = 0;
        addr     = 0;
        data_in  = 0;
        read_en  = 0;
        write_en = 4'b0000;


        // ----------------------------------------
        // RESET
        // ----------------------------------------

        #10;
        rst_n = 1;

        wait(!mem_ready);


        // ----------------------------------------
        // TEST 1: FULL WORD WRITE
        // ----------------------------------------

        $display("TEST 1: WRITE");

        addr     = 14'd10;
        data_in  = 32'h12345678;
        write_en = 4'b1111;

        wait(mem_ready);

        $display("Write completed");
        $display("mem_ready = %b", mem_ready);

        write_en = 4'b0000;

        wait(!mem_ready);


        // ----------------------------------------
        // TEST 2: READ
        // ----------------------------------------

        $display("TEST 2: READ");

        addr    = 14'd10;
        read_en = 1'b1;

        wait(mem_ready);

        #1;

        $display("Read completed");
        $display("data_out  = %h", data_out);
        $display("mem_ready = %b", mem_ready);

        if (data_out == 32'h12345678) begin
            $display("READ TEST PASSED");
        end else begin
            $display("READ TEST FAILED");
        end

        read_en = 1'b0;

        wait(!mem_ready);


        // ----------------------------------------
        // TEST 3: BYTE-WISE WRITE
        // ----------------------------------------

        $display("TEST 3: BYTE-WISE WRITE");

        addr     = 14'd10;
        data_in  = 32'hAAAAFFFF;
        write_en = 4'b0011;

        wait(mem_ready);

        $display("Byte write completed");
        $display("mem_ready = %b", mem_ready);

        write_en = 4'b0000;

        wait(!mem_ready);


        // ----------------------------------------
        // TEST 4: READ AFTER BYTE-WISE WRITE
        // ----------------------------------------

        $display("TEST 4: READ AFTER BYTE WRITE");

        addr    = 14'd10;
        read_en = 1'b1;

        wait(mem_ready);

        #1;

        $display("Data after byte write = %h", data_out);

        if (data_out == 32'h1234FFFF) begin
            $display("BYTE WRITE TEST PASSED");
        end else begin
            $display("BYTE WRITE TEST FAILED");
        end

        read_en = 1'b0;

        wait(!mem_ready);


        // ----------------------------------------
        // FINISH
        // ----------------------------------------

        $display("ALL TESTS COMPLETED");

        #20;

        $finish;

    end

endmodule