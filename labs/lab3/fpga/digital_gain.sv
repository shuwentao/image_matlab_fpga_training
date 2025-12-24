module digital_gain #(
    parameter PPC = 1         ,
    parameter TUSER_WIDTH = 5 ,
    parameter TDEST_WIDTH = 2 ,
    parameter TDATA_WIDTH = 8
)(
input  logic                        clk             ,
input  logic                        rst             ,

input  logic [8:0]                  gain_factor     ,

input  logic [TUSER_WIDTH-1:0]      s_axis_tuser    ,
input  logic [TDEST_WIDTH-1:0]      s_axis_tdest    ,
input  logic                        s_axis_tvalid   ,
output logic                        s_axis_tready   ,
input  logic                        s_axis_tlast    ,
input  logic [PPC*TDATA_WIDTH-1:0]  s_axis_tdata    , 

output logic [TUSER_WIDTH-1:0]      m_axis_tuser    ,
output logic [TDEST_WIDTH-1:0]      m_axis_tdest    ,
output logic                        m_axis_tvalid   ,
input  logic                        m_axis_tready   ,
output logic                        m_axis_tlast    ,
output logic [PPC*TDATA_WIDTH-1:0]  m_axis_tdata      
);


logic [TUSER_WIDTH-1:0]                 s_axis_tuser_d1  ;
logic [TDEST_WIDTH-1:0]                 s_axis_tdest_d1  ;
logic                                   s_axis_tvalid_d1 ;
logic                                   s_axis_tlast_d1  ;
logic [PPC*TDATA_WIDTH-1:0]             s_axis_tdata_d1  ;

logic                                   prog_full_axis   ;

logic [1+1+TUSER_WIDTH+TDEST_WIDTH-1:0] data_in          ; 
logic [1+1+TUSER_WIDTH+TDEST_WIDTH-1:0] data_out         ; 

logic [7:0]                             A_ch0            ;
logic [8:0]                             B_ch0            ;
logic [7:0]                             P_ch0            ;

logic [7:0]                             A_ch1            ;
logic [8:0]                             B_ch1            ;
logic [7:0]                             P_ch1            ;

logic [TUSER_WIDTH-1:0]                 xpm_s_axis_tuser ;
logic [TDEST_WIDTH-1:0]                 xpm_s_axis_tdest ;
logic                                   xpm_s_axis_tvalid;
logic                                   xpm_s_axis_tlast ;
logic [PPC*TDATA_WIDTH-1:0]             xpm_s_axis_tdata ;

always_ff@(posedge clk) begin
    s_axis_tvalid_d1 <= s_axis_tvalid && s_axis_tready ;
    s_axis_tdata_d1  <= s_axis_tdata ;
    s_axis_tlast_d1  <= s_axis_tlast ;
    s_axis_tuser_d1  <= s_axis_tuser ;
    s_axis_tdest_d1  <= s_axis_tdest ;
end


assign A_ch0 = s_axis_tdata_d1[TDATA_WIDTH-1:0] ;
assign B_ch0 = gain_factor     ;

multi_dsp u_multi_dsp_ch0(
    .clk        (   clk     ),
    .rst        (   rst     ),
    .A          (   A_ch0   ),
    .B          (   B_ch0   ),
    .P          (   P_ch0   )
);


generate
    begin
        if(PPC == 2) begin
            assign A_ch1 = s_axis_tdata_d1[PPC*TDATA_WIDTH-1:TDATA_WIDTH] ;
            assign B_ch1 = gain_factor     ;
            
            multi_dsp u_multi_dsp_ch1(
                .clk        (   clk     ),
                .rst        (   rst     ),
                .A          (   A_ch1   ),
                .B          (   B_ch1   ),
                .P          (   P_ch1   )
            );
            
        end
    end
endgenerate


assign xpm_s_axis_tdata  = {P_ch1,P_ch0} ;

//{1,1,TUSER_WIDTH,TDEST_WIDTH}
//1,1,5,2
assign data_in = {s_axis_tvalid_d1,s_axis_tlast_d1,s_axis_tuser_d1,s_axis_tdest_d1};
shift_register #(
    .DATA_WIDTH ( 1+1+TUSER_WIDTH+TDEST_WIDTH ),
    .LATENCY    ( 3                           )
) u_shift_register(
    .clk        (   clk         ),
    .rst        (   rst         ),
    .data_in    (   data_in     ),
    .data_out   (   data_out    ) 
);
assign xpm_s_axis_tdest  = data_out[TDEST_WIDTH-1:0];                       //[1:0]
assign xpm_s_axis_tuser  = data_out[TUSER_WIDTH+TDEST_WIDTH-1:TDEST_WIDTH]; //[6:2]
assign xpm_s_axis_tlast  = data_out[TUSER_WIDTH+TDEST_WIDTH] ; //7
assign xpm_s_axis_tvalid = data_out[TUSER_WIDTH+TDEST_WIDTH+1];//8

always_ff@(posedge clk) begin
    if(rst)
        s_axis_tready <= 1'b0 ;
    else 
        s_axis_tready <= ~ prog_full_axis ;
end

xpm_axi_stream_fifo#(
    .TDATA_WIDTH      ( PPC*TDATA_WIDTH      ),
    .PROG_FULL_THRESH ( 10                   ),
    .FIFO_DEPTH       ( 16                   ),
    .CLOCKING_MODE    ( "common_clock"       ),
    .FIFO_MEMORY_TYPE ( "auto"               ) 
) u_xpm_axi_stream_fifo(
    .s_aclk             (   clk                 ),
    .s_aresetn          (   ~rst                ),
    .m_aclk             (   clk                 ),
    .s_axis_tvalid      (   xpm_s_axis_tvalid   ),
    .s_axis_tdata       (   xpm_s_axis_tdata    ),
    .s_axis_tlast       (   xpm_s_axis_tlast    ),
    .s_axis_tready      (                       ),
    .s_axis_tuser       (   xpm_s_axis_tuser    ),
    .s_axis_tdest       (   xpm_s_axis_tdest    ),
    .m_axis_tvalid      (   m_axis_tvalid       ),
    .m_axis_tready      (   m_axis_tready       ),
    .m_axis_tdata       (   m_axis_tdata        ),
    .m_axis_tlast       (   m_axis_tlast        ),
    .m_axis_tuser       (   m_axis_tuser        ),
    .m_axis_tdest       (   m_axis_tdest        ),
    .prog_full_axis     (   prog_full_axis      ) 
);

endmodule
