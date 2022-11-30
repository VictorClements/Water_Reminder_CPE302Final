module waterDrunk
       #(parameter width = 6)
        (input  logic             clk, reset,
         input  logic [15:0]      count,       //current time passed (in 30 minute intervals)  
         input  logic [3:0]       water_level, //current water level
         output logic [width-1:0] water_drunk, //how much water has been drunk
         output logic             drank);      //true if water was drunk during the 30 minute time period


//internal signals

logic [4:0] new_level, old_level; //wires for the shift register
logic [4:0] difference;           //stores the difference between the prior water level and the current water level
logic       positive;             //holds whether the difference is positive    
logic [4:0] addToCounter;         //the amount to be added to the water_drunk counter
logic       drankReset;           //Reset signal of the register holding the drank value

always_ff @(posedge clk, posedge reset)
  if(reset) {new_level, old_level} <= 10'b0;
  else      {new_level[3:0], old_level[3:0]} 
            <= {water_level, new_level[3:0]};

//4 bit bus to hold the subtraction of the old and new water levels to find if any water was drunk
assign difference = old_level - new_level;

//1 bit wire to hold if the difference signal is positive 
assign positive = old_level > new_level;

//mux to select between the difference (if its positive) or zero (if not positive)
mux2 #(5) mymux (5'b0, difference, positive, addToCounter);

//counter register that holds the total amount of water drunk
always_ff @(posedge clk, posedge reset)
  if(reset) water_drunk <= 0;
  else      water_drunk <= water_drunk + addToCounter;

//assign drankReset wire to be true if reset is high or the time is back to 0 minutes
assign drankReset = reset | (count == 16'b0);

//register to hold if there was a drink during the current 30 minute interval
always_ff @(posedge clk, posedge drankReset)
  if(drankReset)  drank <= 1'b0;
  else            drank <= drank | positive;    //the point of this is that the register will permanently store a 1 if it ever recieves a 1
endmodule
