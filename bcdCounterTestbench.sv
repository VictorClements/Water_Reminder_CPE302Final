module bcdCounterTestbench();
  //inputs
  logic        clk, reset;
  logic        en, cin, hourIs2XIn;
  
  //internal signals
  logic [3:0]  cnt;
  
  //outputs
  logic        cout;
  logic        hourIs2XOut;

  assign en = 1'b1;
  assign hourIs2XIn = 1'b0;

  // instantiate device under test
  bcdCounter #(2) dut(clk, reset, en, cin, 
    hourIs2XIn, cnt, cout, hourIs2XOut);

  // generate clock
  always 
    begin
      clk = 1; #2; clk = 0; #2;
    end

  // at start of test, load vectors
  // and pulse reset
  initial
    begin
      cin = 1'b1; reset = 1; #15; reset = 0;
      #20; cin = 1'b0; #12; cin = 1'b1;
    end
endmodule