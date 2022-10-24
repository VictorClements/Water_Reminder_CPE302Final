//this decoder will be used for reading in the values from the GPIO
//which will come from the ADC (Analog to Digital Converter)
//it will turn in those values into 4 bit numbers representing the 
//current water level.
//0000 = 0 inches of water, and 1111 = 12 inches of water
//at the moment this assumes 4 bits of precision (16 bits in)
//although we may change this later to 5 bits of precision (32 bits in)
module priorityDecoder(input  logic [15:0] in,
                       output logic [3:0]  out);
  always_comb
    //case statement to decide the current water level
    //it may look a little weird but remember:
    //the water level sensor resistance is inversely proportional
    //to the height of the water, so if the water is very high (say 12 inches)
    //then the resistance will be low (around 400 Ohms)
    //which means that the resulting voltage from running the current through
    //our resistor will be pretty low (around 1V if the current source is 2.5mA)
    //which is the lowest input voltage, so the comparators will all read 0's
    //and vice versa, a very low water level will mean the comparators will all read 1's
    //so that is the explanation behind the below priority decoder...
    casez(in)
      16'b1???????????????: out = 4'b0000;  //low out because all 1's from input
      16'b01??????????????: out = 4'b0001;
      16'b001?????????????: out = 4'b0010;
      16'b0001????????????: out = 4'b0011;
      
      16'b00001???????????: out = 4'b0100;
      16'b000001??????????: out = 4'b0101;
      16'b0000001?????????: out = 4'b0110;
      16'b00000001????????: out = 4'b0111;
      
      16'b000000001???????: out = 4'b1000;
      16'b0000000001??????: out = 4'b1001;
      16'b00000000001?????: out = 4'b1010;
      16'b000000000001????: out = 4'b1011;
      
      16'b0000000000001???: out = 4'b1100;
      16'b00000000000001??: out = 4'b1101;
      16'b000000000000001?: out = 4'b1110;
      16'b0000000000000000: out = 4'b1111;  //high out because all 0's from input

      default:              out = 4'b0000;
    endcase
endmodule

//the reminder module takes in the waterLevel given by the 
//priority decoder as well as the current time given from the
//timer module to calculate if a reminder should be output to
//the VGA monitor.
module reminder(input  logic       clk, reset,
                input  logic [3:0] waterLevel,
                input  logic [3:0] hMSD, hLSD, mMSD, mLSD, sMSD, sLSD
                output logic       remind);
//internal logic signal that will be given to remind if reset = 0
logic reminder;
//asynchronosly resettable register
  always_ff @(posedge clk, posedge reset)
    if(reset) remind <= 1'b0;
    else      remind <= reminder

  always_comb
    //case statement to see based on the current water level, if a reminder is need
    //essentially, every hour that passes in the day requires that you have drinken 
    //more and more of the water. if the water level is 0, then all of the water has
    //been drunk, so there is no need for a reminder
    //then as the water level increases, then there are more times for which you will be reminded
    //to drink, so for water level 0001, you will be reminded if the current time is 22 hours or later
    //and if water level is 0010, then reminder is when time is 21 hours or later, all the way up until
    //1111, where is time is 8 hours or later, then you will be reminded
    case(waterLevel)
      4'b0000:  reminder = 1'b0;
      4'b0001:  if((hMSD == 4'd2) & (hLSD >= 4'd2))                     reminder = 1'b1;
                else  reminder = 1'b0;
      4'b0010:  if((hMSD == 4'd2) & (hLSD >= 4'd1))                     reminder = 1'b1;
                else  reminder = 1'b0;
      4'b0011:  if(hMSD == 4'd2)                                        reminder = 1'b1;
                else  reminder = 1'b0;
      4'b0100:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD == 4'd9))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b0101:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD >= 4'd8))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b0110:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD >= 4'd7))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b0111:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD >= 4'd6))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b1000:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD >= 4'd5))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b1001:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD >= 4'd4))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b1010:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD >= 4'd3))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b1011:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD >= 4'd2))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b1100:  if( (hMSD == 4'd2) | ((hMSD == 4'd1) & (hLSD >= 4'd1))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b1101:  if(hMSD >= 4'd1)                                        reminder = 1'b1;
                else  reminder = 1'b0;
      4'b1110:  if( (hMSD >= 4'd1) | ((hMSD == 4'd0) & (hLSD == 4'd9))) reminder = 1'b1;
                else  reminder = 1'b0;
      4'b1111:  if( (hMSD >= 4'd1) | ((hMSD == 4'd0) & (hLSD >= 4'd8))) reminder = 1'b1;
                else  reminder = 1'b0;
    endcase

