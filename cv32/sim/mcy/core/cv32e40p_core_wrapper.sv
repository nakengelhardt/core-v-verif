
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
module cv32e40p_core 
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
    // Instruction memory interface
    output logic instr_req_o, 
    input logic instr_gnt_i, 
    input logic instr_rvalid_i, 
    output logic [31:0] instr_addr_o, 
    input logic [31:0] instr_rdata_i, 
    // Data memory interface
    output logic data_req_o, 
    input logic data_gnt_i, 
    input logic data_rvalid_i, 
    output logic data_we_o, 
    output logic [3:0] data_be_o, 
    output logic [31:0] data_addr_o, 
    output logic [31:0] data_wdata_o, 
    input logic [31:0] data_rdata_i, 
    // apu-interconnect
    // handshake signals
    output logic apu_master_req_o, 
    output logic apu_master_ready_o, 
    input logic apu_master_gnt_i, 
    // request channel
    output logic [(APU_NARGS_CPU - 1):0][31:0] apu_master_operands_o, 
    output logic [(APU_WOP_CPU - 1):0] apu_master_op_o, 
    output logic [(WAPUTYPE - 1):0] apu_master_type_o, 
    output logic [(APU_NDSFLAGS_CPU - 1):0] apu_master_flags_o, 
    // response channel
    input logic apu_master_valid_i, 
    input logic [31:0] apu_master_result_i, 
    input logic [(APU_NUSFLAGS_CPU - 1):0] apu_master_flags_i, 
    // Interrupt inputs
    input logic [31:0] irq_i,  // CLINT interrupts + CLINT extension interrupts
    output logic irq_ack_o, 
    output logic [4:0] irq_id_o, 
    // Debug Interface
    input logic debug_req_i, 
    // CPU Control Signals
    input logic fetch_enable_i, 
    output logic core_sleep_o) ;
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
    mutated wrapped_i (.clk_i(clk_i), .rst_ni(rst_ni), .pulp_clock_en_i(pulp_clock_en_i), .scan_cg_en_i(scan_cg_en_i), .boot_addr_i(boot_addr_i), .mtvec_addr_i(mtvec_addr_i), .dm_halt_addr_i(dm_halt_addr_i), .hart_id_i(hart_id_i), .dm_exception_addr_i(dm_exception_addr_i), .instr_req_o(instr_req_o), .instr_gnt_i(instr_gnt_i), .instr_rvalid_i(instr_rvalid_i), .instr_addr_o(instr_addr_o), .instr_rdata_i(instr_rdata_i), .data_req_o(data_req_o), 
                .data_gnt_i(data_gnt_i), .data_rvalid_i(data_rvalid_i), .data_we_o(data_we_o), .data_be_o(data_be_o), .data_addr_o(data_addr_o), .data_wdata_o(data_wdata_o), .data_rdata_i(data_rdata_i), .apu_master_req_o(apu_master_req_o), .apu_master_ready_o(apu_master_ready_o), .apu_master_gnt_i(apu_master_gnt_i), .apu_master_operands_o(apu_master_operands_o), .apu_master_op_o(apu_master_op_o), .apu_master_type_o(apu_master_type_o), .apu_master_flags_o(apu_master_flags_o), .apu_master_valid_i(apu_master_valid_i), 
                .apu_master_result_i(apu_master_result_i), .apu_master_flags_i(apu_master_flags_i), .irq_i(irq_i), .irq_ack_o(irq_ack_o), .irq_id_o(irq_id_o), .debug_req_i(debug_req_i), .fetch_enable_i(fetch_enable_i), .core_sleep_o(core_sleep_o)) ; 
endmodule



