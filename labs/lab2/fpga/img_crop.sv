module img_crop #(
    parameter PPC	  = 1 ,	
    parameter TUSER_WIDTH = 5 ,
    parameter TDEST_WIDTH = 2 ,
    parameter TDATA_WIDTH = 8
)(
input  logic                        clk             ,
input  logic                        rst             ,

input  logic [11:0]                 crop_start_x    ,
input  logic [11:0]                 crop_start_y    ,
input  logic [11:0]                 crop_width      ,
input  logic [11:0]                 crop_height     ,

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


logic                       s_axis_tvalid_d1;
logic [PPC*TDATA_WIDTH-1:0] s_axis_tdata_d1;
logic                       s_axis_tlast_d1;

logic                       xpm_s_axis_tvalid;
logic [TUSER_WIDTH-1:0]     xpm_s_axis_tuser;
logic [PPC*TDATA_WIDTH-1:0] xpm_s_axis_tdata;
logic                       xpm_s_axis_tlast;

logic [11:0]                x_cnt;
logic [11:0]                y_cnt;

logic                       newFrame;
logic                       prog_full_axis; 

logic [11:0]                crop_start_x_d1;
logic [11:0]                crop_start_y_d1; 
logic [11:0]                crop_end_x_d1;
logic [11:0]                crop_end_x_last;
logic [11:0]                crop_end_y_d1;


assign newFrame = s_axis_tvalid && s_axis_tuser[0];

generate 
    begin
    	if(PPC == 2) begin
            always_ff@(posedge clk) begin
                crop_start_x_d1 <= crop_start_x[11:1];
                crop_start_y_d1 <= crop_start_y - 1 ; 
            
                crop_end_x_d1   <= crop_start_x[11:1] + crop_width[11:1];
                crop_end_x_last <= crop_start_x[11:1] + crop_width[11:1] - 1;
                crop_end_y_d1   <= crop_start_y + crop_height - 1;
            end
	    end
	    else if(PPC == 1) begin
	        always_ff@(posedge clk) begin
            crop_start_x_d1 <= crop_start_x - 1 ;
            crop_start_y_d1 <= crop_start_y - 1 ; 

            crop_end_x_d1   <= crop_start_x + crop_width - 1;
            crop_end_x_last <= crop_start_x + crop_width - 2;
            crop_end_y_d1   <= crop_start_y + crop_height - 1;
            end
	    end
    end
endgenerate


always_ff@(posedge clk) begin
    s_axis_tvalid_d1 <= s_axis_tvalid & s_axis_tready ;
    s_axis_tdata_d1  <= s_axis_tdata ;
    s_axis_tlast_d1  <= s_axis_tlast ;
end

always_ff@(posedge clk) begin
    if(rst)
        xpm_s_axis_tvalid <= 1'b0 ;
    else if(x_cnt >= crop_start_x_d1 && x_cnt < crop_end_x_d1 && y_cnt >= crop_start_y_d1 && y_cnt < crop_end_y_d1)
        xpm_s_axis_tvalid <= s_axis_tvalid_d1 ;
    else
        xpm_s_axis_tvalid <= 1'b0 ;
        
end

always_ff@(posedge clk) begin
    xpm_s_axis_tdata  <= s_axis_tdata_d1  ;
    if(s_axis_tvalid_d1)
        xpm_s_axis_tlast  <= (x_cnt == crop_end_x_last);
end

always_ff@(posedge clk) begin
    if(s_axis_tvalid && s_axis_tready && s_axis_tuser[0])
        xpm_s_axis_tuser <= s_axis_tuser ;
    else if(xpm_s_axis_tvalid)
        xpm_s_axis_tuser <= s_axis_tuser ;
end

always_ff@(posedge clk) begin
    if(rst)
        x_cnt <= 'b0 ;
    else if(newFrame) 
        x_cnt <= 'b0 ;
    else if(s_axis_tvalid_d1 && s_axis_tlast_d1)
        x_cnt <= 'b0 ;
    else if(s_axis_tvalid_d1)
        x_cnt <= x_cnt + 1;
end

always_ff@(posedge clk) begin
    if(rst)
        y_cnt <= 'b0 ;
    else if(newFrame)
        y_cnt <= 'b0 ;
    else if(s_axis_tvalid_d1 && s_axis_tlast_d1)
        y_cnt <= y_cnt + 1;
end

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
    .m_axis_tvalid      (   m_axis_tvalid       ),
    .m_axis_tready      (   m_axis_tready       ),
    .m_axis_tdata       (   m_axis_tdata        ),
    .m_axis_tlast       (   m_axis_tlast        ),
    .m_axis_tuser       (   m_axis_tuser        ),
    .prog_full_axis     (   prog_full_axis      ) 
);



endmodule
