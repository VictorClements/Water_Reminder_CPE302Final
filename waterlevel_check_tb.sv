module FSMwaterlevel_tb();
  logic        clk, reset;
  logic  [3:0] water_level_input,water_level;


  // instantiate device under test
  FSMwaterlevel dut(reset, clk, water_level_input, water_level);

  // generate clock
  always 
    begin
      clk = 1; #5; clk = 0; #5;
    end

  // at start of test, load vectors
  // and pulse reset
  initial
    begin
      reset = 1; #10; reset = 0;
      water_level_input = 4'd15; #10;
      water_level_input = 4'd14; #10;
      water_level_input = 4'd13; #10;
      water_level_input = 4'd15; #10;
      water_level_input = 4'd15; #10;
      water_level_input = 4'd15; #10;   
      water_level_input = 4'd15; #10;  // should be 15 at this point 
      
      water_level_input = 4'd14; #10; 
      
      water_level_input = 4'd13; #10; // water_level should be  15
      water_level_input = 4'd13; #10; // water_level should be  15
      water_level_input = 4'd13; #10; // water_level should be  15
      water_level_input = 4'd13; #10; // now water_level should be  13
    end
endmodule


/*
module waterLevelCheckerTestbench();
  logic        clk, reset;
  logic  [3:0] water_level_input,water_level;


  // instantiate device under test
  FSMwaterlevel dut(reset, clk, water_level_input, water_level);

  // generate clock
  always 
    begin
      clk = 1; #5; clk = 0; #5;
    end

  // at start of test, load vectors
  // and pulse reset
  initial
    begin
      reset = 1; #10; reset = 0;
      water_level_input = 4'd15; #10;
      water_level_input = 4'd14; #10;
      water_level_input = 4'd13; #10;
      water_level_input = 4'd15; #10;
      water_level_input = 4'd15; #10;
      water_level_input = 4'd15; #10;   
      water_level_input = 4'd15; #10;  // should be 15 at this point 
      
      water_level_input = 4'd14; #10; 
      
      water_level_input = 4'd13; #10; // water_level should be  15
      water_level_input = 4'd13; #10; // water_level should be  15
      water_level_input = 4'd13; #10; // water_level should be  15
      water_level_input = 4'd13; #10; // now water_level should be  13
    end
endmodule
*/