module bcdCounterTestbench();
  logic        clk, reset;
  logic [3:0]  count0, count1, count2, count3, count4, count5;
  logic [2:0]  selectLine;
  logic        carryOut0, carryOut1, carryOut2, carryOut3, carryOut4, carryOut5;
  logic        hourIs2XIn;

  // instantiate device under test
  timer dut(clk, reset, selectLine, count0, count1, count2, count3, count4, count5, hourIs2XIn);

  // generate clock
  always 
    begin
      clk = 1; #4; clk = 0; #4;
    end

  // at start of test, load vectors
  // and pulse reset
  initial
    begin
      reset = 1; #15; reset = 0;
    end
endmodule
