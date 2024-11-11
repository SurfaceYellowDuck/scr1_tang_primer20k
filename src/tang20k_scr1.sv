/// Copyright by Syntacore LLC © 2016, 2017, 2021. See LICENSE for details
/// @file       <tang20k_scr1.sv>
/// @brief      Top-level entity with SCR1 for Tang Primer 20K board 
///

`include "includes/scr1_arch_types.svh"
`include "includes/scr1_arch_description.svh"
`include "includes/scr1_ahb.svh"
`include "includes/scr1_memif.svh"
`include "includes/scr1_ipic.svh"

//User-defined board-specific parameters accessible as memory-mapped GPIO
//parameter bit [31:0] FPGA_PRIMER20K_SOC_ID           = `SCR1_PTFM_SOC_ID;
//parameter bit [31:0] FPGA_PRIMER20K_BLD_ID           = `SCR1_PTFM_BLD_ID;
parameter bit [31:0] FPGA_TANG20K_CORE_CLK_FREQ    = `SCR1_PTFM_CORE_CLK_FREQ;

module tang20k_scr1 (
    // === CLOCK ===========================================
    input  logic                    CLK,
    // === RESET ===========================================
    input  logic                    RESETn,
    // === LEDs ============================================
    output logic                    LED0,
    output logic                    LED1,
    output logic                    LED2,
    output logic                    LED3,
    output logic                    LED4,
    output logic                    LED5,
    // === Buttons =========================================
    input  logic                    BTN0,
    input  logic                    BTN1,
    input  logic                    BTN2,
    input  logic                    BTN3,
    input  logic                    BTN4,
    // === FTDI UART =======================================
    input  logic                    UART_RX,
    output logic                    UART_TX
);



//=======================================================
//  Signals / Variables declarations
//=======================================================
logic                               pwrup_rst_n;
logic                               cpu_clk;
logic                               extn_rst_in_n;
logic                               extn_rst_n;
logic [1:0]                         extn_rst_n_sync;
logic                               hard_rst_n;
logic [3:0]                         hard_rst_n_count;
logic                               soc_rst_n;
logic                               cpu_rst_n;
`ifdef SCR1_DBG_EN
logic                               sys_rst_n;
`endif // SCR1_DBG_EN

// --- SCR1 ---------------------------------------------
logic [3:0]                         ahb_imem_hprot;
logic [2:0]                         ahb_imem_hburst;
logic [2:0]                         ahb_imem_hsize;
logic [1:0]                         ahb_imem_htrans;
logic [SCR1_AHB_WIDTH-1:0]          ahb_imem_haddr;
logic                               ahb_imem_hready;
logic [SCR1_AHB_WIDTH-1:0]          ahb_imem_hrdata;
logic                               ahb_imem_hresp;
//
logic [3:0]                         ahb_dmem_hprot;
logic [2:0]                         ahb_dmem_hburst;
logic [2:0]                         ahb_dmem_hsize;
logic [1:0]                         ahb_dmem_htrans;
logic [SCR1_AHB_WIDTH-1:0]          ahb_dmem_haddr;
logic                               ahb_dmem_hwrite;
logic [SCR1_AHB_WIDTH-1:0]          ahb_dmem_hwdata;
logic                               ahb_dmem_hready;
logic [SCR1_AHB_WIDTH-1:0]          ahb_dmem_hrdata;
logic                               ahb_dmem_hresp;
`ifdef SCR1_IPIC_EN
logic [31:0]                        scr1_irq;
`else
logic                               scr1_irq;
`endif // SCR1_IPIC_EN

// --- UART ---------------------------------------------
logic                               uart_rts_n; // <- UART
logic                               uart_dtr_n; // <- UART
logic                               uart_irq;

logic [31:0]                        uart_readdata;
logic                               uart_readdatavalid;
logic [31:0]                        uart_writedata;
logic [31:0]                        uart_address;
logic                               uart_write;
logic                               uart_read;
logic                               uart_waitrequest;

