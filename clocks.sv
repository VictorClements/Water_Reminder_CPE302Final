//used for the normal 1hz clock
module clock1Hz
         (input  logic clk, reset,
          output logic slowClk);

  logic [39:0] count;

  always_ff @(posedge clk, posedge reset)
    if (reset)  count <= 40'b0;
    else          count <= count + 40'd21990;
assign slowClk = count[39];

endmodule

//used for speeding normal clock up to 1 IRL second = 1 clock minute
module clock60Hz
         (input  logic clk, reset,
          output logic slowClk);

  logic [39:0] count;

  always_ff @(posedge clk, posedge reset)
    if (reset)  count <= 40'b0;
    else          count <= count + 40'd1319414;
assign slowClk = count[39];

endmodule

//used for speeding normal clock up to 1 IRL second = 1 clock hour
module clock3600Hz
         (input  logic clk, reset,
          output logic slowClk);

  logic [39:0] count;

  always_ff @(posedge clk, posedge reset)
    if (reset)  count <= 40'b0;
    else          count <= count + 40'd79164837;
assign slowClk = count[39];

endmodule

module Clock760Hz(input  logic clk, reset,
                  output logic slowClk);
  logic [15:0] count;

  always_ff@(posedge clk, posedge reset)
    if(reset)   count <= 15'b0;
    else        count <= count + 1;

  assign slowClk = count[15];
  
endmodule
