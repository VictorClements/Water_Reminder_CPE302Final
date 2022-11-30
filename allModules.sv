module vgawrapper(input  logic       CLOCK_50,
                  input  logic [2:0] SW,
						      inout  logic [4:0] GPIO,
                  output logic       VGA_CLK, 
                  output logic       VGA_HS,
                  output logic       VGA_VS,
                  output logic       VGA_SYNC_N,
                  output logic       VGA_BLANK_N,
                  output logic [7:0] VGA_R,
                  output logic [7:0] VGA_G,
                  output logic [7:0] VGA_B,
                  output logic [6:0] HEX0, HEX1, HEX2, HEX3);
						
  vga vga(CLOCK_50, SW[0], {GPIO[0], GPIO[1], GPIO[2], GPIO[3]},
          SW[2:1], VGA_CLK, VGA_HS, VGA_VS, VGA_SYNC_N, VGA_BLANK_N,
		      GPIO[4], VGA_R, VGA_G, VGA_B, HEX0, HEX1, HEX2, HEX3);
			 
endmodule
//================================================================================================================================//
module vga(input  logic clk, reset, 
           input  logic [3:0] water_level,
           input  logic [1:0] selectLine,
           output logic vgaclk,          // 25.175 MHz VGA clock 
           output logic hsync, vsync, 
           output logic sync_b, blank_b, // to monitor & DAC 
			     output logic extendedRemind,           // audio reminder
           output logic [7:0] r, g, b,
           output logic [6:0] display0, display1, display2, display3);  // to video DAC 
           
  logic       remainder;
  logic [3:0] stablizedWaterLevel;
  logic [3:0] count0, count1, count2, count3;
  logic [9:0] x, y; 
  logic [5:0] water_drunk;             // sum of all water drunk by the user
  logic [7:0] decimal_water_drunk;     // changing water_drunk to decimal from the look up table;

  timer timer1(clk, reset, water_level, selectLine, remainder, stablizedWaterLevel,
               count0, count1, count2, count3, water_drunk, display0, display1, display2, display3);
  //audio ad1(remainder, clk, reset,AUDIO);

  remindExtender extendUnit(clk, reset, remainder, extendedRemind);

  // changing water_drunk to decimal number
  LUT lut(water_drunk,decimal_water_drunk);
  // Use a clock divider to create the 25 MHz VGA pixel clock 
  // 25 MHz clk period = 40 ns 
  // Screen is 800 clocks wide by 525 tall, but only 640 x 480 used for display 
  // HSync = 1/(40 ns * 800) = 31.25 kHz 
  // Vsync = 31.25 KHz / 525 = 59.52 Hz (~60 Hz refresh rate) 
  
  // divide 50 MHz input clock by 2 to get 25 MHz clock
  always_ff @(posedge clk, posedge reset)
    if (reset)
	   vgaclk = 1'b0;
    else
	   vgaclk = ~vgaclk;
		
  // generate monitor timing signals 
  vgaController vgaCont(vgaclk, reset, hsync, vsync, sync_b, blank_b, x, y); 

  // user-defined module to determine pixel color 
  videoGen videoGen(x, y, count0, count1, count2, count3, stablizedWaterLevel, extendedRemind, decimal_water_drunk, r, g, b); 
  
endmodule 
//================================================================================================================================//
module vgaController #(parameter HBP     = 10'd48,   // horizontal back porch
                                 HACTIVE = 10'd640,  // number of pixels per line
                                 HFP     = 10'd16,   // horizontal front porch
                                 HSYN    = 10'd96,   // horizontal sync pulse = 96 to move electron gun back to left
                                 HMAX    = HBP + HACTIVE + HFP + HSYN, //48+640+16+96=800: number of horizontal pixels (i.e., clock cycles)
                                 VBP     = 10'd32,   // vertical back porch
                                 VACTIVE = 10'd480,  // number of lines
                                 VFP     = 10'd11,   // vertical front porch
                                 VSYN    = 10'd2,    // vertical sync pulse = 2 to move electron gun back to top
                                 VMAX    = VBP + VACTIVE + VFP  + VSYN) //32+480+11+2=525: number of vertical pixels (i.e., clock cycles)                      

     (input  logic vgaclk, reset,
      output logic hsync, vsync, sync_b, blank_b, 
      output logic [9:0] hcnt, vcnt); 

      // counters for horizontal and vertical positions 
      always @(posedge vgaclk, posedge reset) begin 
        if (reset) begin
          hcnt <= 0;
          vcnt <= 0;
        end
        else  begin
          hcnt++; 
      	   if (hcnt == HMAX) begin 
            hcnt <= 0; 
  	        vcnt++; 
  	        if (vcnt == VMAX) 
  	          vcnt <= 0; 
          end 
        end
      end 
	  
      // compute sync signals (active low)
      assign hsync  = ~( (hcnt >= (HBP + HACTIVE + HFP)) & (hcnt < HMAX) ); 
      assign vsync  = ~( (vcnt >= (VBP + VACTIVE + VFP)) & (vcnt < VMAX) ); 

      // assign sync_b = hsync & vsync; 
      assign sync_b = 1'b0;  // this should be 0 for newer monitors

      // force outputs to black when not writing pixels
      assign blank_b = (hcnt > HBP & hcnt < (HBP + HACTIVE)) & (vcnt > VBP & vcnt < (VBP + VACTIVE)); 
