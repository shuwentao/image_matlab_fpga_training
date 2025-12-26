//PPC == 1 padding = 1
module rowPadding #(
    parameter MAX_COL_NUM = 720 ,
    parameter TUSER_WIDTH = 5 ,
    parameter TDEST_WIDTH = 2 ,
    parameter TDATA_WIDTH = 8
)(
input  logic                     clk             ,
input  logic                     rst             ,

input  logic [11:0]              v_num           ,
input  logic [11:0]              h_num           ,

input  logic [TUSER_WIDTH-1:0]   s_axis_tuser    ,
input  logic [TDEST_WIDTH-1:0]   s_axis_tdest    ,
input  logic                     s_axis_tvalid   ,
output logic                     s_axis_tready   ,
input  logic                     s_axis_tlast    ,
input  logic [TDATA_WIDTH-1:0]   s_axis_tdata    , 

output logic [TUSER_WIDTH-1:0]   m_axis_tuser    ,
output logic [TDEST_WIDTH-1:0]   m_axis_tdest    ,
output logic                     m_axis_tvalid   ,
input  logic                     m_axis_tready   ,
output logic                     m_axis_tlast    ,
output logic [3*TDATA_WIDTH-1:0] m_axis_tdata      
);

logic                       newFrame         ;

logic [11:0]                h_cnt            ;
logic [11:0]                v_cnt            ;

logic                       s_axis_tvalid_d1 ;
logic                       s_axis_tlast_d1  ;
logic [TDATA_WIDTH-1:0]     s_axis_tdata_d1  ;

logic                       s_axis_tvalid_d2 ;
logic                       s_axis_tlast_d2  ;
logic [TDATA_WIDTH-1:0]     s_axis_tdata_d2  ;

logic                       s_axis_tvalid_d3 ;
logic                       s_axis_tlast_d3  ;
logic [TDATA_WIDTH-1:0]     s_axis_tdata_d3  ;


logic [11:0]                ram_raddr        ;
logic [11:0]                ram_raddr_d1     ;
logic [11:0]                ram_raddr_d2     ;
logic [TDATA_WIDTH-1:0]     ram0_rdata       ;
logic                       ram0_we          ;

logic [TDATA_WIDTH-1:0]     ram1_rdata       ;
logic                       ram1_we          ;

logic [11:0]                ram_waddr        ;
logic [TDATA_WIDTH-1:0]     ram0_wdata       ;
logic [TDATA_WIDTH-1:0]     ram1_wdata       ;
logic [2*TDATA_WIDTH-1:0]   ram_wdata        ;
logic [2*TDATA_WIDTH-1:0]   ram_rdata        ;


logic                       xpm_s_axis_tvalid;
logic                       xpm_s_axis_tlast ;
logic [3*TDATA_WIDTH-1:0]   xpm_s_axis_tdata ;
logic                       xpm_s_axis_tuser ;

logic                       prog_full_axis   ;

assign newFrame = s_axis_tvalid && s_axis_tuser[0] ;

always_ff@(posedge clk) begin
    if(rst)
        s_axis_tvalid_d1 <= 1'b0 ;
    else if(v_cnt == v_num && h_cnt < h_num - 1)
        s_axis_tvalid_d1 <= ~ prog_full_axis ;
    else
        s_axis_tvalid_d1 <= s_axis_tvalid & s_axis_tready ;
end

always_ff@(posedge clk) begin
    s_axis_tdata_d1  <= s_axis_tdata ;
end

always_ff@(posedge clk) begin
    if(v_cnt == v_num && h_cnt == h_num - 2)
        s_axis_tlast_d1 <= 1'b1 ;
    else
        s_axis_tlast_d1 <= s_axis_tlast ; 
end

//pipeline stage1
always_ff@(posedge clk) begin
    if(rst)
        h_cnt <= 'b0 ;
    else if(newFrame)
        h_cnt <= 'b0 ;
    else if(s_axis_tvalid_d3 && s_axis_tlast_d3)
        h_cnt <= 'b0 ;
    else if(s_axis_tvalid_d1)
        h_cnt <= h_cnt + 1 ;
end

always_ff@(posedge clk) begin
    if(rst)
        v_cnt <= 'b0 ;
    else if(newFrame)
        v_cnt <= 'b0 ;
    else if(s_axis_tvalid_d3 && s_axis_tlast_d3)
        if(v_cnt == v_num)
            v_cnt <= 'b0 ;
        else
            v_cnt <= v_cnt + 1 ;
