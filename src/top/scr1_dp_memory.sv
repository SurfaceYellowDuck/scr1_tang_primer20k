/// Copyright by Syntacore LLC © 2016-2020. See LICENSE for details
/// @file       <scr1_dp_memory.sv>
/// @brief      Dual-port synchronous memory with byte enable inputs
///

`include "scr1_arch_description.svh"

`ifdef SCR1_TCM_EN
module scr1_dp_memory
#(
    parameter SCR1_WIDTH    = 32,
    parameter SCR1_SIZE     = `SCR1_IMEM_AWIDTH'h00010000,
    parameter SCR1_NBYTES   = SCR1_WIDTH / 8
)
(
    input   logic                           clk,
    input   logic                           rst,
    // Port A
    input   logic                           rena,
    input   logic [$clog2(SCR1_SIZE)-1:2]   addra,
    output  logic [SCR1_WIDTH-1:0]          qa,
    // Port B
    input   logic                           renb,
    input   logic                           wenb,
    input   logic [SCR1_NBYTES-1:0]         webb,
    input   logic [$clog2(SCR1_SIZE)-1:2]   addrb,
    input   logic [SCR1_WIDTH-1:0]          datab,
    output  logic [SCR1_WIDTH-1:0]          qb,

    output  logic                           dbg_sig
);

`ifdef SCR1_TRGT_FPGA_INTEL
//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
 `ifdef SCR1_TRGT_FPGA_INTEL_MAX10        //32                                      //16384
(* ramstyle = "M9K" *)    logic [SCR1_NBYTES-1:0][7:0]  memory_array  [0:(SCR1_SIZE/SCR1_NBYTES)-1];
 `elsif SCR1_TRGT_FPGA_INTEL_ARRIAV
(* ramstyle = "M10K" *)   logic [SCR1_NBYTES-1:0][7:0]  memory_array  [0:(SCR1_SIZE/SCR1_NBYTES)-1];
 `endif
logic [3:0] wenbb;
//-------------------------------------------------------------------------------
// Port B memory behavioral description
//-------------------------------------------------------------------------------
assign wenbb = {4{wenb}} & webb;
always_ff @(posedge clk) begin
    if (wenb) begin
        if (wenbb[0]) begin
            ram_block_1[addrb][0+:8] <= datab[0+:8];
            ram_block_2[addrb][0+:8] <= datab[0+:8];
        end
        if (wenbb[1]) begin
            ram_block_1[addrb][8+:8] <= datab[8+:8];
            ram_block_2[addrb][8+:8] <= datab[8+:8];
        end
        if (wenbb[2]) begin
            ram_block_1[addrb][16+:8] <= datab[16+:8];
            ram_block_2[addrb][16+:8] <= datab[16+:8];
        end
        if (wenbb[3]) begin
            ram_block_1[addrb][24+:8] <= datab[24+:8];
            ram_block_2[addrb][24+:8] <= datab[24+:8];
        end
    end
    if(renb) begin
        qb <= ram_block_1[addrb];
    end
    if(rena) begin
        qa <= ram_block_2[addra];
    end
end

`elsif SCR1_TRGT_FPGA_GOWIN

localparam int unsigned RAM_SIZE_WORDS = SCR1_SIZE/SCR1_NBYTES;

//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
(* ram_style = "block" *)  logic  [SCR1_WIDTH-1:0]  ram_block_1  [(RAM_SIZE_WORDS-1):0] /* synthesis syn_ramstyle = "block_ram" */;

logic [3:0] wenbb;
//-------------------------------------------------------------------------------
// Port B memory behavioral description
//-------------------------------------------------------------------------------
always_ff @(posedge clk) begin
    if (wenb) begin
        ram_block_1[addrb] <= datab;
    end
    if(renb) begin
        qb <= ram_block_1[addrb];
    end
end
//-------------------------------------------------------------------------------
// Port A memory behavioral description
//-------------------------------------------------------------------------------
always_ff @(posedge clk) begin 
    if(rena) begin
        qa <= ram_block_1[addra];
    end
end

`else // SCR1_TRGT_FPGA_INTEL

// CASE: OTHERS - SCR1_TRGT_FPGA_XILINX, SIMULATION, ASIC etc

localparam int unsigned RAM_SIZE_WORDS = SCR1_SIZE/SCR1_NBYTES;

//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
 `ifdef SCR1_TRGT_FPGA_XILINX
(* ram_style = "block" *)  logic  [SCR1_WIDTH-1:0]  ram_block  [RAM_SIZE_WORDS-1:0];
 `else  // ASIC or SIMULATION
logic  [SCR1_WIDTH-1:0]  ram_block  [RAM_SIZE_WORDS-1:0];
 `endif
//-------------------------------------------------------------------------------
// Port A memory behavioral description
//-------------------------------------------------------------------------------
always_ff @(posedge clk) begin
    if (rena) begin
        qa <= ram_block[addra];
    end
end

//-------------------------------------------------------------------------------
// Port B memory behavioral description
//-------------------------------------------------------------------------------
always_ff @(posedge clk) begin
    if (wenb) begin
        for (int i=0; i<SCR1_NBYTES; i++) begin
            if (webb[i]) begin
                ram_block[addrb][i*8 +: 8] <= datab[i*8 +: 8];
            end
        end
    end
    if (renb) begin
        qb <= ram_block[addrb];
    end
end

`endif // SCR1_TRGT_FPGA_INTEL

endmodule : scr1_dp_memory

`endif // SCR1_TCM_EN
