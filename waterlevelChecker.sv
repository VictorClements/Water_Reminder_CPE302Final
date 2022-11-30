module waterLevelChecker(input  logic       clk, reset,
                         input  logic [3:0] water_level_input,   // input data from the GPIO pins
                         output logic [3:0] water_level);        // we have to analyze the data and send the data to reminder

    logic [3:0] N1, N2, N3, N4; // internal signals for shift register     
    logic comparator;           // internal wire to check if all values are the same 

    // shift registers to store 4 consecutively read in values of the water level
    always_ff@(posedge clk, posedge reset)
        if(reset)   {N1, N2, N3, N4} <= 16'b0;
        else        {N1, N2, N3, N4} <= {water_level_input, N1, N2, N3};

    // comparator wire that stores whether all the signals are equal
    assign comparator = (N1 == N2) & (N2 == N3) & (N3 == N4);
    
    // register to hold and output the (checked) water level
    always_ff@(posedge clk, posedge reset) begin
        if(reset)           water_level <= 4'b0;
        else if(comparator) water_level <= N4;
    end
endmodule
