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
