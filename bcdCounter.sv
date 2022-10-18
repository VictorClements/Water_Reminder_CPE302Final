/*      //more explicit with what happens at each clock edge
module bcdCounter 
  #(parameter Max = 4'd9)
   (input  logic       clk, reset,
    output logic [3:0] count,
    output logic       carryOut);

    always_ff @(posedge clk)
        if (reset)              begin
                                        count <= 4'd0;
                                        carryOut <= 1'b0;
        end
        else if(count == Max)   begin
                                        count <= 4'd0;
                                        carryOut <= 1'b0;
        end
        else if(count == Max-1) begin
                                        count <= count + 1;
                                        carryOut <= 1'b1;
        end
        else                    begin             
                                        count <= count + 1;
                                        carryOut <= 1'b0;
        end
endmodule
*/
/*
//this doesnt account for the the fact that the signals are output at the start of the change to the maximum, not the end
module bcdCounter 
  #(parameter Max = 4'd9)
   (input  logic       clk, reset,
    input  logic       carryIn,
    output logic [3:0] count,
    output logic       carryOut);

    always_ff @(posedge clk)
        if (reset)                      {count, carryOut} <= 5'b0;
        else if(carryIn == 0)           
                if(carryOut == 1'b0)    {count, carryOut} <= {count, carryOut};
                else                    {count, carryOut} <= {count, 1'b0};
        else if(count == Max)           {count, carryOut} <= 5'b0;
        else if(count == Max-1)         {count, carryOut} <= {count+1, 1'b1};
        else                            {count, carryOut} <= {count+1, 1'b0};
endmodule
*/
//try out the method of the enable for the carryOut

module secondsCounter (input  logic       clk, reset,
                       output logic [3:0] count0, count1,
                       output logic       carryOut1);
  //internal signals for carry
  logic carryOut0;

  //instantiate the bcd counters for seconds
  bcdCounter #(9) secondsLSD(clk, reset, 1'b1, count0, carryOut0);
  bcdCounter #(5) secondsMSD(clk, reset, carryOut0, count1, carryOut1);
endmodule