endmodule 
//================================================================================================================================//
module videoGen(input logic [9:0] x, y, 
                input logic [3:0] count0, count1, count2, count3,
                input logic [3:0] water_level,
                input logic       remainder,
                input logic  [7:0] water_drunk,
                output logic [7:0] r, g, b); 
    // displaying for water levels
    logic level_1, level_2, level_3, level_4, level_5, level_6, level_7, level_8,
        level_9, level_10, level_11, level_12, level_13, level_14, level_15; 
//	// displaying the remainder in the VGA
//	logic remainder_inrect;
    
    // rectagular shape for  water level
    logic right, left, top , bottom;

  //for displaying DRINK!
  logic pixel1, pixel2, pixel3, pixel4, pixel5, pixel6;
  
  //for displaying current time (00:00)
  logic colon, num1, num2, num3, num4;
  
  //for displaying number for total water drunk
  logic num5, num6;
  
  //for displaying TOTAL : 
  logic pixel7, pixel8, pixel9, pixel10, pixel11, pixel12;

  //for displaying WATER REMINDER (t because title)
  logic t0, t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12;

//the 15 bars to represent the water level
  rectgen rectgen1(x, y, 10'd148, 10'd395, 10'd250, 10'd400,  level_1);
  rectgen rectgen2(x, y, 10'd148, 10'd385, 10'd250, 10'd390,  level_2);
  rectgen rectgen3(x, y, 10'd148, 10'd375, 10'd250, 10'd380,  level_3);
  rectgen rectgen4(x, y, 10'd148, 10'd365, 10'd250, 10'd370,  level_4);
  rectgen rectgen5(x, y, 10'd148, 10'd355, 10'd250, 10'd360,  level_5);
  rectgen rectgen6(x, y, 10'd148, 10'd345, 10'd250, 10'd350,  level_6);
  rectgen rectgen7(x, y, 10'd148, 10'd335, 10'd250, 10'd340,  level_7);
  rectgen rectgen8(x, y, 10'd148, 10'd325, 10'd250, 10'd330,  level_8);
  rectgen rectgen9(x, y, 10'd148, 10'd315, 10'd250, 10'd320,  level_9);
  rectgen rectgen10(x, y, 10'd148, 10'd305, 10'd250, 10'd310, level_10);
  rectgen rectgen11(x, y, 10'd148, 10'd295, 10'd250, 10'd300, level_11);
  rectgen rectgen12(x, y, 10'd148, 10'd285, 10'd250, 10'd290, level_12);
  rectgen rectgen13(x, y, 10'd148, 10'd275, 10'd250, 10'd280, level_13);
  rectgen rectgen14(x, y, 10'd148, 10'd265, 10'd250, 10'd270, level_14);
  rectgen rectgen15(x, y, 10'd148, 10'd255, 10'd250, 10'd260, level_15);

// four bars for the border of the "water bottle"
  rectgen rectgen16(x,y,  10'd255, 10'd245, 10'd260, 10'd410, right);
  rectgen rectgen17(x,y,  10'd138, 10'd250, 10'd143, 10'd405, left);
  rectgen rectgen18(x,y,  10'd138, 10'd245, 10'd255, 10'd250, top);
  rectgen rectgen19(x,y,  10'd138, 10'd405, 10'd255, 10'd410, bottom);

  logic [14:0] inrect;
  assign inrect = {level_1,level_2,level_3,level_4,level_5,
                   level_6,level_7,level_8,level_9,level_10,level_11,level_12,
                   level_13,level_14,level_15};

