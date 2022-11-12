module waterDrunk
       #(parameter width = 6)
        (input  logic       clk, reset,
         input  logic [3:0] water_level
         output logic [width-1:0] water_drunk);

//internal signals
logic [3:0] new_level, old_level;
logic [3:0] difference;
logic       positive;
logic [3:0] addToCounter;

//register to store newest value read from water level
always_ff @(posedge clk, posedge reset)
  if(reset) new_level <= 4'b0;
  else      new_level <= water_level;

//shift register
always_ff @(posedge clk, posedge reset)
  if(reset) old_level <= 4'b0;
  else      old_level <= new_level;

//4 bit bus to hold the subtraction the old and new water levels to find if any water was drunk
assign difference = old_level - new_level;

//1 bit wire to hold if the difference signal is positive (in two's complement the easiest way to check this is just pulling off the msb and running it through an inverter)
assign positive = difference > 0;

//mux to select between the difference (if its positive) or zero (if not positive)
mux2 #(4) mymux (4'b0, difference, positive, addToCounter);

//counter register that holds the total amount of water drunk
always_ff @(posedge clk, posedge reset)
  if(reset) water_drunk <= 0;
  else      water_drunk <= water_drunk + difference;

endmodule
