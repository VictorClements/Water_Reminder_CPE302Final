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