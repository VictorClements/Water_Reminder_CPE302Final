
module audio(input  logic reminder, clk, 
             output logic toBuzzer);

assign toBuzzer = reminder ? clk : 1'b0;

endmodule

module Clock760Hz(input  logic clk, reset,
                  output logic slowClk);
  logic [15:0] count;

  always_ff@(posedge clk, posedge reset)
    if(reset)   count <= 16'b0;
    else        count <= count + 1;

  assign slowClk = count[15];
endmodule

module letterGen(input  logic [9:0] x, y,   //current x and y position
                 input  logic [9:0] left, top, right, bot,  // for checking if the current x and y position is within the rectangle bounds
                 input  logic [4:0] letterSelect,   // 0, 1, ... , 25
                 output logic       pixel); //bit for saying if pixel is 0 or 1
  logic        inrect;  //bit for saying if current pixel is in the rectangle
  logic [14:0] charrom [519:0];  //depth of ROM is 520, and length of each line is 15 bits (26 letters means 20 lines for each letter)
  logic [14:0] line;            //individual line of character rom

  assign inrect = (x >= left & x < right & y >= top & y < bot); //same as rectgen, checks

  initial $readmemb("characterROM.txt", charrom);

  assign line = charrom[letterSelect*20 + (y-top)];

  assign pixel = inrect & line[x-left];

endmodule
