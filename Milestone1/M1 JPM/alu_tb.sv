module alu_tb;

localparam BW = 8;

typedef enum logic[3:0]{
        ADD   = 4'b0000,
        SUB   = 4'b0001,
        SLL   = 4'b0010,
        SLT   = 4'b0100,
        SLTU  = 4'b0110,
        XOR   = 4'b1000,
        SRL   = 4'b1010,
        SRA   = 4'b1011,
        OR    = 4'b1100,
        AND   = 4'b1110,
        PASSB = 4'b1111
    } ops;

logic        [BW-1:0] in_a, in_b, out, expected_out;
logic signed [BW-1:0] s_a, s_b                ;
ops                   opcode                  ;
logic                 overflow, negative, zero;
logic                 cond                    ;
logic signed [BW:0] sum;

assign s_a = in_a;
assign s_b = in_b;

alu #(.BW(BW)) DUT(
    .in_a(in_a)      ,
    .in_b(in_b)      ,
    .opcode(opcode)  ,
    .out(out)        ,
    .flags({overflow, negative, zero})
);

task verify(
    input logic [BW-1:0] a, b, out,
    input ops            opcode,
    input logic          cond, v, n, z
);
    logic zero_cond, neg_cond, over_cond;
    zero_cond = (z == ~|out)?     1'b1 : 1'b0;
    neg_cond  = (n == out[BW-1])? 1'b1 : 1'b0;
    if (opcode == ADD)begin
      over_cond = v == (a[BW-1] & b[BW-1] & ~out[BW-1]) || (~a[BW-1] & ~b[BW-1] & out[BW-1]);
    end
    else if (opcode == SUB) begin
      over_cond = v == (a[BW-1] & ~b[BW-1] & ~out[BW-1]) || (~a[BW-1] & b[BW-1] & out[BW-1]);
    end
    else begin
      over_cond = v==0;
    end
    
    if (!cond) begin
      $display("%s OPERATION FAIL: in_a: %d in_b: %d out: %d overflow: %b negative: %b zero: %b \n", opcode.name(), a, b, out, v, n, z);
      $stop;
    end
    else if (!zero_cond) begin
      $display("%s ZERO FAIL: in_a: %d in_b: %d out: %d overflow: %b negative: %b zero: %b \n", opcode.name(), a, b, out, v, n, z);
      $stop;
    end
    else if (!neg_cond) begin
      $display("%s NEGATIVE FAIL: in_a: %d in_b: %d out: %d overflow: %b negative: %b zero: %b \n", opcode.name(), a, b, out, v, n, z);
      $stop;
    end
    else if (!over_cond) begin
      $display("%s OVERFLOW FAIL: in_a: %d in_b: %d out: %d overflow: %b negative: %b zero: %b \n", opcode.name(), a, b, out, v, n, z);
      $stop;
    end
    else begin
      $display("%s PASS: in_a: %d in_b: %d out: %d overflow: %b negative: %b zero: %b \n", opcode.name(), a, b, out, v, n, z);
    end
endtask

