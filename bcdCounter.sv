//basic counter for each digit of our timer, 2 for the hour digits, 2 for the minute digits, and 2 for the second digits
module bcdCounter
        #(parameter Max = 4'd9)
         (input  logic       clk, reset, 
          input  logic       en, cin,       //at the moment the en signal is always kept high, so there is no need for it
          input  logic       hourIs2XIn,    //this will only be used for the LSDhour bcd counters, for other counters, we will ground this input
          output logic [3:0] cnt, 
          output logic       cout,
          output logic       hourIs2XOut);  //this will only be used for the MSDhour bcd counters, for other counters, it will be tied to an unused junk wire

  //asynchronosly resettable register
  always_ff @(posedge clk, posedge reset) 
    //reset sets the counter to zero
    if (reset)  cnt <= 4'b0; 
    //this is the case for if we are using the hour LSD counter, in which case we will change from hour 23 to 00 instead of to 24
    else if (hourIs2XIn & (cnt == 4'd3) & cin) cnt <= 4'b0; 
    //if there is the enable signal coming in, then we do regular counter behavior
    else if (en)  
        //if the carry out is true, then we will go back to zero
        if (cout) cnt <= 4'b0; 
        //otherwise, we will add the carry in to count
        else      cnt <= cnt + cin; 
    //no else needed here since register will hold previous memory value if there is no enable 
 
  //assigns carry out to if we are at the Max value and there is a carry, or if there is a carry, we are the Hour LSD, and if the count is at 3
  assign cout = ((cnt == Max) & cin) | (hourIs2XIn & (cnt == 4'd3) & cin);

  //assigns this signal to if the count is currently at 2 (only to be used for the hour MSD)
  assign hourIs2XOut = cnt == 2;
endmodule
