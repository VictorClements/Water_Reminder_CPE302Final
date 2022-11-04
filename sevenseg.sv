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