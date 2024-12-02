`include "scr1_ahb.svh"
parameter ROM_SIZE = `ROM_SIZE;

module rom_mem 
(
                input                               clk,
                input                               rst_n,
                input       [$clog2(ROM_SIZE)+1:2]  imem_addr, 
                input       [1:0]                   imem_trans, 
                input                               imem_hsel, 
                output                              imem_ready, 
                output                              imem_resp, 
                output logic [SCR1_AHB_WIDTH-1:0]   imem_data, 
                input        [$clog2(ROM_SIZE)+1:2] dmem_addr, 
                input        [1:0]                  dmem_trans, 
                input                               dmem_hsel, 
                input                               dmem_hready_in, 
                output reg                          dmem_ready, 
                output reg                          dmem_resp, 
                output logic [SCR1_AHB_WIDTH-1:0]   dmem_data
);

    (* ram_style = "block" *)  logic  [SCR1_AHB_WIDTH-1:0]  rom_block  [ROM_SIZE-1:0] /* synthesis syn_ramstyle = "block_ram" */;
    
    logic rom_imem_need_action;
    logic rom_dmem_need_action;
    assign rom_imem_need_action = (imem_trans != 2'b00) && imem_hsel;
    assign rom_dmem_need_action = (dmem_trans != 2'b00) && dmem_hsel && dmem_hready_in;
    assign imem_ready           = 1'b1;
    assign imem_resp            = 1'b0;
    
    
    always_ff @(posedge clk) begin
        if (~rst_n) begin
            dmem_ready <= 1'b1;
            dmem_resp  <= 1'b0;
        end
            if (rom_imem_need_action) begin
                imem_data <= rom_block[imem_addr];
            end
                if (rom_dmem_need_action) begin
                    dmem_data  <= rom_block[dmem_addr];
                    dmem_ready <= 1'b1;
                    dmem_resp  <= 1'b0;
                end
    end
    
    initial begin
        $readmemh("scbl.hex", rom_block);
    end
    endmodule: rom_mem
