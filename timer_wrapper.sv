//wrapper module for the timer
module timer_wrapper (input  logic       CLOCK_50,
                      input  logic [2:0] SW,
                      output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);
          //clk,      reset, select[1:0], segs0, segs1, segs2, segs3, segs4, segs5
timer timer(CLOCK_50, SW[0], SW[2:1],     HEX0,  HEX1,  HEX2,  HEX3,  HEX4,  HEX5);
endmodule