endmodule

//seven seg to display currrent time on the FPGA board
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

//basic counter for each digit of our timer, 2 for the hour digits, 2 for the minute digits, and 2 for the second digits
module bcdCounter
        #(parameter Max = 4'd9)
         (input  logic       clk, reset, 
          input  logic       en, cin, 
          input  logic       hourIs2XIn,    //this will only be used for the LSDhour bcd counters, for other counters, we will ground this input
          output logic [3:0] cnt, 
          output logic       cout,
          output logic       hourIs2XOut);  //this will only be used for the LSDhour bcd counters, for other counters, we will not wire this output
  //asynchronosly resettable register
  always_ff @(posedge clk, posedge reset) 
    if (reset)  cnt <= 4'b0; //reset sets the counter to zero
    else if (hourIs2XIn & (cnt == 4'd3) & cin) cnt <= 4'b0; //this is the case for if we are using the hour LSD counter, in which case we will change from hour 23 to 00 instead of to 24
    else if (en)  //if there is the enable signal coming in, then we do regular counter behavior
        if (cout) cnt <= 4'b0; //if the carry out is true, then we will go back to zero
        else      cnt <= cnt + cin; //otherwise, we will add the carry in to count
    //no else needed here since register will hold previous memory value if there is no enable 
 
  //assigns carry out to if we are at the Max value and there is a carry, or if there is a carry, we are the Hour LSD, and if the count is at 3
  assign cout = ((cnt == Max) & cin) | (hourIs2XIn & (cnt == 4'd3) & cin);
  //assigns this signal to if the count is currently at 2 (only to be used for the hour MSD)
  assign hourIs2XOut = cnt == 2;
endmodule

//this instantates 6 bcdCounters, each with 6 sevenSeg displays
//as well as the 3 different clocks so that you can adjust the timer speed (mainly for debugging purposes but 
//this will also be helpful for presentation purposes, since we cant wait an hour during a presention to show a single reminder)
module timer (input  logic       clk, reset,
              input  logic [1:0] selectLine,
              output logic [6:0] display0, display1, display2, display3, display4, display5);

  //internal signals
  logic [3:0] count0, count1, count2, count3, count4, count5; //to hold the bcd counts
  logic       carryOut0, carryOut1, carryOut2, carryOut3, carryOut4, carryOut5; //to hold the bcd carries
  logic       junk0, junk1, junk2, junk3, junk4;  //junk bits for the bcdCounters which arent the hours MSD. WILL NOT BE USED!!!
  logic       hourIs2XIn;                         //signal to outputing from the hour MSD to the hours LSD if the current MSD is 2
  logic       slowClk0, slowClk1, slowClk2;       //3 different clocks that can be switched between using a multiplexer
  logic       systemClk;  //the clock signal actively being used for the system

  always_comb
    // essentially a 3-to-1 mux that decides which clock to use for the system based on the select line
    case(selectLine)
      2'b00:    systemClk = slowClk0;
      2'b01:    systemClk = slowClk1;
      default:  systemClk = slowClk2;
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

  //hex displays for the current time
  sevenseg segs0(count0, display0);
  sevenseg segs1(count1, display1);
  sevenseg segs2(count2, display2);
  sevenseg segs3(count3, display3);
  sevenseg segs4(count4, display4);
  sevenseg segs5(count5, display5);

endmodule

//wrapper module for the timer
module timer_wrapper (input  logic       CLOCK_50,
                      input  logic [2:0] SW,
                      output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);
          //clk,      reset, select[1:0], segs0, segs1, segs2, segs3, segs4, segs5
timer timer(CLOCK_50, SW[0], SW[2:1],     HEX0,  HEX1,  HEX2,  HEX3,  HEX4,  HEX5);
endmodule
