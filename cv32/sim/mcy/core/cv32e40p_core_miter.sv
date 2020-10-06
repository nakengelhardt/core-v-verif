
// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
////////////////////////////////////////////////////////////////////////////////
// Engineer:       Matthias Baer - baermatt@student.ethz.ch                   //
//                                                                            //
// Additional contributions by:                                               //
//                 Igor Loi - igor.loi@unibo.it                               //
//                 Andreas Traber - atraber@student.ethz.ch                   //
//                 Sven Stucki - svstucki@student.ethz.ch                     //
//                 Michael Gautschi - gautschi@iis.ee.ethz.ch                 //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    Top level module                                           //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Top level module of the RISC-V core.                       //
//                 added APU, FPU parameter to include the APU_dispatcher     //
//                 and the FPU                                                //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
module miter 
    import cv32e40p_apu_core_pkg:: * ;
#(parameter PULP_XPULP = 1, parameter PULP_CLUSTER = 0, parameter FPU = 0, parameter PULP_ZFINX = 0, parameter NUM_MHPMCOUNTERS = 1) (
    // PULP ISA Extension (incl. custom CSRs and hardware loop, excl. p.elw) !!! HARDWARE LOOP IS NOT OPERATIONAL YET !!!
    // PULP Cluster interface (incl. p.elw)
    // Floating Point Unit (interfaced via APU interface)
    // Float-in-General Purpose registers
    // Clock and Reset
    input logic clk_i, 
    input logic rst_ni, 
    input logic pulp_clock_en_i,  // PULP clock enable (only used if PULP_CLUSTER = 1)
    input logic scan_cg_en_i,  // Enable all clock gates for testing
    // Core ID, Cluster ID, debug mode halt address and boot address are considered more or less static
    input logic [31:0] boot_addr_i, 
    input logic [31:0] mtvec_addr_i, 
    input logic [31:0] dm_halt_addr_i, 
    input logic [31:0] hart_id_i, 
    input logic [31:0] dm_exception_addr_i, 
    input logic instr_gnt_i, 
    input logic instr_rvalid_i, 
    input logic [31:0] instr_rdata_i, 
    input logic data_gnt_i, 
    input logic data_rvalid_i, 
    input logic [31:0] data_rdata_i, 
    input logic apu_master_gnt_i, 
    // response channel
    input logic apu_master_valid_i, 
    input logic [31:0] apu_master_result_i, 
    input logic [(APU_NUSFLAGS_CPU - 1):0] apu_master_flags_i, 
    // Interrupt inputs
    input logic [31:0] irq_i,  // CLINT interrupts + CLINT extension interrupts
    // Debug Interface
    input logic debug_req_i, 
    // CPU Control Signals
    input logic fetch_enable_i) ;
    logic uut_core_sleep_o ; 
    logic ref_core_sleep_o ; 
    logic uut_irq_ack_o ; 
    logic ref_irq_ack_o ; 
    logic uut_apu_master_ready_o ; 
    logic ref_apu_master_ready_o ; 
    logic uut_apu_master_req_o ; 
    logic ref_apu_master_req_o ; 
    logic uut_data_we_o ; 
    logic ref_data_we_o ; 
    logic uut_data_req_o ; 
    logic ref_data_req_o ; 
    logic uut_instr_req_o ; 
    logic ref_instr_req_o ; 
    logic [31:0] ref_instr_addr_o ; 
    logic [31:0] uut_instr_addr_o ; 
    logic [3:0] ref_data_be_o ; 
    logic [3:0] uut_data_be_o ; 
    logic [31:0] ref_data_addr_o ; 
    logic [31:0] uut_data_addr_o ; 
    logic [31:0] ref_data_wdata_o ; 
    logic [31:0] uut_data_wdata_o ; 
    logic [(APU_NARGS_CPU - 1):0][31:0] ref_apu_master_operands_o ; 
    logic [(APU_NARGS_CPU - 1):0][31:0] uut_apu_master_operands_o ; 
    logic [(APU_WOP_CPU - 1):0] ref_apu_master_op_o ; 
    logic [(APU_WOP_CPU - 1):0] uut_apu_master_op_o ; 
    logic [(WAPUTYPE - 1):0] ref_apu_master_type_o ; 
    logic [(WAPUTYPE - 1):0] uut_apu_master_type_o ; 
    logic [(APU_NDSFLAGS_CPU - 1):0] ref_apu_master_flags_o ; 
    logic [(APU_NDSFLAGS_CPU - 1):0] uut_apu_master_flags_o ; 
    logic [4:0] ref_irq_id_o ; 
    logic [4:0] uut_irq_id_o ; 
    if ((PULP_XPULP != 1)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with PULP_XPULP = 1 but %0d was passed",PULP_XPULP) ;
    if ((PULP_CLUSTER != 0)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with PULP_CLUSTER = 0 but %0d was passed",PULP_CLUSTER) ;
    if ((FPU != 0)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with FPU = 0 but %0d was passed",FPU) ;
    if ((PULP_ZFINX != 0)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with PULP_ZFINX = 0 but %0d was passed",PULP_ZFINX) ;
    if ((NUM_MHPMCOUNTERS != 1)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with NUM_MHPMCOUNTERS = 1 but %0d was passed",NUM_MHPMCOUNTERS) ;
    cv32e40p_core ref_i (.mutsel(8'b0), .clk_i(clk_i), .rst_ni(rst_ni), .pulp_clock_en_i(pulp_clock_en_i), .scan_cg_en_i(scan_cg_en_i), .boot_addr_i(boot_addr_i), .mtvec_addr_i(mtvec_addr_i), .dm_halt_addr_i(dm_halt_addr_i), .hart_id_i(hart_id_i), .dm_exception_addr_i(dm_exception_addr_i), .instr_req_o(ref_instr_req_o), .instr_gnt_i(instr_gnt_i), .instr_rvalid_i(instr_rvalid_i), .instr_addr_o(ref_instr_addr_o), .instr_rdata_i(instr_rdata_i), 
                .data_req_o(ref_data_req_o), .data_gnt_i(data_gnt_i), .data_rvalid_i(data_rvalid_i), .data_we_o(ref_data_we_o), .data_be_o(ref_data_be_o), .data_addr_o(ref_data_addr_o), .data_wdata_o(ref_data_wdata_o), .data_rdata_i(data_rdata_i), .apu_master_req_o(ref_apu_master_req_o), .apu_master_ready_o(ref_apu_master_ready_o), .apu_master_gnt_i(apu_master_gnt_i),
 .\apu_master_operands_o[0] (ref_apu_master_operands_o[0]),
 .\apu_master_operands_o[1] (ref_apu_master_operands_o[1]),
 .\apu_master_operands_o[2] (ref_apu_master_operands_o[2]),
 .apu_master_op_o(ref_apu_master_op_o), .apu_master_type_o(ref_apu_master_type_o), .apu_master_flags_o(ref_apu_master_flags_o), 
                .apu_master_valid_i(apu_master_valid_i), .apu_master_result_i(apu_master_result_i), .apu_master_flags_i(apu_master_flags_i), .irq_i(irq_i), .irq_ack_o(ref_irq_ack_o), .irq_id_o(ref_irq_id_o), .debug_req_i(debug_req_i), .fetch_enable_i(fetch_enable_i), .core_sleep_o(ref_core_sleep_o)) ; 
    cv32e40p_core uut_i (.mutsel(8'b01), .clk_i(clk_i), .rst_ni(rst_ni), .pulp_clock_en_i(pulp_clock_en_i), .scan_cg_en_i(scan_cg_en_i), .boot_addr_i(boot_addr_i), .mtvec_addr_i(mtvec_addr_i), .dm_halt_addr_i(dm_halt_addr_i), .hart_id_i(hart_id_i), .dm_exception_addr_i(dm_exception_addr_i), .instr_req_o(uut_instr_req_o), .instr_gnt_i(instr_gnt_i), .instr_rvalid_i(instr_rvalid_i), .instr_addr_o(uut_instr_addr_o), .instr_rdata_i(instr_rdata_i), 
                .data_req_o(uut_data_req_o), .data_gnt_i(data_gnt_i), .data_rvalid_i(data_rvalid_i), .data_we_o(uut_data_we_o), .data_be_o(uut_data_be_o), .data_addr_o(uut_data_addr_o), .data_wdata_o(uut_data_wdata_o), .data_rdata_i(data_rdata_i), .apu_master_req_o(uut_apu_master_req_o), .apu_master_ready_o(uut_apu_master_ready_o), .apu_master_gnt_i(apu_master_gnt_i),
 .\apu_master_operands_o[0] (uut_apu_master_operands_o[0]),
 .\apu_master_operands_o[1] (uut_apu_master_operands_o[1]),
 .\apu_master_operands_o[2] (uut_apu_master_operands_o[2]),
 .apu_master_op_o(uut_apu_master_op_o), .apu_master_type_o(uut_apu_master_type_o), .apu_master_flags_o(uut_apu_master_flags_o), 
                .apu_master_valid_i(apu_master_valid_i), .apu_master_result_i(apu_master_result_i), .apu_master_flags_i(apu_master_flags_i), .irq_i(irq_i), .irq_ack_o(uut_irq_ack_o), .irq_id_o(uut_irq_id_o), .debug_req_i(debug_req_i), .fetch_enable_i(fetch_enable_i), .core_sleep_o(uut_core_sleep_o)) ; 

logic init_cycle = 1'b1;
always @ (posedge clk_i) begin
	init_cycle = 1'b0;
end


    always
        @(*)
        begin
		if (init_cycle) assume (!rst_ni);
	if (rst_ni) begin
            assert ((ref_instr_req_o == uut_instr_req_o)) ;
            assert ((ref_instr_addr_o == uut_instr_addr_o)) ;
            assert ((ref_data_req_o == uut_data_req_o)) ;
            assert ((ref_data_we_o == uut_data_we_o)) ;
            assert ((ref_data_be_o == uut_data_be_o)) ;
            assert ((ref_data_addr_o == uut_data_addr_o)) ;
            assert ((ref_data_wdata_o == uut_data_wdata_o)) ;
            assert ((ref_apu_master_req_o == uut_apu_master_req_o)) ;
            assert ((ref_apu_master_ready_o == uut_apu_master_ready_o)) ;
            assert ((ref_apu_master_operands_o[0] == uut_apu_master_operands_o[0])) ;
            assert ((ref_apu_master_operands_o[1] == uut_apu_master_operands_o[1])) ;
            assert ((ref_apu_master_operands_o[2] == uut_apu_master_operands_o[2])) ;
            assert ((ref_apu_master_op_o == uut_apu_master_op_o)) ;
            assert ((ref_apu_master_type_o == uut_apu_master_type_o)) ;
            assert ((ref_apu_master_flags_o == uut_apu_master_flags_o)) ;
            assert ((ref_irq_ack_o == uut_irq_ack_o)) ;
            assert ((ref_irq_id_o == uut_irq_id_o)) ;
            assert ((ref_core_sleep_o == uut_core_sleep_o)) ;
        end
	end
endmodule



