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

// here is the parameterized version of the above code:
/*
module letterGen #(parameter DEPTH = 780,  WIDTH = 15,  SPACING = 20, BITMAP_FILE = "characterROM.txt", SCREENHEIGHT, SCREENWIDTH,
                             SELECTWIDTH = $clog2(DEPTH/SPACING), XBITS = $clog2(SCREENWIDTH), YBITS = $clog2(SCREENHEIGHT))
                  (input  logic [XBITS-1:0]       x,            // current x cordinate
                   input  logic [XBITS-1:0]       left, right,  // x-boundaries of the bitmap
                   input  logic [YBITS-1:0]       y,            // current y cordinate
                   input  logic [YBITS-1:0]       top, bottom,  // y-boundaries of the bitmap
                   input  logic [SELECTWIDTH-1:0] letterSelect, // selects which bitmap from the file to load
                   output logic                   pixel);       // whether the pixel should be on (change to tri if the last comment is used)

  logic             inrect;              // signal to see if within bitmap
  logic [WIDTH-1:0] charrom [DEPTH-1:0]; // entire character rom
  logic [WIDTH-1:0] line;                // individual line of character rom
  
  initial $readmemb(BITMAP_FILE, charrom); //reads in bitmaps
  assign inrect = (x >= left & x < right & y >= top & y < bottom); //checks if within bounds
  assign line = charrom[letterSelect*SPACING + (y-top)]; // finds the line we are on currently
  assign pixel = inrect & line[(WIDTH - 1) - (x - left)]; // finds the pixel we are on within the line we are on
//assign pixel = inrect ? line[(WIDTH - 1) - (x - left)] : 1'bz; // should work assuming another module takes care of outputting to this pixel
endmodule
*/
