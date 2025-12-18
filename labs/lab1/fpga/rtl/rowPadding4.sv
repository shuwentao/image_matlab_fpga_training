//ppc=2 pad=2
module rowPadding #(
    parameter TUSER_WIDTH = 5 ,
    parameter TDEST_WIDTH = 2 ,
    parameter TDATA_WIDTH = 8
)(
input  logic                     clk             ,
input  logic                     rst             ,

input  logic [TUSER_WIDTH-1:0]   s_axis_tuser    ,
input  logic [TDEST_WIDTH-1:0]   s_axis_tdest    ,
input  logic                     s_axis_tvalid   ,
output logic                     s_axis_tready   ,
input  logic                     s_axis_tlast    ,
input  logic [2*TDATA_WIDTH-1:0] s_axis_tdata    , 

output logic [TUSER_WIDTH-1:0]   m_axis_tuser    ,
output logic [TDEST_WIDTH-1:0]   m_axis_tdest    ,
output logic                     m_axis_tvalid   ,
input  logic                     m_axis_tready   ,
output logic                     m_axis_tlast    ,
output logic [2*TDATA_WIDTH-1:0] m_axis_tdata      
);

logic [TDATA_WIDTH-1:0]     PAD_reg0 = 'b0    ;
logic [TDATA_WIDTH-1:0]     PAD_reg1 = 'b0    ;
logic [TDATA_WIDTH-1:0]     PAD_reg2 = 'b0    ;
logic [TDATA_WIDTH-1:0]     PAD_reg3 = 'b0    ;
logic [TDATA_WIDTH-1:0]     PAD_reg4 = 'b0    ;
logic [TDATA_WIDTH-1:0]     PAD_reg5 = 'b0    ;

logic                       prog_full_axis    ;
logic                       xpm_s_axis_tvalid ;
logic [TUSER_WIDTH-1:0]     xpm_s_axis_tuser  ;
logic [2*TDATA_WIDTH-1:0]   xpm_s_axis_tdata  ;
logic                       xpm_s_axis_tlast  ;

logic                       s_axis_tvalid_d1  ;
logic [2*TDATA_WIDTH-1:0]   s_axis_tdata_d1   ;

logic                       s_axis_tlast_d1   ;

enum {
    S_IDLE   = 'b0_0000_0001,
    S_INIT0  = 'b0_0000_0010,
    S_INIT1  = 'b0_0000_0100,
    S_RUN    = 'b0_0000_1000,
    S_DRAIN0 = 'b0_0001_0000,
    S_DRAIN1 = 'b0_0010_0000,
    S_DRAIN2 = 'b0_0100_0000,
    S_DRAIN3 = 'b0_1000_0000,
    S_DONE   = 'b1_0000_0000 
} cstate,nstate ;

always_ff@(posedge clk) begin
    if(rst)
        cstate <= S_IDLE ;
    else
        cstate <= nstate ;
end

always_comb begin
    case(cstate)
        S_IDLE  : nstate = S_INIT0 ; 
        S_INIT0 : nstate = s_axis_tvalid_d1 ? S_INIT1 : S_INIT0 ;
        S_INIT1 : nstate = s_axis_tvalid_d1 ? S_RUN : S_INIT1 ;
        S_RUN   : nstate = s_axis_tvalid_d1 && s_axis_tlast_d1 ? S_DRAIN0 : S_RUN   ;
        S_DRAIN0: nstate = S_DRAIN1;
        S_DRAIN1: nstate = S_DRAIN2;
        S_DRAIN2: nstate = S_DRAIN3;
        S_DRAIN3: nstate = S_DONE  ;
        S_DONE  : nstate = S_IDLE  ;
        default : nstate = S_IDLE  ;
    endcase
end

always_ff@(posedge clk) begin
    s_axis_tvalid_d1 <= s_axis_tvalid & s_axis_tready ;
    s_axis_tdata_d1  <= s_axis_tdata ;
    s_axis_tlast_d1  <= s_axis_tlast ;
end

always_ff@(posedge clk) begin
     if(s_axis_tvalid_d1)
        PAD_reg0 <= s_axis_tdata_d1[2*TDATA_WIDTH-1:TDATA_WIDTH] ;
end

