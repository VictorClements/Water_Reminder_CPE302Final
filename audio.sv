module audio(input  logic reminder, clk,reset,
             output logic toBuzzer);
  logic slowclk;

  Clock760Hz Hz(clk,reset,slowclk);
  assign toBuzzer = reminder ? slowclk : 1'b0;
endmodule
