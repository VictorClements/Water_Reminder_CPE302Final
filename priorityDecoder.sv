//this decoder will be used for reading in the values from the GPIO
//which will come from the ADC (Analog to Digital Converter)
//it will turn in those values into 4 bit numbers representing the 
//current water level.
//0000 = 0 inches of water, and 1111 = 12 inches of water
//at the moment this assumes 4 bits of precision (16 bits in)

//The case statement may look a little weird but remember:
//the water level sensor resistance is inversely proportional
//to the height of the water, so if the water is very high (say 12 inches)
//then the resistance will be low (around 400 Ohms)
//which means that the resulting voltage from running the current through
//our resistor will be pretty low (around 1V if the current source is 2.5mA)
//which is the lowest input voltage, so the comparators will all read 0's
//and vice versa, a very low water level will mean the comparators will all read 1's
//so that is the explanation behind the below priority decoder...

module priorityDecoder(input  logic [15:0] in,
                       output logic [3:0]  out);
  always_comb
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