always_ff@(posedge clk) begin
    if(s_axis_tvalid_d1) 
        PAD_reg1 <= s_axis_tdata_d1[TDATA_WIDTH-1:0] ;
    //else if((cstate == S_RUN) && s_axis_tvalid_d1) 
    //    PAD_reg1 <= s_axis_tdata_d1[TDATA_WIDTH-1:0] ;
end

always_ff@(posedge clk) begin
    if(cstate == S_INIT0)
        PAD_reg2 <= s_axis_tdata_d1[2*TDATA_WIDTH-1:TDATA_WIDTH] ;
    else if((cstate == S_RUN) && s_axis_tvalid_d1) 
        PAD_reg2 <= PAD_reg0 ;
    else if(cstate == S_DRAIN0)
        PAD_reg2 <= PAD_reg0 ;
    else if(cstate == S_DRAIN1)
        PAD_reg2 <= PAD_reg4 ;
end

always_ff@(posedge clk) begin
    if(cstate == S_INIT0)
        PAD_reg3 <= s_axis_tdata_d1[TDATA_WIDTH-1:0] ;
    else if((cstate == S_RUN) && s_axis_tvalid_d1) 
        PAD_reg3 <= PAD_reg1 ;
    else if(cstate == S_DRAIN0)
        PAD_reg3 <= PAD_reg1 ;
//    else if(cstate == S_DRAIN1)//hold
end

always_ff@(posedge clk) begin
    if(cstate == S_INIT1)
        PAD_reg4 <= PAD_reg2 ;
    else if((cstate == S_RUN) && s_axis_tvalid_d1) 
        PAD_reg4 <= PAD_reg2 ;
    else if(cstate == S_DRAIN0 || cstate == S_DRAIN1 || cstate == S_DRAIN2 || cstate == S_DRAIN3)
        PAD_reg4 <= PAD_reg2 ;
end

always_ff@(posedge clk) begin
    if(cstate == S_INIT1)
        PAD_reg5 <= s_axis_tdata_d1[TDATA_WIDTH-1:0];
    else if((cstate == S_RUN) && s_axis_tvalid_d1) 
        PAD_reg5 <= PAD_reg3 ;
    else if(cstate == S_DRAIN0 || cstate == S_DRAIN1 || cstate == S_DRAIN2 || cstate == S_DRAIN3)
        PAD_reg5 <= PAD_reg3 ;
end


always_ff@(posedge clk) begin
    if(rst)
        xpm_s_axis_tvalid <= 1'b0 ;
    else if(nstate == S_RUN)
        xpm_s_axis_tvalid <= s_axis_tvalid_d1 ;
    else if(nstate == S_DRAIN0)
        xpm_s_axis_tvalid <= 1'b1 ;
    else if(cstate == S_DRAIN3)
        xpm_s_axis_tvalid <= 1'b0 ;
end

always_ff@(posedge clk) begin
    if(rst)
        s_axis_tready <= 1'b0 ;
    else if(s_axis_tvalid && s_axis_tready && s_axis_tlast)
        s_axis_tready <= 1'b0 ;
    else if(nstate == S_INIT0) 
        s_axis_tready <= 1'b1 ;
    else if(nstate == S_INIT1) 
        s_axis_tready <= 1'b1 ;
    else if(nstate == S_RUN)
        s_axis_tready <= ~ prog_full_axis ;
end

always_ff@(posedge clk) begin
    if(s_axis_tvalid && s_axis_tready && s_axis_tuser[0])
        xpm_s_axis_tuser <= s_axis_tuser ;
    else if(xpm_s_axis_tvalid)
        xpm_s_axis_tuser <= s_axis_tuser ;
end

assign xpm_s_axis_tdata = {PAD_reg4,PAD_reg5} ;

always_ff@(posedge clk) begin
    if(rst)
        xpm_s_axis_tlast <= 1'b0 ;
    else if(cstate == S_DRAIN2)
        xpm_s_axis_tlast <= 1'b1 ;
    else
        xpm_s_axis_tlast <= 1'b0 ;
end


xpm_axi_stream_fifo#(
    .TDATA_WIDTH      ( 2*TDATA_WIDTH        ),
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
    .m_axis_tvalid      (   m_axis_tvalid       ),
    .m_axis_tready      (   m_axis_tready       ),
    .m_axis_tdata       (   m_axis_tdata        ),
    .m_axis_tlast       (   m_axis_tlast        ),
    .m_axis_tuser       (   m_axis_tuser        ),
    .prog_full_axis     (   prog_full_axis      ) 
);

endmodule
