module bcdCounterTestbench();
  logic        clk, reset;
  logic [3:0]  count0, count1;
  logic        carryOut;

  // instantiate device under test
  secondsCounter dut(clk, reset, count0, count1, carryOut);

  // generate clock
  always 
    begin
      clk = 1; #5; clk = 0; #5;
    end

  // at start of test, load vectors
  // and pulse reset
  initial
    begin
      reset = 1; #22; reset = 0;
    end
endmodule