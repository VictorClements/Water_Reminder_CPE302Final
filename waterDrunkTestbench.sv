module waterDrunkTestbench();
  logic        clk, reset;
  logic [3:0]  water_level; 
  logic [5:0]  water_Drunk, water_Drunkexpected;
  logic [31:0] vectornum, errors;
  logic [9:0]  testvectors[10000:0];

  // instantiate device under test
  waterDrunk dut(clk, reset, water_level, water_Drunk);

  // generate clock
  always 
    begin
      clk = 1; #5; clk = 0; #5;
    end

  // at start of test, load vectors
  // and pulse reset
  initial
    begin
      $readmemh("waterDrunkTestvectors.txt", testvectors);
      vectornum = 0; errors = 0;
      reset = 1; #22; reset = 0;
    end

  // apply test vectors on rising edge of clk
  always @(posedge clk)
    begin
      #1; {water_Drunkexpected, water_level} = testvectors[vectornum];
    end

  // check results on falling edge of clk
  always @(negedge clk)
    if (~reset) begin // skip during reset
      if (water_Drunk !== water_Drunkexpected) begin  // check result
        $display("Error: outputs = %h (%h expected)", water_Drunk, water_Drunkexpected);
        errors = errors + 1;
      end
      vectornum = vectornum + 1;
      if (testvectors[vectornum] === 10'bx) begin 
        $display("%d tests completed with %d errors", 
	           vectornum, errors);
        $stop;
      end
    end
endmodule