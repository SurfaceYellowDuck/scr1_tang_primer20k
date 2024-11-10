/// Copyright by Syntacore LLC © 2016-2020. See LICENSE for details
/// @file       <scr1_dp_memory.sv>
/// @brief      Dual-port synchronous memory with byte enable inputs
///

`include "../includes/scr1_arch_description.svh"

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

//-------------------------------------------------------------------------------
// Port A memory behavioral description
//-------------------------------------------------------------------------------
// always_ff @(posedge clk) begin
//     qa <= memory_array[addra];
// end

`elsif SCR1_TRGT_FPGA_GOWIN

localparam int unsigned RAM_SIZE_WORDS = SCR1_SIZE/SCR1_NBYTES;

//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
// (* ram_style = "block" *)  logic  [SCR1_NBYTES-1:0][7:0]  ram_block_1  [(RAM_SIZE_WORDS-1):0];
// (* ram_style = "block" *)  logic  [SCR1_NBYTES-1:0][7:0]  ram_block_2  [(RAM_SIZE_WORDS-1):0];

(* ram_style = "block" *)  logic  [SCR1_WIDTH-1:0]  ram_block_1  [(RAM_SIZE_WORDS-1):0] /* synthesis syn_ramstyle = "block_ram" */;
(* ram_style = "block" *)  logic  [SCR1_WIDTH-1:0]  ram_block_2  [(RAM_SIZE_WORDS-1):0] /* synthesis syn_ramstyle = "block_ram" */;



logic [3:0] wenbb;
//-------------------------------------------------------------------------------
// Port B memory behavioral description
//-------------------------------------------------------------------------------
assign wenbb = {4{wenb}} & webb;
always_ff @(posedge clk) begin
    // if (~rst) begin  
    //     ram_block_1[0] <= 32'h01402603;
    //     ram_block_1[1] <= 32'h00167613;
    //     ram_block_1[2] <= 32'hfe060ce3;
    //     ram_block_1[3] <= 32'h00000603;
    //     ram_block_1[4] <= 32'h00c02023;
    //     ram_block_1[5] <= 32'hfedff06f;

    //     ram_block_2[0] <= 32'h01402603;
    //     ram_block_2[1] <= 32'h00167613;
    //     ram_block_2[2] <= 32'hfe060ce3;
    //     ram_block_2[3] <= 32'h00000603;
    //     ram_block_2[4] <= 32'h00c02023;
    //     ram_block_1[5] <= 32'hfedff06f;
    // end
    if (wenb) begin
        // if (datab ==32'hfedff06f)
        //     dbg_sig <= 0;

        if (wenbb[0]) begin
            ram_block_1[addrb][0+:8] <= datab[0+:8];
            ram_block_2[addrb][0+:8] <= datab[0+:8];
            // if(datab[8:0] == 8'b00000001)
                // dbg_sig <= 0;
            // else db
        end
        if (wenbb[1]) begin
            ram_block_1[addrb][8+:8] <= datab[8+:8];
            ram_block_2[addrb][8+:8] <= datab[8+:8];
            // dbg_sig <= 0;
        end
        if (wenbb[2]) begin
            ram_block_1[addrb][16+:8] <= datab[16+:8];
            ram_block_2[addrb][16+:8] <= datab[16+:8];
            // dbg_sig <= 0;
        end
        if (wenbb[3]) begin
            ram_block_1[addrb][24+:8] <= datab[24+:8];
            ram_block_2[addrb][24+:8] <= datab[24+:8];
            // dbg_sig <= 0;
        end
    end
    if(renb) begin
        qb <= ram_block_1[addra];
    end
end
//-------------------------------------------------------------------------------
// Port A memory behavioral description
//-------------------------------------------------------------------------------
always_ff @(posedge clk) begin
    if(rena) begin 
        qa <= ram_block_2[addra];
    end
end


// (* ram_style = "block" *)  logic  [SCR1_WIDTH-1:0]  ram_block  [RAM_SIZE_WORDS-1:0];

// //-------------------------------------------------------------------------------
// // Port A memory behavioral description
// //-------------------------------------------------------------------------------
// always_ff @(posedge clk) begin
//     if (~rst) begin  
//         ram_block[0] <= 32'h01402603;
//         ram_block[1] <= 32'h00167613;
//         ram_block[2] <= 32'hfe060ce3;
//         ram_block[3] <= 32'h00000603;
//         ram_block[4] <= 32'h00c02023;
//         ram_block[5] <= 32'hfedff06f;
//         dbg_sig <= 0;
//     end else if (rena) begin 
//         if (addra == 8)begin 
//             dbg_sig <= 1;
//         end 
//         qa <= ram_block[addra];
//     end
// end

// //-------------------------------------------------------------------------------
// // Port B memory behavioral description
// //-------------------------------------------------------------------------------
// always_ff @(posedge clk) begin
//     if (renb) begin
//         // if (addrb == 8)begin 
//         //     dbg_sig <= 0;
//         // end
//         qb <= ram_block[addrb];
//     end
// end

//-------------------------------------------------------------------------------
// Port A memory behavioral description
//-------------------------------------------------------------------------------
// always_ff @(posedge clk) begin
    // if (~rst) begin  
        // ram_block[0] <= 32'h01402603;
        // ram_block[1] <= 32'h00167613;//
        // ram_block[2] <= 32'hfe060ce3;
        // ram_block[3] <= 32'h00000603;
        // ram_block[4] <= 32'h00c02023;
        // ram_block[5] <= 32'hfedff06f;
        // dbg_sig <= 0;
    // end else if (rena) begin 
        // if (addra == 8)begin 
            // dbg_sig <= 1;
        // end 
        // qa <= ram_block[addra];
    // end
// end

//-------------------------------------------------------------------------------
// Port B memory behavioral description
//-------------------------------------------------------------------------------
// always_ff @(posedge clk) begin
    // if (renb) begin
        // if (addrb == 8)begin 
        //     dbg_sig <= 0;
        // end
//         qb <= ram_block[addrb];
//     end
// end

//-------------------------------------------------------------------------------
// Port B memory behavioral description
//-------------------------------------------------------------------------------
//always_ff @(posedge clk) begin
//    if (wenb) begin
//        for (int i=0; i<SCR1_NBYTES; i++) begin
//            if (webb[i]) begin
//                ram_block[addrb][i*8 +: 8] <= datab[i*8 +: 8];
//            end
//        end
//    end
//    else begin
//        qb = ram_block[addrb];
//        qa = ram_block[addra];
//    end
//end

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
