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
