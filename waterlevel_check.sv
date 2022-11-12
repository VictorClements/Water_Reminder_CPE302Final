// this module will do an FSM that takes the actual level of the water in the bottle
// this module will check if there movement of water in the bottle to get the accurate level of the water
module FSMwaterlevel(input  logic       reset, clk,
                     input  logic [3:0] water_level_input,   // input data from the GPIO pins
                     output logic [3:0] water_level);        // we have to analyze the data and send the data to reminder

    logic [3:0] N1,N2,N3,N4;            // registers for comparators
    logic comparator;
    always_ff@(posedge clk, posedge reset)
    begin
        if(reset) water_level <= 4'b0;
        else begin
        N4 <= N3;
        N3 <= N2;
        N2 <= N1;
        N1 <= water_level_input;
        end
    end

    assign comparator = (N1 == N2) & (N2 == N3) & (N3 == N4) & (N4 == N1);
    
    always_ff@(posedge clk , posedge reset) begin
        if(comparator)
            water_level <= water_level_input;
    end
endmodule

/*
module waterLevelChecker(input  logic       reset, clk,
                         input  logic [3:0] water_level_input,   // input data from the GPIO pins
                         output logic [3:0] water_level);        // we have to analyze the data and send the data to reminder

    logic [3:0] N1,N2,N3,N4;    // internal signals for shift register     
    logic comparator;           // internal wire to check if all values are the same 

    // shift registers to store 4 consecutively read in values of the water level
    always_ff@(posedge clk, posedge reset)
        if(reset) N1 <= 4'b0;
        else      N1 <= water_level_input;

    always_ff@(posedge clk, posedge reset)
        if(reset) N2 <= 4'b0;
        else      N2 <= N1;

    always_ff@(posedge clk, posedge reset)
        if(reset) N3 <= 4'b0;
        else      N3 <= N2;

    always_ff@(posedge clk, posedge reset)
        if(reset) N4 <= 4'b0;
        else      N4 <= N3;

    // comparator wire that stores whether all the signals are equal
    assign comparator = (N1 == N2) & (N2 == N3) & (N3 == N4);
    
    // register to hold and output the (checked) water level
    always_ff@(posedge clk , posedge reset) begin
        if(reset)           water_level <= 4'b0;
        else if(comparator) water_level <= N4;
    end
endmodule
*/