//this instantates 6 bcdCounters, each with 6 sevenSeg displays
//as well as the 3 different clocks so that you can adjust the timer speed (mainly for debugging purposes but 
//this will also be helpful for presentation purposes, since we cant wait an hour during a presention to show a single reminder)
module timer (input  logic       clk, reset,
              input  logic [3:0] water_level,
              input  logic [1:0] selectLine,
              output logic       remind,
              output logic [6:0] display0, display1, display2, display3, display4, display5);

  //internal signals
  logic [3:0] count0, count1, count2, count3, count4, count5; //to hold the bcd counts
  logic       carryOut0, carryOut1, carryOut2, carryOut3, carryOut4, carryOut5; //to hold the bcd carries
  logic       junk0, junk1, junk2, junk3, junk4;  //junk bits for the bcdCounters which arent the hours MSD. WILL NOT BE USED!!!
  logic       hourIs2XIn;                         //signal to outputing from the hour MSD to the hours LSD if the current MSD is 2
  logic       slowClk0, slowClk1, slowClk2;       //3 different clocks that can be switched between using a multiplexer
  logic       systemClk;  //the clock signal actively being used for the system

  always_comb
    // 3-to-1 mux that decides which clock to use for the system based on the select line
    // mainly for demo and debugging for hardware
    case(selectLine)
      2'b00:    systemClk = slowClk0;
      2'b01:    systemClk = slowClk1;
      //default:  systemClk = slowClk2;
      default:  systemClk = clk;  //FOR SIMULATION ONLY!
    endcase

  //clocks for different desired speeds
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

  //instantiate the reminder module to calculate if a reminder is needed
  reminder reminder(systemClk, reset, water_level, count5, count4, remind);

  //hex displays for the current time
  sevenseg segs0(count0, display0);
  sevenseg segs1(count1, display1);
  sevenseg segs2(count2, display2);
  sevenseg segs3(count3, display3);
  sevenseg segs4(count4, display4);
  sevenseg segs5(count5, display5);
endmodule