//letters to display when reminder is active (DRINK!)
letterGen letter1(x, y, 10'd300, 10'd300, 10'd315, 10'd320, 6'd3,  pixel1);
letterGen letter2(x, y, 10'd320, 10'd300, 10'd335, 10'd320, 6'd17, pixel2);
letterGen letter3(x, y, 10'd340, 10'd300, 10'd355, 10'd320, 6'd8,  pixel3);
letterGen letter4(x, y, 10'd360, 10'd300, 10'd375, 10'd320, 6'd13, pixel4);
letterGen letter5(x, y, 10'd380, 10'd300, 10'd395, 10'd320, 6'd10, pixel5);
letterGen letter6(x, y, 10'd400, 10'd300, 10'd415, 10'd320, 6'd26, pixel6);

//numbers to display the current time (00:00)
letterGen number1(x, y, 10'd300, 10'd360, 10'd315, 10'd380, (6'd28+{2'b0, count3}), num1);
letterGen number2(x, y, 10'd320, 10'd360, 10'd335, 10'd380, (6'd28+{2'b0, count2}), num2);
letterGen colonSy(x, y, 10'd340, 10'd360, 10'd355, 10'd380,  6'd27,                 colon);
letterGen number3(x, y, 10'd360, 10'd360, 10'd375, 10'd380, (6'd28+{2'b0, count1}), num3);
letterGen number4(x, y, 10'd380, 10'd360, 10'd395, 10'd380, (6'd28+{2'b0, count0}), num4);

letterGen letter7 (x, y, 10'd440, 10'd150, 10'd455, 10'd170, 6'd19, pixel7);   // T
letterGen letter8 (x, y, 10'd460, 10'd150, 10'd475, 10'd170, 6'd14, pixel8);   // O
letterGen letter9 (x, y, 10'd480, 10'd150, 10'd495, 10'd170, 6'd19, pixel9);   // T
letterGen letter10(x, y, 10'd500, 10'd150, 10'd515, 10'd170, 6'd0,  pixel10);   // A
letterGen letter11(x, y, 10'd520, 10'd150, 10'd535, 10'd170, 6'd11, pixel11);   // L
letterGen letter12(x, y, 10'd540, 10'd150, 10'd555, 10'd170, 6'd27, pixel12);   // :
letterGen letter111(x, y, 10'd560, 10'd150, 10'd575,10'd170, (6'd28 +{2'b0, water_drunk[7:4]}), num5);     // numbers after total 
letterGen letter222(x, y, 10'd580, 10'd150, 10'd595, 10'd170, (6'd28 +{2'b0, water_drunk[3:0]}), num6);    // numbers after total

//letters to display title of project
letterGen title0 (x, y, 10'd230, 10'd50, 10'd245, 10'd70, 6'd22, t0); // W
letterGen title1 (x, y, 10'd250, 10'd50, 10'd265, 10'd70, 6'd0,  t1); // A
letterGen title2 (x, y, 10'd270, 10'd50, 10'd285, 10'd70, 6'd19, t2); // T
letterGen title3 (x, y, 10'd290, 10'd50, 10'd305, 10'd70, 6'd4 , t3); // E
letterGen title4 (x, y, 10'd310, 10'd50, 10'd325, 10'd70, 6'd17, t4); // R
                                                                      // space
letterGen title5 (x, y, 10'd350, 10'd50, 10'd365, 10'd70, 6'd17, t5); // R
letterGen title6 (x, y, 10'd370, 10'd50, 10'd385, 10'd70, 6'd4,  t6); // E
letterGen title7 (x, y, 10'd390, 10'd50, 10'd405, 10'd70, 6'd12, t7); // M
letterGen title8 (x, y, 10'd410, 10'd50, 10'd425, 10'd70, 6'd8 , t8); // I
letterGen title9 (x, y, 10'd430, 10'd50, 10'd445, 10'd70, 6'd13, t9); // N
letterGen title10(x, y, 10'd450, 10'd50, 10'd465, 10'd70, 6'd3 , t10);// D
letterGen title11(x, y, 10'd470, 10'd50, 10'd485, 10'd70, 6'd4 , t11);// E
letterGen title12(x, y, 10'd490, 10'd50, 10'd505, 10'd70, 6'd17, t12);// R

  always_comb
   begin
       case(inrect)
            15'h4000: if(water_level >= 4'b0001) {r,g,b} = 24'h0000FF; // blue
                      else                       {r,g,b} = 24'h000000;  // black
            15'h2000: if(water_level >= 4'b0010) {r,g,b} = 24'h0000FF; // blue
                      else                       {r,g,b} = 24'h000000;  // black
            15'h1000: if(water_level >= 4'b0011) {r,g,b} = 24'h0000FF; // blue
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0800: if(water_level >= 4'b0100) {r,g,b} = 24'h0000FF; // blue
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0400: if(water_level >= 4'b0101) {r,g,b} = 24'h0000FF; // blue
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0200: if(water_level >= 4'b0110) {r,g,b} = 24'h0000FF; // blue
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0100: if(water_level >= 4'b0111) {r,g,b} = 24'h0000FF; // blue
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0080: if(water_level >= 4'b1000) {r,g,b} = 24'h0000FF; // blue
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0040: if(water_level >= 4'b1001) {r,g,b} = 24'h0000FF; // blue
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0020: if(water_level >= 4'b1010) {r,g,b} = 24'h0000FF; // blue
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0010: if(water_level >= 4'b1011) {r,g,b} = 24'h0000FF; // blue
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0008: if(water_level >= 4'b1100) {r,g,b} = 24'h0000FF; // blue
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0004: if(water_level >= 4'b1101) {r,g,b} = 24'h0000FF; // blue
                      else            	          {r,g,b} = 24'h000000;  // black
            15'h0002: if(water_level >= 4'b1110) {r,g,b} = 24'h0000FF; // blue
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0001: if(water_level >= 4'b1111) {r,g,b} = 24'h0000FF; // blue
                      else                       {r,g,b} = 24'h000000;  // black
            default: {r,g,b} = 24'h000000;
       endcase
    
        if(top | left | right | bottom) {r, g, b} = 24'hffffff;
        
        if(colon | num1 | num2 | num3 | num4) {r, g, b} = 24'h00ff00;
		
		// displaying the total
		if(pixel7 | pixel8 | pixel9 | pixel10 | pixel11 | pixel12 | t0 | t1 |
       t2 | t3 | t4 | t5 | t6 | t7 | t8 | t9 | t10 | t11 | t12) {r, g, b} = 24'hFFFFFF;
		
		
		// Displaying the total sum of water drunk
		if(num5 | num6) {r, g, b} = 24'hffffff;
		  
        if(pixel1 | pixel2 | pixel3 | pixel4 | pixel5 | pixel6)begin
				  if(remainder){r,g,b} = 24'hFF0000;
				  else  {r,g,b} = 24'h000000;
			  end
        //else                            {r,g,b} = 24'h000000;
    end

endmodule
//====================================================================================================================================//
module rectgen(input  logic [9:0] x, y, left, top, right, bot, 
               output logic inrect);
  assign inrect = (x >= left & x < right & y >= top & y < bot); 
endmodule 
//================================================================================================================================//
module letterGen(input  logic [9:0] x, y,   //current x and y position
                // used to see if current position is within bounds
                 input  logic [9:0] left, top, right, bot,  
                 input  logic [5:0] letterSelect,   // 0, 1, ... , 38
                 output logic       pixel); //output for coloring pixel
  //bit for saying if current pixel is in the rectangle
  logic        inrect;  
  //depth of ROM is 780, and length of each line is 15 bits
  logic [14:0] charrom [779:0];  
  logic [14:0] line;            //individual line of character rom
  
  assign inrect = (x >= left & x < right & y >= top & y < bot); //from rectGen

  initial $readmemb("characterROM.txt", charrom); //reads in bitmaps

  assign line = charrom[letterSelect*20 + (y-top)]; //fancy stuff (see to right)
  
  // very similar to chargenrom from the provided VGA module
  //flip the bits of the current line so display isnt backwards (10'b14 -)
  //also pixel should only be true if we are within the bounds (inrect &)
  //finally we figure out which bit in the line we are out by seeing how
  //far we are from the left bound of the rectangle (x - left)
  assign pixel = inrect & line[10'd14-(x-left)];
endmodule

//comments for the "assign line = " above:

//to select the line you want, you need to
//determine where you are in the screen at 
//the moment, in particular, you want to know 
//where you are with respect to the bitmap 
//you are trying to generate the "letterSelect*20"
// tells you which of the letters we want 
//to pick from our rom, since each letter has
// a 20 bit depth, so selecting the character 
//is in increments of 20 bits

//the y-top part essentially is telling you 
//which line to read from the current letter you at
//kind of like an offset within the letter itself, 
//which is determined by figuring out your current
//position with respect to the top of the letter box, 
//which is y - top.
//================================================================================================================================//
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
//================================================================================================================================//
module waterDrunk
       #(parameter width = 6)
        (input  logic             clk, reset,
         input  logic [15:0]      count,       //current time passed (in 30 minute intervals)  
         input  logic [3:0]       water_level, //current water level
         output logic [width-1:0] water_drunk, //how much water has been drunk
         output logic             drank);      //true if water was drunk during the 30 minute time period


//internal signals

logic [4:0] new_level, old_level; //wires for the shift register
logic [4:0] difference;           //stores the difference between the prior water level and the current water level
logic       positive;             //holds whether the difference is positive    
logic [4:0] addToCounter;         //the amount to be added to the water_drunk counter
logic       drankReset;           //Reset signal of the register holding the drank value

always_ff @(posedge clk, posedge reset)
  if(reset) {new_level, old_level} <= 10'b0;
  else      {new_level[3:0], old_level[3:0]} 
            <= {water_level, new_level[3:0]};

//4 bit bus to hold the subtraction of the old and new water levels to find if any water was drunk
assign difference = old_level - new_level;

//1 bit wire to hold if the difference signal is positive 
assign positive = old_level > new_level;

//mux to select between the difference (if its positive) or zero (if not positive)
mux2 #(5) mymux (5'b0, difference, positive, addToCounter);

//counter register that holds the total amount of water drunk
always_ff @(posedge clk, posedge reset)
  if(reset) water_drunk <= 0;
  else      water_drunk <= water_drunk + addToCounter;

//assign drankReset wire to be true if reset is high or the time is back to 0 minutes
assign drankReset = reset | (count == 16'b0);

//register to hold if there was a drink during the current 30 minute interval
always_ff @(posedge clk, posedge drankReset)
  if(drankReset)  drank <= 1'b0;
  else            drank <= drank | positive;    //the point of this is that the register will permanently store a 1 if it ever recieves a 1
endmodule
//================================================================================================================================//
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
//================================================================================================================================//
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
//================================================================================================================================//
module remindExtender(input  logic clk, reset,
                      input  logic reminder,
                      output logic extended);

  logic [26:0] count;
  logic        enable, reminderReset;

  assign reminderReset = reset | count[26];
  assign enable = ~extended;

  always_ff @(posedge clk, posedge reminderReset)
    if(reminderReset)   extended <= 1'b0;
    else if(enable) extended <= reminder;

  always_ff @(posedge clk, posedge reminderReset)
    if(reminderReset)   count <= 27'b0;
    else                count <= count + extended;

    assign extended = extended;
endmodule
//================================================================================================================================//
module mux2
  #(parameter width = 4)
   (input  logic [width-1:0] d0, d1, 
    input  logic             s,
    output logic [width-1:0] y);

   assign y = s ? d1 : d0; 
endmodule
//================================================================================================================================//
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
//================================================================================================================================//
//basic counter for each digit of our timer, 2 for the hour digits, 2 for the minute digits, and 2 for the second digits
module bcdCounter
        #(parameter Max = 4'd9)
         (input  logic       clk, reset, 
          input  logic       en, cin,       //at the moment the en signal is always kept high, so there is no need for it
          input  logic       hourIs2XIn,    //this will only be used for the LSDhour bcd counters, for other counters, we will ground this input
          output logic [3:0] cnt, 
          output logic       cout,
          output logic       hourIs2XOut);  //this will only be used for the MSDhour bcd counters, for other counters, it will be tied to an unused junk wire

  //asynchronosly resettable register
  always_ff @(posedge clk, posedge reset) 
    //reset sets the counter to zero
    if (reset)  cnt <= 4'b0; 
    //this is the case for if we are using the hour LSD counter, in which case we will change from hour 23 to 00 instead of to 24
    else if (hourIs2XIn & (cnt == 4'd3) & cin) cnt <= 4'b0; 
    //if there is the enable signal coming in, then we do regular counter behavior
    else if (en)  
        //if the carry out is true, then we will go back to zero
        if (cout) cnt <= 4'b0; 
        //otherwise, we will add the carry in to count
        else      cnt <= cnt + cin; 
    //no else needed here since register will hold previous memory value if there is no enable 
 
  //assigns carry out to if we are at the Max value and there is a carry, or if there is a carry, we are the Hour LSD, and if the count is at 3
  assign cout = ((cnt == Max) & cin) | (hourIs2XIn & (cnt == 4'd3) & cin);

  //assigns this signal to if the count is currently at 2 (only to be used for the hour MSD)
  assign hourIs2XOut = cnt == 2;
endmodule
//================================================================================================================================//
module audio(input  logic reminder, clk,reset,
             output logic toBuzzer);
  logic slowclk;

  Clock760Hz Hz(clk,reset,slowclk);
  assign toBuzzer = reminder ? slowclk : 1'b0;
endmodule
//================================================================================================================================//
module LUT(input  logic [5:0] binaryNum,
           output logic [7:0] decimalNum);

  always_comb
    case(binaryNum)
           6'd0:  decimalNum = {4'd0, 4'd0};
           6'd1:  decimalNum = {4'd0, 4'd1};
           6'd2:  decimalNum = {4'd0, 4'd2};
           6'd3:  decimalNum = {4'd0, 4'd3};
           6'd4:  decimalNum = {4'd0, 4'd4};
           6'd5:  decimalNum = {4'd0, 4'd5};
           6'd6:  decimalNum = {4'd0, 4'd6};
           6'd7:  decimalNum = {4'd0, 4'd7};
           6'd8:  decimalNum = {4'd0, 4'd8};
           6'd9:  decimalNum = {4'd0, 4'd9};
           6'd10: decimalNum = {4'd1, 4'd0};
           6'd11: decimalNum = {4'd1, 4'd1};
           6'd12: decimalNum = {4'd1, 4'd2};
           6'd13: decimalNum = {4'd1, 4'd3};
           6'd14: decimalNum = {4'd1, 4'd4};
           6'd15: decimalNum = {4'd1, 4'd5};
           6'd16: decimalNum = {4'd1, 4'd6};
           6'd17: decimalNum = {4'd1, 4'd7};
           6'd18: decimalNum = {4'd1, 4'd8};
           6'd19: decimalNum = {4'd1, 4'd9};
           6'd20: decimalNum = {4'd2, 4'd0};
           6'd21: decimalNum = {4'd2, 4'd1};
           6'd22: decimalNum = {4'd2, 4'd2};
           6'd23: decimalNum = {4'd2, 4'd3};
           6'd24: decimalNum = {4'd2, 4'd4};
           6'd25: decimalNum = {4'd2, 4'd5};
           6'd26: decimalNum = {4'd2, 4'd6};
           6'd27: decimalNum = {4'd2, 4'd7};
           6'd28: decimalNum = {4'd2, 4'd8};
           6'd29: decimalNum = {4'd2, 4'd9};
           6'd30: decimalNum = {4'd3, 4'd0};
           6'd31: decimalNum = {4'd3, 4'd1};
           6'd32: decimalNum = {4'd3,4'd2};
           6'd33: decimalNum = {4'd3,4'd3}; 
           6'd34: decimalNum = {4'd3,4'd4};
           6'd35: decimalNum = {4'd3,4'd5};
           6'd36: decimalNum = {4'd3,4'd6};
           6'd37: decimalNum = {4'd3,4'd7};
           6'd38: decimalNum = {4'd3,4'd8};
           6'd39: decimalNum = {4'd3,4'd9};
           6'd40: decimalNum = {4'd4,4'd0};
           6'd41: decimalNum = {4'd4,4'd1};
           6'd42: decimalNum = {4'd4,4'd2};
           6'd43: decimalNum = {4'd4,4'd3};
           6'd44: decimalNum = {4'd4,4'd4};
           6'd45: decimalNum = {4'd4,4'd5};
           6'd46: decimalNum = {4'd4,4'd6};
           6'd47: decimalNum = {4'd4,4'd7};
           6'd48: decimalNum = {4'd4,4'd8};
           6'd49: decimalNum = {4'd4,4'd9};
           6'd50: decimalNum = {4'd5,4'd0};
           6'd51: decimalNum = {4'd5,4'd1};
           6'd52: decimalNum = {4'd5,4'd2};
           6'd53: decimalNum = {4'd5,4'd3};
           6'd54: decimalNum = {4'd5,4'd4};
           6'd55: decimalNum = {4'd5,4'd5};
           6'd56: decimalNum = {4'd5,4'd6};
           6'd57: decimalNum = {4'd5,4'd7};
           6'd58: decimalNum = {4'd5,4'd8};
           6'd59: decimalNum = {4'd5,4'd9};
           6'd60: decimalNum = {4'd6,4'd0};
           6'd61: decimalNum = {4'd6,4'd1};
           6'd62: decimalNum = {4'd6,4'd2};
           6'd63: decimalNum = {4'd6,4'd3};    
    endcase
endmodule
//================================================================================================================================//