end

assign ram_raddr = h_cnt ;
assign ram_ce    = s_axis_tvalid_d1 ;


always_ff@(posedge clk) begin
    s_axis_tvalid_d2 <= s_axis_tvalid_d1 ;
    s_axis_tdata_d2  <= s_axis_tdata_d1  ;
    s_axis_tlast_d2  <= s_axis_tlast_d1  ;
    
    ram_raddr_d1     <= ram_raddr        ;
end

//pipeline stage2
always_ff@(posedge clk) begin
    s_axis_tvalid_d3 <= s_axis_tvalid_d2 ;
    s_axis_tdata_d3  <= s_axis_tdata_d2  ;
    s_axis_tlast_d3  <= s_axis_tlast_d2  ;

    ram_raddr_d2     <= ram_raddr_d1     ;
end

//pipeline stage3
assign ram0_rdata = ram_rdata[TDATA_WIDTH-1:0] ;
assign ram1_rdata = ram_rdata[2*TDATA_WIDTH-1:TDATA_WIDTH] ;

assign ram_waddr  = ram_raddr_d2 ;
assign ram0_wdata = ram1_rdata ;
assign ram1_wdata = s_axis_tdata_d3 ;
assign ram_wdata  = {ram1_wdata,ram0_wdata} ;
assign ram_we     = s_axis_tvalid_d3;

always_ff@(posedge clk) begin
    if(rst) 
        xpm_s_axis_tvalid <= 1'b0 ;
    else if(newFrame)
        xpm_s_axis_tvalid <= 1'b0 ;
    else if(v_cnt == 0)
        xpm_s_axis_tvalid <= 1'b0 ;
    else
        xpm_s_axis_tvalid <= s_axis_tvalid_d3 ;
end

always_ff@(posedge clk) begin
    xpm_s_axis_tlast  <= s_axis_tlast_d3 ;
end

always_ff@(posedge clk) begin
    if(v_cnt == 1)
        xpm_s_axis_tdata  <= {s_axis_tdata_d3,ram1_rdata,s_axis_tdata_d3} ;
    else if(v_cnt == v_num)
        xpm_s_axis_tdata  <= {ram0_rdata,ram1_rdata,ram0_rdata} ;
    else
        xpm_s_axis_tdata  <= {s_axis_tdata_d3,ram1_rdata,ram0_rdata} ;
end

always_ff@(posedge clk) begin
    if(s_axis_tvalid && s_axis_tready && s_axis_tuser[0])
        xpm_s_axis_tuser <= s_axis_tuser ;
    else if(xpm_s_axis_tvalid)
        xpm_s_axis_tuser <= s_axis_tuser ;
end

always_ff@(posedge clk) begin
    if(rst)
        s_axis_tready <= 1'b0 ;
    else if(s_axis_tvalid && s_axis_tready && s_axis_tlast)
        s_axis_tready <= 1'b0 ;
    else if(s_axis_tvalid_d1 && s_axis_tlast_d1)
        s_axis_tready <= 1'b0 ;
    else if(s_axis_tvalid_d2 && s_axis_tlast_d2)
        s_axis_tready <= 1'b0 ;
    else if(s_axis_tvalid_d3 && s_axis_tlast_d3)
        s_axis_tready <= 1'b0 ;
    else if(v_cnt == v_num)
        s_axis_tready <= 1'b0 ;
    else 
        s_axis_tready <= ~ prog_full_axis ;
end

bram_sdp_wfirst_1clk #(
  .RAM_WIDTH       ( 2*TDATA_WIDTH      ),                       
  .RAM_DEPTH       ( MAX_COL_NUM        ),                      
  .RAM_PERFORMANCE ( "HIGH_PERFORMANCE" ), 
  .RAM_INFER_TYPE  ( "block"            )             
) u_bram_sdp_wfirst_1clk(
  .clka     (   clk         ),
  .addra    (   ram_waddr   ),                    
  .dina     (   ram_wdata   ),                   
  .enb      (   1'b1        ),                 
  .wea      (   ram_we      ),                  
  .rstb     (   rst         ),               
  .addrb    (   ram_raddr   ),                     
  .regceb   (   1'b1        ),                  
  .doutb    (   ram_rdata   )                      
);

xpm_axi_stream_fifo#(
    .TDATA_WIDTH      ( 3*TDATA_WIDTH        ),
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
