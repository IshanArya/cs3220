 `include "VX_define.vh" 

module project3_frame(
  input        CLOCK_50,
  input        RESET_N,
  input  [3:0] KEY,
  output [6:0] HEX0,
  output [6:0] HEX1,
  output [9:0] LEDR
);

  
 wire clk;
 wire reset; 
 wire locked; 
 
  
  //*** PLL IP module is called here. ***//
clk_wiz_0 my_clock
 (
  .clk_out1(clk),
  .reset(!RESET_N),
  .locked(locked),
  .clk_in1(CLOCK_50)
 );

  assign reset = !locked;
  
  /* wires to connect between pipeline stages */ 
  
  wire [`FE_latch_WIDTH-1:0] FE_latch_out; 
  wire [`DE_latch_WIDTH-1:0] DE_latch_out; 
  wire [`AGEX_latch_WIDTH-1:0] AGEX_latch_out; 
  wire [`MEM_latch_WIDTH-1:0] MEM_latch_out;

  wire [`from_DE_to_FE_WIDTH-1:0] from_DE_to_FE;
  wire [`from_AGEX_to_FE_WIDTH-1:0] from_AGEX_to_FE;
  wire [`from_MEM_to_FE_WIDTH-1:0] from_MEM_to_FE;
  wire [`from_WB_to_FE_WIDTH-1:0] from_WB_to_FE;

  wire [`from_AGEX_to_DE_WIDTH-1:0] from_AGEX_to_DE;
  wire [`from_MEM_to_DE_WIDTH-1:0] from_MEM_to_DE;
  wire [`from_WB_to_DE_WIDTH-1:0] from_WB_to_DE;

  wire [`from_MEM_to_AGEX_WIDTH-1:0] from_MEM_to_AGEX;
  wire [`from_WB_to_AGEX_WIDTH-1:0] from_WB_to_AGEX;

  wire [`from_WB_to_MEM_WIDTH-1:0] from_WB_to_MEM;
  
  wire [`from_AGEX_stall_WIDTH-1:0] from_AGEX_stall;
  wire [`from_MEM_stall_WIDTH-1:0] from_MEM_stall;
  
  wire data_hazard;
  wire control_hazard;





FE_STAGE my_FE_stage(
    .clk(clk), 
    .reset(reset), 
    .from_DE_to_FE(from_DE_to_FE),
    .from_AGEX_to_FE(from_AGEX_to_FE),
    .from_MEM_to_FE(from_MEM_to_FE),
    .from_WB_to_FE(from_WB_to_FE),
    .FE_latch_out(FE_latch_out),
    .data_hazard(data_hazard),
    .control_hazard(control_hazard)
);
                     
DE_STAGE my_DE_stage(
  .clk(clk),
  .reset(reset),
  .from_FE_latch(FE_latch_out),
  .from_AGEX_to_DE(from_AGEX_to_DE),  
  .from_MEM_to_DE(from_MEM_to_DE),     
  .from_WB_to_DE(from_WB_to_DE), 
  .from_DE_to_FE(from_DE_to_FE),
  .from_AGEX_stall(from_AGEX_stall),
  .from_MEM_stall(from_MEM_stall),
  .DE_latch_out(DE_latch_out),
  .data_hazard(data_hazard),
  .control_hazard(control_hazard)
);

AGEX_STAGE my_AGEX_stage(
  .clk(clk),
  .reset(reset),
  .from_MEM_to_AGEX(from_MEM_to_AGEX),    
  .from_WB_to_AGEX(from_WB_to_AGEX),
  .from_DE_latch(DE_latch_out),
  .AGEX_latch_out(AGEX_latch_out),
  .from_AGEX_to_FE(from_AGEX_to_FE),
  .from_AGEX_to_DE(from_AGEX_to_DE),
  .from_AGEX_stall(from_AGEX_stall)
);

MEM_STAGE my_MEM_stage(
  .clk(clk),
  .reset(reset),
  .KEY(KEY),
  .from_WB_to_MEM(from_WB_to_MEM),  
  .from_AGEX_latch(AGEX_latch_out), 
  .MEM_latch_out(MEM_latch_out),
  .from_MEM_to_FE(from_MEM_to_FE),
  .from_MEM_to_DE(from_MEM_to_DE),
  .from_MEM_to_AGEX(from_MEM_to_AGEX),
  .from_MEM_stall(from_MEM_stall)
);     


       
WB_STAGE my_WB_stage(
  .clk(clk),
  .reset(reset),  
  .from_MEM_latch(MEM_latch_out),
  .from_WB_to_FE(from_WB_to_FE),
  .from_WB_to_DE(from_WB_to_DE),  
  .from_WB_to_AGEX(from_WB_to_AGEX),
  .from_WB_to_MEM(from_WB_to_MEM),
  .HEX0(HEX0),
  .HEX1(HEX1), 
  .LEDR(LEDR) 
);

endmodule









