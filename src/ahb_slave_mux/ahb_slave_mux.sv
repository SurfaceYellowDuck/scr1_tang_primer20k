`include "scr1_arch_custom.svh"
parameter SLAVE_DEVISES_CNT = `SLAVE_DEVISES_CNT;
module ahb_slave_mux 
(
                input                                clk,
                input                                rst_n,
                input        [SLAVE_DEVISES_CNT-1:0] hsel_s,
                input        [1:0]                   htrans,
                input        [31:0]                  rdata_0,
                input        [31:0]                  rdata_1,
                input        [SLAVE_DEVISES_CNT-1:0] resp,
                input        [SLAVE_DEVISES_CNT-1:0] readyout,
                output logic [31:0]                  hrdata,
                output logic                         hresp,
                output logic                         hready
);
    logic [SLAVE_DEVISES_CNT-1:0] local_hsel;
    always_ff @(posedge clk)begin
        if (~rst_n)begin
            local_hsel <= 2'b0;
        end
        else if (htrans != 2'b0 && hsel_s != 2'b0) begin
            local_hsel <= hsel_s;
        end
            
            end
            always @* begin
                if (local_hsel[0] == 1) begin
                    hresp  = resp[0];
                    hrdata = rdata_0;
                    hready = readyout[0];
                end
                else if (local_hsel[1] == 1) begin
                    hready = readyout[1];
                    hrdata = rdata_1;
                    hresp  = resp[1];
                end
                else begin
                    hready = 1'b1;
                    hrdata = 32'b0;
                    hresp  = 1'b0;
                end
            end
            endmodule: ahb_slave_mux
