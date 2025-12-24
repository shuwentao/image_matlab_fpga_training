module multi_dsp (
input  logic                clk  ,
input  logic                rst  ,
input  logic [7:0]          A    ,
input  logic [8:0]          B    ,
output logic [7:0]          P 
);


logic [16:0] P_mult ;
logic [8:0]  P_round;

//A_in      8  bit
//B_in      9  bit
//P_mult    17 bit
//P_round   9  bit
//P_out     8  bit
always_ff@(posedge clk) begin
    P_mult <= A * B ;
end

//round 
always_ff@(posedge clk) begin
    P_round <= P_mult[16:8] + P_mult[7] ;
end

//saturation truncation
always_ff@(posedge clk) begin
    if(P_round > 255)
        P <= 255 ;
    else
        P <= P_round[7:0] ;
end

endmodule
