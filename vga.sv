// vga.sv

module vga(input  logic clk, reset, 
           input  logic [3:0] water_level,
           input  logic [1:0] selectLine,
           output logic vgaclk,          // 25.175 MHz VGA clock 
           output logic hsync, vsync, 
           output logic sync_b, blank_b, // to monitor & DAC 
           output logic [7:0] r, g, b,
           output logic [6:0] display0, display1, display2, display3, display4, display5);  // to video DAC 
           
  logic remainder;
  logic [9:0] x, y; 

  timer timer1(clk, reset, water_level, selectLine, remainder, display0, display1, display2, display3, display4, display5);

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
  videoGen videoGen(x, y,water_level,remainder,r, g, b); 
  
endmodule 


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

/*
module videoGen(input logic [9:0] x, y, output logic [7:0] r, g, b); 
  always_comb
    if (x < 10'd300 & y > 10'd50) {r, g, b} = 24'hff0000;
    else                          {r, g, b} = 24'h0000ff;	 

endmodule
*/

module videoGen(input logic [9:0] x, y, 
                input logic [3:0] water_level,
                input logic       remainder,
                output logic [7:0] r, g, b); 
    // displaying for water levels
    logic level_1, level_2, level_3, level_4, level_5, level_6, level_7, level_8,
        level_9, level_10, level_11, level_12, level_13, level_14, level_15; 
	// displaying the remainder in the VGA
	logic remainder_inrect;
    
    // rectagular shape for  water level
    logic right, left, top , bottom;



    /////// continue from this
  
  // given y position, choose a character to display 
  // then look up the pixel value from the character ROM 
  // and display it in red or blue. Also draw a green rectangle. 
  // module rectgen(input  logic [9:0] x, y, left, top, right, bot, 
  //              output logic inrect);
  //chargenrom chargenromb(y[8:3]+8'd65, x[2:0], y[2:0], pixel); 
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

  rectgen rectgen16(x,y,  10'd255, 10'd245, 10'd260, 10'd410, right);
  rectgen rectgen17(x,y,  10'd138, 10'd250, 10'd143, 10'd405, left);
  rectgen rectgen18(x,y,  10'd138, 10'd245, 10'd255, 10'd250, top);
  rectgen rectgen19(x,y,  10'd138, 10'd405, 10'd255, 10'd410, bottom);
  rectgen rectgen20(x,y,  10'd370, 10'd60, 10'd420, 10'd70, remainder_inrect);
  //assign {r, b} = (y[3]==0) ? {{8{pixel}},8'h00} : {8'h00, {8{pixel}}}; 
  //assign g      = inrect    ? 8'hFF : 8'h00;  

  logic [14:0] inrect;
  assign inrect = {level_1,level_2,level_3,level_4,level_5,
                   level_6,level_7,level_8,level_9,level_10,level_11,level_12,
                   level_13,level_14,level_15};
  always_comb
   begin
       case(inrect)
            15'h4000: if(water_level >= 4'b0001) {r,g,b} = 24'hFF0000; // red
                      else                       {r,g,b} = 24'h000000;  // black
            15'h2000: if(water_level >= 4'b0010) {r,g,b} = 24'hFF0000; // red
                      else                       {r,g,b} = 24'h000000;  // black
            15'h1000: if(water_level >= 4'b0011) {r,g,b} = 24'hFF0000; // red
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0800: if(water_level >= 4'b0100) {r,g,b} = 24'hFF0000; // red
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0400: if(water_level >= 4'b0101) {r,g,b} = 24'hFF0000; // red
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0200: if(water_level >= 4'b0110) {r,g,b} = 24'hFF0000; // red
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0100: if(water_level >= 4'b0111) {r,g,b} = 24'hFF0000; // red
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0080: if(water_level >= 4'b1000) {r,g,b} = 24'hFF0000; // red
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0040: if(water_level >= 4'b1001) {r,g,b} = 24'hFF0000; // red
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0020: if(water_level >= 4'b1010) {r,g,b} = 24'hFF0000; // red
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0010: if(water_level >= 4'b1011) {r,g,b} = 24'hFF0000; // red
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0008: if(water_level >= 4'b1100) {r,g,b} = 24'hFF0000; // red
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0004: if(water_level >= 4'b1101)  {r,g,b} = 24'hFF0000; // red
                      else            	          {r,g,b} = 24'h000000;  // black
            15'h0002: if(water_level >= 4'b1110) {r,g,b} = 24'hFF0000; // red
                      else                       {r,g,b} = 24'h000000;  // black
            15'h0001: if(water_level >= 4'b1111) {r,g,b} = 24'hFF0000; // red
                      else                       {r,g,b} = 24'h000000;  // black
            default: {r,g,b} = 24'h111111;
       endcase
    
        if(top | left | right | bottom) {r,g,b} = 24'hffffff;
		  if(remainder_inrect)begin
				if(remainder){r,g,b} = 24'hFF0000;
				else  {r,g,b} = 24'h000000;
			end
        //else                            {r,g,b} = 24'h000000;
    end




endmodule


module chargenrom(input  logic [7:0] ch, 
                  input  logic [2:0] xoff, yoff,  
                  output logic       pixel); 

  logic [5:0] charrom[2047:0]; // character generator ROM 
  logic [7:0] line;            // a line read from the ROM 

  // initialize ROM with characters from text file 
  initial $readmemb("charrom.txt", charrom); 

  // index into ROM to find line of character 
  assign line = charrom[yoff+{ch-65, 3'b000}];  // subtract 65 because A 
                                                // is entry 0 
  // reverse order of bits 
  assign pixel = line[3'd7-xoff]; 
  
endmodule 

module rectgen(input  logic [9:0] x, y, left, top, right, bot, 
               output logic inrect);
			   
  assign inrect = (x >= left & x < right & y >= top & y < bot); 
  
endmodule 


