module sevenseg(input  logic [3:0] data,
                output logic [6:0] segments);

  always_comb
  case (data)           //Sg - Sa
    4'h0:    segments = 7'b1000000;  // 40
    4'h1:    segments = 7'b1111001;  // 79
    4'h2:    segments = 7'b0100100;  // 24
    4'h3:    segments = 7'b0110000;  // 30
    4'h4:    segments = 7'b0011001;  // 19
    4'h5:    segments = 7'b0010010;  // 12
    4'h6:    segments = 7'b0000010;  // 02
    4'h7:    segments = 7'b1111000;  // 78
    4'h8:    segments = 7'b0000000;  // 00
    4'h9:    segments = 7'b0011000;  // 18
    4'hA:    segments = 7'b0001000;  // 08
    4'hB:    segments = 7'b0000011;  // 03
    4'hC:    segments = 7'b0100111;  // 27
    4'hD:    segments = 7'b0100001;  // 21
    4'hE:    segments = 7'b0000110;  // 06
    4'hF:    segments = 7'b0001110;  // 0E
    default: segments = 7'bx;        // xx
  endcase
  
endmodule

module clock1Hz
         (input  logic clk, reset,
          output logic slowClk);

  logic [39:0] count;

  always_ff @(posedge clk, posedge reset)
    if (reset)  count <= 40'b0;
    else          count <= count + 40'd21990;
assign slowClk = count[39];

endmodule

module clock60Hz
         (input  logic clk, reset,
          output logic slowClk);

  logic [39:0] count;

  always_ff @(posedge clk, posedge reset)
    if (reset)  count <= 40'b0;
    else          count <= count + 40'd1319414;
assign slowClk = count[39];

endmodule

module clock3600Hz
         (input  logic clk, reset,
          output logic slowClk);

  logic [39:0] count;

  always_ff @(posedge clk, posedge reset)
    if (reset)  count <= 40'b0;
    else          count <= count + 40'd79164837;
assign slowClk = count[39];

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
              input  logic [1:0] selectLine,
              output logic [6:0] display0, display1, display2, display3, display4, display5);

  //internal signals
  logic [3:0] count0, count1, count2, count3, count4, count5;
  logic       carryOut0, carryOut1, carryOut2, carryOut3, carryOut4, carryOut5;
  logic       junk0, junk1, junk2, junk3, junk4;
  logic       hourIs2XIn;
  logic       slowClk0, slowClk1, slowClk2;
  logic       systemClk; 

  always_comb
    case(selectLine)
      2'b00:    systemClk = slowClk0;
      2'b01:    systemClk = slowClk1;
      default:  systemClk = slowClk2;
    endcase

  //clock for slowing this bad boi down
  clock1Hz    clock1Hz    (clk, reset, slowClk0);
  clock60Hz   clock60Hz   (clk, reset, slowClk1);
  clock3600Hz clock3600Hz (clk, reset, slowClk2);

  //instantiate the bcd counters for seconds
  bcdCounter #(4'd9) secondsLSD (systemClk, reset, 1'b1, 1'b1,      1'b0,       count0, carryOut0, junk0);
  bcdCounter #(4'd5) secondsMSD (systemClk, reset, 1'b1, carryOut0, 1'b0,       count1, carryOut1, junk1);
  //instantiate the bcd counters for minutes
  bcdCounter #(4'd9) minutesLSD (systemClk, reset, 1'b1, carryOut1, 1'b0,       count2, carryOut2, junk2);
  bcdCounter #(4'd5) minutesMSD (systemClk, reset, 1'b1, carryOut2, 1'b0,       count3, carryOut3, junk3);
  //instantiate the bcd counters for hours
  bcdCounter #(4'd9) hoursLSD   (systemClk, reset, 1'b1, carryOut3, hourIs2XIn, count4, carryOut4, junk4);
  bcdCounter #(4'd2) hoursMSD   (systemClk, reset, 1'b1, carryOut4, 1'b0,       count5, carryOut5, hourIs2XIn);

  //hex displays for the current time
  sevenseg segs0(count0, display0);
  sevenseg segs1(count1, display1);
  sevenseg segs2(count2, display2);
  sevenseg segs3(count3, display3);
  sevenseg segs4(count4, display4);
  sevenseg segs5(count5, display5);

endmodule

module timer_wrapper (input  logic       CLOCK_50,
                      input  logic [2:0] SW,
                      output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);
timer timer(CLOCK_50, SW[0], SW[2:1], HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);
endmodule
