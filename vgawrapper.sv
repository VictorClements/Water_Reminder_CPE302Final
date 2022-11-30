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
