//////////////////////////////////////////////////////////////////////////////////
// Company:  Y&L technology
// Engineer: xiansong
// 
// Create Date:     
// Design Name:     
// Module Name:     guided_filter
// Project Name:    
// Target Devices:  ZU7EV
// Tool versions:   Vivado2019.2
// Description: 
//
// Dependencies: 
//////////////////////////////////////////////////////////////////////////////////
module shift_register #(
    parameter                                           DATA_WIDTH = 10,
    parameter                                           LATENCY = 10
    )(
    input                                               clk ,
    input                                               rst ,
    input   wire    [DATA_WIDTH - 1 : 0]                data_in ,
    output  wire    [DATA_WIDTH - 1 : 0]                data_out    
    );

//==============================================================================
// parameter
//==============================================================================


//==============================================================================
// wire reg
//==============================================================================
    reg             [DATA_WIDTH - 1 : 0]                data_in_dl [1:LATENCY];
    genvar                                              i   ;
//==============================================================================
// 
//==============================================================================
always@(posedge clk)begin
    if(rst)
        data_in_dl[1] <= {DATA_WIDTH{1'b0}};
    else
        data_in_dl[1] <= data_in;
end

generate
    for(i = 2 ; i <= LATENCY ; i = i + 1)begin
        always@(posedge clk)begin
            if(rst)
                data_in_dl[i] <= {DATA_WIDTH{1'b0}};
            else
                data_in_dl[i] <= data_in_dl[i-1];
        end
    end
endgenerate

assign data_out = data_in_dl[LATENCY];

endmodule