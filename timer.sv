//this instantates 6 bcdCounters, each with 6 sevenSeg displays
//as well as the 3 different clocks so that you can adjust the timer speed (mainly for debugging purposes but 
//this will also be helpful for presentation purposes, since we cant wait an hour during a presention to show a single reminder)
module timer (input  logic       clk, reset,
              input  logic [3:0] waterLevelIn,
              input  logic [1:0] selectLine,
              output logic       remind,
              output logic [3:0] stablizedWaterLevel,
              output logic [3:0] count0, count1, count2, count3,
              output logic [5:0] water_drunk,
              output logic [6:0] display0, display1, display2, display3);

  //internal signals
  logic       carryOut0, carryOut1, carryOut2, carryOut3; //to hold the bcd carries
  logic       junk0, junk1, junk2, junk3;  //junk bits for the bcdCounters which arent the hours MSD. WILL NOT BE USED!!!
  logic       slowClk0, slowClk1, slowClk2;       //3 different clocks that can be switched between using a multiplexer
  logic       systemClk;  //the clock signal actively being used for the system
  logic       drank;

  always_comb
    // essentially a 3-to-1 mux that decides which clock to use for the system based on the select line
    case(selectLine)
      2'b00:    systemClk = slowClk0;
      2'b01:    systemClk = slowClk1;
      default:    systemClk = slowClk2;
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
  bcdCounter #(4'd2) minutesMSD (systemClk, reset, 1'b1, carryOut2, 1'b0,       count3, carryOut3, junk3);

  //water level stabilizer to make sure the user deciding they hate me wont cause the entire design to freak out
  waterLevelChecker  stablizer  (slowClk0, reset, waterLevelIn, stablizedWaterLevel);
  //module to keep running count of total amount of water drunk
  waterDrunk #(6)    amount     (clk, reset, {count3, count2, count1, count0}, stablizedWaterLevel, water_drunk, drank);
  
  //remind signal to tell the vga to display if there is a reminder
  assign remind = (count3 == 4'd2) & carryOut2 & ~drank;

  //hex displays for the current time
  //replace later in favor of displaying on vga
  sevenseg segs0(count0, display0);
  sevenseg segs1(count1, display1);
  sevenseg segs2(count2, display2);
  sevenseg segs3(count3, display3);
endmodule