logic                               uart_wb_ack;
logic  [7:0]                        uart_wb_dat;
logic                               uart_read_vd;

// --- Heartbeat ----------------------------------------
logic [31:0]                        rtc_counter;
logic                               tick_2Hz;
logic                               heartbeat;

//=======================================================
//  Resets
//=======================================================
assign extn_rst_in_n    = RESETn;
assign cpu_clk          = CLK;
assign pwrup_rst_n      = 1'b1;

always_ff @(posedge cpu_clk, negedge pwrup_rst_n)
begin
    if (~pwrup_rst_n) begin
        extn_rst_n_sync     <= '0;
    end else begin
        extn_rst_n_sync[0]  <= extn_rst_in_n;
        extn_rst_n_sync[1]  <= extn_rst_n_sync[0];
    end
end
assign extn_rst_n = extn_rst_n_sync[1];

always_ff @(posedge cpu_clk, negedge pwrup_rst_n)
begin
    if (~pwrup_rst_n) begin
        hard_rst_n          <= 1'b0;
        hard_rst_n_count    <= '0;
    end else begin
        if (hard_rst_n) begin
            // hard_rst_n == 1 - de-asserted
            hard_rst_n          <= extn_rst_n;
            hard_rst_n_count    <= '0;
        end else begin
            // hard_rst_n == 0 - asserted
            if (extn_rst_n) begin
                if (hard_rst_n_count == '1) begin
                    // If extn_rst_n = 1 at least 16 clocks,
                    // de-assert hard_rst_n
                    hard_rst_n          <= 1'b1;
                end else begin
                    hard_rst_n_count    <= hard_rst_n_count + 1'b1;
                end
            end else begin
                // If extn_rst_n is asserted within 16-cycles window -> start
                // counting from the beginning
                hard_rst_n_count    <= '0;
            end
        end
    end
end

`ifdef SCR1_DBG_EN
assign soc_rst_n = sys_rst_n;
assign cpu_rst_n = sys_rst_n;
`else
assign soc_rst_n = hard_rst_n;
assign cpu_rst_n = hard_rst_n;
`endif // SCR1_DBG_EN

//=======================================================
//  Heartbeat
//=======================================================
always_ff @(posedge cpu_clk, negedge hard_rst_n)
begin
    if (~hard_rst_n) begin
        rtc_counter     <= '0;
        tick_2Hz        <= 1'b0;
    end
    else begin
        if (rtc_counter == '0) begin
            rtc_counter <= (FPGA_TANG20K_CORE_CLK_FREQ/2);
            tick_2Hz    <= 1'b1;
        end
        else begin
            rtc_counter <= rtc_counter - 1'b1;
            tick_2Hz    <= 1'b0;
        end
    end
end

always_ff @(posedge cpu_clk, negedge hard_rst_n)
begin
    if (~hard_rst_n) begin
        heartbeat       <= 1'b0;
    end
    else begin
        if (tick_2Hz) begin
            heartbeat   <= ~heartbeat;
        end
    end
end
logic dbg_tcm;
//=======================================================
//  SCR1 Core's Processor Cluster
//=======================================================
scr1_top_ahb
i_scr1 (
        // Common
        .pwrup_rst_n                (pwrup_rst_n            ),
        .rst_n                      (hard_rst_n             ),
        .cpu_rst_n                  (cpu_rst_n              ),
        .test_mode                  (1'b0                   ),
        .test_rst_n                 (1'b1                   ),
        .clk                        (cpu_clk                ),
        .rtc_clk                    (1'b0                   ),
`ifdef SCR1_DBG_EN
        .sys_rst_n_o                (sys_rst_n              ),
        .sys_rdc_qlfy_o             (                       ),
`endif // SCR1_DBG_EN

        // Fuses
        .fuse_mhartid               ('0                     ),
`ifdef SCR1_DBG_EN
        .fuse_idcode                (`SCR1_TAP_IDCODE       ),
`endif // SCR1_DBG_EN

        // IRQ
`ifdef SCR1_IPIC_EN
        .irq_lines                  (scr1_irq               ),
`else
        .ext_irq                    (scr1_irq             ),
`endif//SCR1_IPIC_EN
        .soft_irq                   ('0                     ),

        // Instruction Memory Interface
        .imem_hprot                 (ahb_imem_hprot         ),
        .imem_hburst                (ahb_imem_hburst        ),
        .imem_hsize                 (ahb_imem_hsize         ),
        .imem_htrans                (ahb_imem_htrans        ),
        .imem_hmastlock             (                       ),
        .imem_haddr                 (ahb_imem_haddr         ),
        .imem_hready                (ahb_imem_hready        ),
        .imem_hrdata                (ahb_imem_hrdata        ),
        .imem_hresp                 (ahb_imem_hresp         ),
        // Data Memory Interface
        .dmem_hprot                 (ahb_dmem_hprot         ),
        .dmem_hburst                (ahb_dmem_hburst        ),
        .dmem_hsize                 (ahb_dmem_hsize         ),
        .dmem_htrans                (ahb_dmem_htrans        ),
        .dmem_hmastlock             (                       ),
        .dmem_haddr                 (ahb_dmem_haddr         ),
        .dmem_hwrite                (ahb_dmem_hwrite        ),
        .dmem_hwdata                (ahb_dmem_hwdata        ),
        .dmem_hready                (ahb_dmem_hready        ),
        .dmem_hrdata                (ahb_dmem_hrdata        ),
        .dmem_hresp                 (ahb_dmem_hresp         ),

        .dbg_tcm                    (dbg_tcm                )
);

`ifdef SCR1_IPIC_EN
assign scr1_irq = {31'd0, uart_irq};
`else
assign scr1_irq = uart_irq;
`endif // SCR1_IPIC_EN

logic hsel_uart;
logic hsel_rom;
always_ff @(posedge cpu_clk) begin 
    if(~soc_rst_n)begin
        hsel_rom <= 0;
        hsel_uart <= 0;
    end
    else begin 
        hsel_uart <= (ahb_dmem_haddr[31:16] == 16'b1111111111011111); //uart addr 0xffdf0000
        hsel_rom <= (ahb_imem_haddr[31:16] == 16'b1111111111101111);
    end
end


(* ram_style = "block" *)  logic  [32-1:0]  ram_block_3  [16383:0] /* synthesis syn_ramstyle = "block_ram" */;


wire rom_need_action = ahb_imem_htrans != (2'b00 & hsel_rom);

logic [13:0] haddr;
typedef enum bit {idle, read_data} statetype;

// typedef enum bit
// {
//     idle = 2'b0,
//     read_data = 2'b1
// }
// statetype;
// statetype state, next_state;

// statetype state, nextstate;
// logic hready;
statetype state, nextstate;
assign ahb_imem_hready = (state == idle);
always_ff @(posedge cpu_clk) begin
    case(state) 
        idle        :   begin 
                            if(hsel_rom)
                                 haddr <= ahb_imem_haddr[$clog2(16384)+1:2];
                            end
        read_data   :   begin 
                            // if(haddr[12:2] == 11'b00000000000)
                            //     LED1 <=0;
                            ahb_imem_hrdata <= ram_block_3[haddr];
                            end
    endcase
end
// states register 
always_ff @(posedge cpu_clk)begin 
    // if(~soc_rst_n) begin 
    //     state <= init;
    // end
    // else begin 
    state <= nextstate;
    // end
end
// state transition logic
always_comb begin 
    case(state)
        default     :   nextstate = idle;
        // init        :   nextstate = idle;
        idle        :   nextstate = ~rom_need_action ? idle : read_data;
    endcase
end


always_ff @(posedge cpu_clk) begin 
    if(hsel_rom) begin 
        LED5 <= 0;
    end
    if(hsel_uart) begin 
        LED4 <= 0;
    end
    else begin 
        LED5 <= 1;
        LED4 <= 1;
    end
end

ahb_lite_uart16550
i_uart(
    .HCLK (cpu_clk),
    .HRESETn (soc_rst_n),
    .HADDR (ahb_dmem_haddr),
    .HBURST (ahb_dmem_hburst),
    .HMASTLOCK (1'b1),
    .HPROT (ahb_dmem_hprot),
    .HSEL (hsel_uart),
    .HSIZE (ahb_dmem_hsize),
    .HTRANS (ahb_dmem_htrans),
    .HWDATA (ahb_dmem_hwdata),
    .HWRITE (ahb_dmem_hwrite),
    .HRDATA (ahb_dmem_hrdata),
    .HREADY (ahb_dmem_hready),
    .HRESP (ahb_dmem_hresp),
    .SI_Endian (1'b1),

    .UART_SRX (UART_RX),
    .UART_STX (UART_TX),
    .UART_RTS (uart_rts_n),
    .UART_CTS (uart_rts_n),
    .UART_DTR (uart_dtr_n),
    .UART_DSR (uart_dtr_n),
    .UART_RI  ('1),
    .UART_DCD ('1),

    .UART_INT (uart_irq)
);

initial begin
    $readmemh("test.hex", ram_block_3);
end


// always_ff @(posedge clock)

// Do not delete, this is a loopback FSM for uart
// **************************************************************************************************
// logic [3 : 0] state;
// logic test3;
// logic test4;
// assign LED4 = test4;
// assign LED3 = test3;

// always_ff @(posedge cpu_clk) begin
//     if (~hard_rst_n) begin
//         ahb_dmem_haddr <= 32'd0;
//         ahb_dmem_htrans <= 2'b0;
//         ahb_dmem_hwdata <= 32'b0;
//         state <= 4'd0;
//         test3 <= 1'b1;
//         test4 <= 1'b1;
//     end else begin
//         if (state == 4'd0) begin // read LSR req
//             ahb_dmem_haddr <= 32'd20;
//             ahb_dmem_htrans <= 2'b10;
//             ahb_dmem_hwrite <= 1'b0;
//             state <= 4'd1;

//         end else if (state == 4'd1) begin // wait
//             ahb_dmem_htrans <= 2'b0; // IDLE
//             state <= 4'd2;
//         end else if (state == 4'd2) begin // get LSR resp
//             test4 <= 1'b0;
//             if (ahb_dmem_hready) begin
//                 if (ahb_dmem_hrdata[0]) begin // fifo not empty, read char req
//                     test3 <= 1'b0;
//                     ahb_dmem_haddr <= 32'd0;
//                     ahb_dmem_htrans <= 2'b10;
//                     ahb_dmem_hwrite <= 1'b0;
//                     state <= 4'd3;
//                 end else begin
//                     ahb_dmem_htrans <= 2'b0; // xfer is DONE
//                     state <= 4'd0;
//                 end
//             end else begin
//                 state <= 4'd2;
//             end
//         end 
//         else if(state == 4'd3) begin // wait
//             ahb_dmem_htrans <= 2'b0; // IDLE
//             state <= 4'd4;
//         end else if(state == 4'd4) begin // write 
//             ahb_dmem_htrans <= 2'b10;
//             ahb_dmem_hwrite <= 1'b1;
//             state <= 4'd5;
//         end else if(state == 4'd5) begin // wait
//             ahb_dmem_htrans <= 2'b0; // IDLE
//             state <= 4'd6; 
//         end else if(state == 4'd6) begin 
//             if(ahb_dmem_hready) begin 
//                 ahb_dmem_htrans <= 2'b0; 
//                 state <= 4'd0;
//             end
//             else state <= 4'd6;
//         end
//     end
// end
// **************************************************************************************************

//==========================================================
// LEDs
//==========================================================
// assign LED2      =  pwrup_rst_n;
// assign LED3      =  hard_rst_n;
// assign LED4      =  cpu_rst_n;
// assign LED5      =  heartbeat;

endmodule: tang20k_scr1