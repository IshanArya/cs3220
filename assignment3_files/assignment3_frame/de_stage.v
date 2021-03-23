 `include "VX_define.vh" 


module DE_STAGE(
  input clk,
  input reset,
  input [`FE_latch_WIDTH-1:0] from_FE_latch,
  input [`from_AGEX_to_DE_WIDTH-1:0] from_AGEX_to_DE,  
  input [`from_MEM_to_DE_WIDTH-1:0] from_MEM_to_DE,     
  input [`from_WB_to_DE_WIDTH-1:0] from_WB_to_DE,  
  input [`from_AGEX_stall_WIDTH-1:0] from_AGEX_stall,
  input [`from_MEM_stall_WIDTH-1:0] from_MEM_stall,
  output [`from_DE_to_FE_WIDTH-1:0] from_DE_to_FE,   
  output[`DE_latch_WIDTH-1:0] DE_latch_out,
  output data_hazard,
  output control_hazard
);

/* pipeline latch*/ 
 reg [`DE_latch_WIDTH-1:0] DE_latch; 

  /* register file */ 
  reg [`DBITS-1:0] regs [`REGWORDS-1:0];
  
 /* decode signals */
  
  wire [`INSTBITS-1:0] inst_DE; 
  wire [`DBITS-1:0] PC_DE;
  wire [`DBITS-1:0] pcplus_DE; 
  wire [`OP1BITS-1:0] op1_DE;
  wire [`OP2BITS-1:0] op2_DE;
  wire [`IMMBITS-1:0] imm_DE;
  wire [`REGNOBITS-1:0] rd_DE;
  wire [`REGNOBITS-1:0] rs_DE;
  wire [`REGNOBITS-1:0] rt_DE;
  wire [`REGNOBITS-1:0] wregno_AGEX;
  wire [`REGNOBITS-1:0] wregno_MEM;
  wire [`REGNOBITS-1:0] wregno_WB;
  wire [`REGNOBITS-1:0] wregno_DE;
  
  wire signed [`DBITS-1:0] regval1_DE;
  wire signed [`DBITS-1:0] regval2_DE;
  wire signed [`DBITS-1:0] sxt_imm_DE;
  wire[`DBITS-1:0] regval_WB;


  wire is_br_DE;
  wire is_alur_DE;
  wire is_alui_DE;
  wire is_jmp_DE;
  wire is_lw_DE;
  wire is_sw_DE;
  wire rd_rt_DE;
  wire rd_mem_DE;
  wire wr_mem_DE;
  wire wr_reg_DE;
  wire wr_reg_AGEX;
  wire wr_reg_MEM;
  wire wr_reg_WB;
  
  
  
  wire dh_AGEX;
  wire dh_MEM;
  wire data_hazard_wire;
  wire control_hazard_wire;
  
  
  wire[`DE_latch_WIDTH-1:0] DE_latch_contents; 
  wire[`BUS_CANARY_WIDTH-1:0] bus_canary_DE; 
 // **TODO: Complete the rest of the pipeline 

// extracting a part of opcode 
  assign op1_DE = inst_DE[31:26];  // example code 
  assign op2_DE = inst_DE[25:18];
  assign imm_DE = inst_DE[23:8];
  assign rd_DE  = inst_DE[11:8];
  assign rs_DE  = inst_DE[7:4];
  assign rt_DE  = inst_DE[3:0];
  
  // Sign extension example 
  SXT mysxt (.IN(imm_DE), .OUT(sxt_imm_DE));
  
  assign regval1_DE = regs[rs_DE];
  assign regval2_DE = regs[rt_DE];
  
  assign wregno_DE = is_alur_DE ? rd_DE : rt_DE;
  
  assign is_br_DE = op1_DE[5:2] == `OP1_BR;
  assign is_alur_DE = op1_DE == `OP1_ALUR;
  assign is_alui_DE = op1_DE[5:3] == `OP1_ALUI;
  assign is_jmp_DE = op1_DE == `OP1_JAL;
  assign is_lw_DE = op1_DE == `OP1_LW;
  assign is_sw_DE = op1_DE == `OP1_SW;
  assign rd_rt_DE = is_alur_DE || is_sw_DE || is_br_DE;
  assign rd_mem_DE = op1_DE == `OP1_LW;
  assign wr_mem_DE = op1_DE == `OP1_SW;
  assign wr_reg_DE = (bus_canary_DE != 0) && (is_alur_DE || is_alui_DE || is_jmp_DE || is_lw_DE);
  assign {wregno_AGEX, wr_reg_AGEX} = from_AGEX_stall;
  assign {wregno_MEM, wr_reg_MEM} = from_MEM_stall;
  assign {wregno_WB, regval_WB, wr_reg_WB} = from_WB_to_DE;
  
  assign dh_AGEX = wr_reg_AGEX && (rs_DE == wregno_AGEX || (rd_rt_DE && rt_DE == wregno_AGEX));
  assign dh_MEM = wr_reg_MEM   && (rs_DE == wregno_MEM  || (rd_rt_DE && rt_DE == wregno_MEM));
  
  assign data_hazard_wire = dh_AGEX || dh_MEM;
  assign control_hazard_wire = is_br_DE || is_jmp_DE;
  
  assign data_hazard = data_hazard_wire;
  assign control_hazard = control_hazard_wire;
  
  

 // complete the rest of instruction decoding 

// assign wire to send the contents of DE latch to other pipeline stages  
  assign DE_latch_out = DE_latch;
  

  


// decoding the contents of FE latch out. the order should be matched with the fe_stage.v 
  assign {
            inst_DE,
            PC_DE, 
            pcplus_DE,
            bus_canary_DE 
            }  = from_FE_latch;  // based on the contents of the latch, you can decode the content 



    assign DE_latch_contents = {
                                  inst_DE,
                                  PC_DE,
                                  pcplus_DE,
                                  op1_DE,
                                  op2_DE,
                                  regval1_DE,
                                  regval2_DE,
                                  sxt_imm_DE,
                                  is_br_DE,
                                  is_jmp_DE,
                                  rd_mem_DE,
                                  wr_mem_DE,
                                  wr_reg_DE,
                                  wregno_DE,

                                  // more signals might need
                                   bus_canary_DE 
                                  }; 
    
  always @ (negedge clk or posedge reset) begin
    if(reset) begin
	  	regs[0] <= {`DBITS{1'b0}};
	  	regs[1] <= {`DBITS{1'b0}};
	   	regs[2] <= {`DBITS{1'b0}};
		  regs[3] <= {`DBITS{1'b0}};
	  	regs[4] <= {`DBITS{1'b0}};
		  regs[5] <= {`DBITS{1'b0}};
		  regs[6] <= {`DBITS{1'b0}};
		  regs[7] <= {`DBITS{1'b0}};
		  regs[8] <= {`DBITS{1'b0}};
		  regs[9] <= {`DBITS{1'b0}};
		  regs[10] <= {`DBITS{1'b0}};
		  regs[11] <= {`DBITS{1'b0}};
		  regs[12] <= {`DBITS{1'b0}};
		  regs[13] <= {`DBITS{1'b0}};
		  regs[14] <= {`DBITS{1'b0}};
		  regs[15] <= {`DBITS{1'b0}};
	 end 
   // need to complete register write 
     else if(wr_reg_WB)
        regs[wregno_WB] <= regval_WB;
  end

  always @ (posedge clk or posedge reset) begin
    if(reset) begin
      DE_latch <= {`DE_latch_WIDTH{1'b0}};
      // might need more code 
      end
     else if(data_hazard_wire)
        DE_latch <= {`DE_latch_WIDTH{1'b0}};
     else 
     // need to complete. e.g.) stall? 
      DE_latch <= DE_latch_contents;
  end

endmodule




module SXT(IN, OUT);
  parameter IBITS = 16;
  parameter OBITS = 32;

  input  [IBITS-1:0] IN;
  output [OBITS-1:0] OUT;

  assign OUT = {{(OBITS-IBITS){IN[IBITS-1]}}, IN};
endmodule

