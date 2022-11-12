module timerTestbench();
  logic        clk, reset;
  logic [3:0]  water_level;
  logic [1:0]  selectLine;
  logic        remind;
  logic [6:0]  display0, display1, display2, display3, display4, display5;

  // instantiate device under test
  timer dut(clk, reset, water_level, selectLine, remind, 
            display0, display1, display2, display3, display4, display5);

  // generate clock
  always 
    begin
      clk = 1; #4; clk = 0; #4;
    end

  // at start of test, load vectors
  // and pulse reset
  initial
    begin
      reset = 1; water_level = 4'b1000; selectLine = 2'b11;
      #15; reset = 0;
    end
endmodule