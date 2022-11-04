/*
module reminder(input  logic       clk, reset,
                input  logic [3:0] waterLevel,
                input  logic [3:0] hMSD, hLSD,
                output logic       remind);
//internal logic signal that will be given to remind if reset = 0
logic reminder;
//asynchronosly resettable register
  always_ff @(posedge clk, posedge reset)
    if(reset) remind <= 1'b0;
    else      remind <= reminder;

  always_comb
    //case statement to see based on the current water level, if a reminder is need
    //essentially, every hour that passes in the day requires that you have drinken 
    //more and more of the water. if the water level is 0, then all of the water has
    //been drunk, so there is no need for a reminder
    //then as the water level increases, then there are more times for which you will be reminded
    //to drink, so for water level 0001, you will be reminded if the current time is 22 hours or later
    //and if water level is 0010, then reminder is when time is 21 hours or later, all the way up until
    //1111, where is time is 8 hours or later, then you will be reminded
    case(waterLevel)
      4'b0000:  reminder = 1'b0;
      4'b0001:  if((hMSD == 4'd2) & (hLSD >= 4'd2))                     reminder = 1'b1;
                else  reminder = 1'b0;
      4'b0010:  if((hMSD == 4'd2) & (hLSD >= 4'd1))                     reminder = 1'b1;
                else  reminder = 1'b0;
      4'b0011:  if(hMSD == 4'd2)                                        reminder = 1'b1;
                else  reminder = 1'b0;
      4'b0100:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD == 4'd9))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b0101:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD >= 4'd8))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b0110:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD >= 4'd7))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b0111:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD >= 4'd6))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b1000:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD >= 4'd5))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b1001:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD >= 4'd4))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b1010:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD >= 4'd3))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b1011:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD >= 4'd2))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b1100:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD >= 4'd1))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b1101:  if(hMSD >= 4'd1)                                        reminder = 1'b1;
                else  reminder = 1'b0;
      4'b1110:  if( (hMSD >= 4'd1) | ((hMSD == 4'd0) & (hLSD == 4'd9))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b1111:  if( (hMSD >= 4'd1) | ((hMSD == 4'd0) & (hLSD >= 4'd8))) reminder = 1'b1;
                else  reminder = 1'b0;
    endcase

endmodule
*/

//the reminder module will take in the current water level and output a remindeSignal
//a reminder will be output when the count reaches its maximum
module reminder (input  logic       clk, reset,
                 input  logic [3:0] water_level,
                 output logic       remindSignal);

logic                decrease;
logic [3:0] count;
logic [3:0] old_water_level, new_water_level;

  // counter register
  //so far this will just count to the maximum value, and when it hits it, it outputs the remind signal then goes down to 0
  always_ff @(posedge clk, posedge reset)
    if(reset | decrease) begin
      count <= 0;
      remindSignal <= 0;
    end
    else if(count == 4'b1111) begin
      count <= 0;
      remindSignal <= 1;
    end
    else      begin
      count <= count + 1;
      remindSignal <= 0;
    end

  always_ff @(posedge clk, posedge reset)
    if(reset) new_water_level <= 0;
    else  new_water_level <= water_level;

  always_ff @(posedge clk, posedge reset)
    if(reset) old_water_level <= 0;
    else  old_water_level <= new_water_level;

  always_comb begin
    if(old_water_level > new_water_level)   decrease = 1'b1;
    else                                    decrease = 1'b0;
  end
endmodule
