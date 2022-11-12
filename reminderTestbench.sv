module reminderTestbench();
  logic        clk, reset;
  logic [3:0]  water_level;
  logic [3:0]  hMSD, hLSD;
  logic        remind, remindexpected;

  logic [31:0] vectornum, errors;
  logic [12:0] testvectors[10000:0];

  // instantiate device under test
  reminder dut(clk, reset, water_level, hMSD, hLSD, remind);

  // generate clock
  always 
    begin
      clk = 1; #5; clk = 0; #5;
    end

  // at start of test, load vectors
  // and pulse reset
  initial
    begin
      $readmemh("reminderTestVectors.txt", testvectors);
      vectornum = 0; errors = 0;
      reset = 1; #22; reset = 0;
    end

  // apply test vectors on rising edge of clk
  always @(posedge clk)
    begin
      #1; {remindexpected, water_level, hMSD, hLSD} = testvectors[vectornum];
    end

  // check results on falling edge of clk
  always @(negedge clk)
    if (~reset) begin // skip during reset
      if (remind !== remindexpected) begin  // check result
        $display("Error: water level = %h, hour = %h", water_level, {hMSD, hLSD});
        $display("  outputs = %b (%b expected)", remind, remindexpected);
        errors = errors + 1;
      end
      vectornum = vectornum + 1;
      if (testvectors[vectornum] === 13'bx) begin 
        $display("%d tests completed with %d errors", 
	           vectornum, errors);
        $stop;
      end
    end

endmodule










/*
module reminderTestbench();
  logic        clk, reset;
  logic [3:0]  water_level;
  logic        remind;

  // instantiate device under test
  reminder dut(clk, reset, water_level, remind);

    initial begin
        reset = 1; water_level = 4'b1111; #10;
        reset = 0; #65;
        water_level = 4'b1110; #65;
        water_level = 4'b1101; #65;
        water_level = 4'b1100; #65;
        water_level = 4'b1011; #65;
    end

  // generate clock
  always 
    begin
      clk = 1; #2; clk = 0; #2;
    end

endmodule
*/