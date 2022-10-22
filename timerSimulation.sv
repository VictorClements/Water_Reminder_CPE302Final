module slowClock
        #(parameter MSB = 1'b0)
         (input  logic clk, reset,
          output logic slowClk);
  logic [MSB:0] count;

  always_ff @(posedge clk, posedge reset)
    if (reset)  count <= 'b0;
    else        count <= count + 1;

assign slowClk = count[MSB];
endmodule

module bcdCounter
        #(parameter Max = 4'd9)
         (input  logic       clk, reset, 
          input  logic       en, cin, 
          input  logic       hourIs2XIn,    //this will only be used for the LSDhour bcd counters, for other counters, we will ground this wire
          output logic [3:0] cnt, 
          output logic       cout,
          output logic       hourIs2XOut);  //this will only be used for the LSDhour bcd counters, for other counters, we will ground this wire
  always_ff @(posedge clk, posedge reset) 
    if (reset)  cnt <= 4'b0; 
    else if (hourIs2XIn & (cnt == 4'd3) & cin) cnt <= 4'b0;
    else if (en) 
        if (cout) cnt <= 4'b0; 
        else      cnt <= cnt + cin; 
 
  assign cout = ((cnt == Max) & cin) | (hourIs2XIn & (cnt == 4'd3) & cin);
  assign hourIs2XOut = cnt == 2;
endmodule

module timer (input  logic       clk, reset,
              input  logic [2:0] selectLine,
              output logic [3:0] count0, count1, count2, count3, count4, count5,
              output logic       hourIs2XIn);

  //internal signals
  logic carryOut0, carryOut1, carryOut2, carryOut3, carryOut4, carryOut5;
  logic junk0, junk1, junk2, junk3, junk4;
  logic slowClk0, slowClk1, slowClk2, slowClk3, slowClk4, slowClk5, slowClk6, slowClk7; 
  logic systemClk;

  //8 to 1 mux for selecting the speed of the clock desired
  always_comb 
    case(selectLine)
      3'b000:   systemClk = slowClk0;
      3'b001:   systemClk = slowClk1;
      3'b010:   systemClk = slowClk2;
      3'b011:   systemClk = slowClk3;
      3'b100:   systemClk = slowClk4;
      3'b101:   systemClk = slowClk5;
      3'b110:   systemClk = slowClk6;
      3'b111:   systemClk = slowClk7;
      default:  systemClk = slowClk0;
    endcase

  //clocks for slowing this bad boi down
  slowClock #(0)  clock25_MHz (clk, reset, slowClk0);
  slowClock #(3)  clock3__MHz (clk, reset, slowClk1);
  slowClock #(6)  clock390KHz (clk, reset, slowClk2);
  slowClock #(9)  clock49_KHz (clk, reset, slowClk3);
  slowClock #(12) clock6__KHz (clk, reset, slowClk4);
  slowClock #(15) clock763_Hz (clk, reset, slowClk5);
  slowClock #(18) clock95__Hz (clk, reset, slowClk6);
  slowClock #(21) clock12__Hz (clk, reset, slowClk7);

  //instantiate the bcd counters for seconds
  bcdCounter #(4'd9) secondsLSD (systemClk, reset, 1'b1, 1'b1,      1'b0,       count0, carryOut0, junk0);
  bcdCounter #(4'd5) secondsMSD (systemClk, reset, 1'b1, carryOut0, 1'b0,       count1, carryOut1, junk1);
  //instantiate the bcd counters for seconds
  bcdCounter #(4'd9) minutesLSD (systemClk, reset, 1'b1, carryOut1, 1'b0,       count2, carryOut2, junk2);
  bcdCounter #(4'd5) minutesMSD (systemClk, reset, 1'b1, carryOut2, 1'b0,       count3, carryOut3, junk3);
  //instantiate the bcd counters for seconds
  bcdCounter #(4'd9) hoursLSD   (systemClk, reset, 1'b1, carryOut3, hourIs2XIn, count4, carryOut4, junk4);
  bcdCounter #(4'd2) hoursMSD   (systemClk, reset, 1'b1, carryOut4, 1'b0,       count5, carryOut5, hourIs2XIn);
endmodule