initial begin
  for (int i = 0; i < 50; i = i+1) begin
    in_a = $urandom_range(0, 2**BW-1);
    in_b = $urandom_range(0, 2**BW-1);
    
    opcode = ADD;
    #10ns;
    expected_out = s_a + s_b;
    cond = (out == expected_out);
    verify(s_a, s_b, out, opcode, cond, overflow, negative, zero);

    opcode = SUB;
    #10ns;
    expected_out = s_a - s_b;
    cond = (out == expected_out);
    verify(s_a, s_b, out, opcode, cond, overflow, negative, zero);

    opcode = SLL;
    #10ns
    expected_out = (in_a << in_b[$clog2(BW)-1:0]);
    cond = (out == expected_out);
    verify(in_a, in_b, out, opcode, cond, overflow, negative, zero);

    opcode = SLT; 
    #10ns
    expected_out = (s_a<s_b);
    cond = (out == expected_out);
    verify(s_a, s_b, out, opcode, cond, overflow, negative, zero);
    
    opcode = SLTU;
    #10ns
    expected_out = (in_a<in_b);
    cond = (out == expected_out);
    verify(in_a, in_b, out, opcode, cond, overflow, negative, zero);

    opcode = XOR;
    #10ns
    expected_out = (in_a ^ in_b);
    cond = (out == expected_out);
    verify(in_a, in_b, out, opcode, cond, overflow, negative, zero);

    opcode = SRL; 
    #10ns
    expected_out = (in_a >> in_b[$clog2(BW)-1:0]);
    cond = (out == expected_out);
    verify(in_a, in_b, out, opcode, cond, overflow, negative, zero);

    opcode = SRA; 
    #10ns
    expected_out = (s_a >>> in_b[$clog2(BW)-1:0]);
    cond = (out == expected_out);
    verify(s_a, in_b, out, opcode, cond, overflow, negative, zero);
    
    opcode = OR; 
    #10ns
    expected_out = (in_a | in_b);
    cond = (out == expected_out);
    verify(in_a, in_b, out, opcode, cond, overflow, negative, zero);
    
    opcode = AND;
    #10ns
    expected_out = (in_a & in_b);
    cond = (out == expected_out);
    verify(in_a, in_b, out, opcode, cond, overflow, negative, zero);
    
    opcode = PASSB;
    #10ns
    expected_out = in_b;
    cond = (out == expected_out);
    verify(in_a, in_b, out, opcode, cond, overflow, negative, zero);
  

  end
  
  // Other OPCODE
  // cond = (out == {BW{1'b0}});
  // opcode = 4'b0111;
  // #10ns
  // if ((out == {BW{1'b0}}) && ((overflow | ~zero | negative) == 1'b0)) begin
  //   $display("PASS: in_a%d in_b:%d out:%d overflow:%b negative:%b zero: %b \n", in_a, in_b, out, overflow, negative, zero);
  // end
  // else begin
  //   $display("FAIL: in_a%d in_b:%d out:%d overflow:%b negative:%b zero: %b \n", in_a, in_b, out, overflow, negative, zero);
  //   $stop;
  // end
 
  
  // Force Overflow in ADD both positives
  sum = $urandom_range(2**(BW-1), 2**BW-2); //Generate sum so that s_a + s_b generates overflow
  in_a = $urandom_range(sum-(2**(BW-1)-1), 2**(BW-1)-1);     // Random positive s_a
  in_b = sum - in_a;                          // Choose s_b so that s_b + s_a = sum => overflow
  opcode = ADD;
  #10ns;
  expected_out = s_a + s_b;
  cond = (out == expected_out);
  $display("Force Overflow in ADD with positives");
  verify(s_a, s_b, out, opcode, cond, overflow, negative, zero);
  
  // Force Overflow in ADD both negatives
  sum = -$urandom_range(2**(BW-1)+1, 2**BW-2); // Generate sum so that s_a + s_b generates overflow
  in_a = -$urandom_range((-sum)-(2**(BW-1)-1), 2**(BW-1)-1);       // Random negative s_a
  in_b = sum - in_a;                             // Choose s_b so that s_b + s_a = sum => overflow
  opcode = ADD;
  #10ns;
  expected_out = s_a + s_b;
  cond = (out == expected_out);
  $display("Force Overflow in ADD with negatives");
  verify(s_a, s_b, out, opcode, cond, overflow, negative, zero);

  // Force Overflow in SUB  positive - negative
  sum = $urandom_range(2**(BW-1), 2**BW-2); // Generate positive result that overflows
  in_a = $urandom_range(sum-(2**(BW-1)-1), 2**(BW-1)-1);     // Random positive s_a
  in_b = in_a - sum;                          // Choose negative s_b so s_a - s_b = sum
  opcode = SUB;
  #10ns;
  expected_out = s_a - s_b;
  cond = (out == expected_out);
  $display("Force Overflow in SUB with positive and negative");
  verify(s_a, s_b, out, opcode, cond, overflow, negative, zero);
  
  // Force overflow in SUB negative - positive
  sum = -$urandom_range(2**(BW-1)+1, 2**BW-2);
  in_a = -$urandom_range((-sum)-(2**(BW-1)-1), 2**(BW-1)-1);
  in_b = in_a - sum;
  opcode = SUB;
  #10ns;
  expected_out = s_a - s_b;
  cond = (out == expected_out);
  $display("Force Overflow in SUB with negative and positive");
  verify(s_a, s_b, out, opcode, cond, overflow, negative, zero);
  $finish;

end

endmodule