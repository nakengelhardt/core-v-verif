
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
// Engineer        Andreas Traber - atraber@iis.ee.ethz.ch                    //
//                                                                            //
// Additional contributions by:                                               //
//                 Matthias Baer - baermatt@student.ethz.ch                   //
//                 Igor Loi - igor.loi@unibo.it                               //
//                 Sven Stucki - svstucki@student.ethz.ch                     //
//                 Davide Schiavone - pschiavo@iis.ee.ethz.ch                 //
//                                                                            //
// Design Name:    Decoder                                                    //
// Project Name:   RI5CY                                                      //
// Language:       SystemVerilog                                              //
//                                                                            //
// Description:    Decoder                                                    //
//                                                                            //
////////////////////////////////////////////////////////////////////////////////
module miter 
    import cv32e40p_pkg:: * ;
    import cv32e40p_apu_core_pkg:: * ;
#(parameter PULP_XPULP = 1, parameter PULP_CLUSTER = 0, parameter A_EXTENSION = 0, parameter FPU = 0, parameter FP_DIVSQRT = 0, parameter PULP_SECURE = 0, parameter USE_PMP = 0, parameter SHARED_FP = 0, parameter SHARED_DSP_MULT = 0, parameter SHARED_INT_MULT = 0, parameter SHARED_INT_DIV = 0, parameter SHARED_FP_DIVSQRT = 0, parameter WAPUTYPE = 0, parameter APU_WOP_CPU = 6, parameter DEBUG_TRIGGER_EN = 1) (
    // PULP ISA Extension (including PULP specific CSRs and hardware loop, excluding p.elw)
    // singals running to/from controller
    input logic deassert_we_i,  // deassert we, we are stalled or not active
    // from IF/ID pipeline
    input logic [31:0] instr_rdata_i,  // instruction read from instr memory/cache
    input logic illegal_c_insn_i,  // compressed instruction decode failed
    // FPU
    input logic [(C_RM - 1):0] frm_i,  // Rounding mode from float CSR
    input PrivLvl_t current_priv_lvl_i,  // The current privilege level
    input logic debug_mode_i,  // processor is in debug mode
    input logic debug_wfi_no_sleep_i,  // do not let WFI cause sleep
    // HPM related control signals
    input logic [31:0] mcounteren_i) ;
    logic uut_hwlp_cnt_mux_sel_o ; 
    logic ref_hwlp_cnt_mux_sel_o ; 
    logic uut_hwlp_start_mux_sel_o ; 
    logic ref_hwlp_start_mux_sel_o ; 
    logic uut_hwlp_target_mux_sel_o ; 
    logic ref_hwlp_target_mux_sel_o ; 
    logic uut_data_load_event_o ; 
    logic ref_data_load_event_o ; 
    logic uut_prepost_useincr_o ; 
    logic ref_prepost_useincr_o ; 
    logic uut_data_we_o ; 
    logic ref_data_we_o ; 
    logic uut_data_req_o ; 
    logic ref_data_req_o ; 
    logic uut_csr_status_o ; 
    logic ref_csr_status_o ; 
    logic uut_csr_access_o ; 
    logic ref_csr_access_o ; 
    logic uut_regfile_alu_waddr_sel_o ; 
    logic ref_regfile_alu_waddr_sel_o ; 
    logic uut_regfile_alu_we_dec_o ; 
    logic ref_regfile_alu_we_dec_o ; 
    logic uut_regfile_alu_we_o ; 
    logic ref_regfile_alu_we_o ; 
    logic uut_regfile_mem_we_o ; 
    logic ref_regfile_mem_we_o ; 
    logic uut_apu_en_o ; 
    logic ref_apu_en_o ; 
    logic uut_mult_sel_subword_o ; 
    logic ref_mult_sel_subword_o ; 
    logic uut_mult_dot_en_o ; 
    logic ref_mult_dot_en_o ; 
    logic uut_mult_int_en_o ; 
    logic ref_mult_int_en_o ; 
    logic uut_is_subrot_o ; 
    logic ref_is_subrot_o ; 
    logic uut_is_clpx_o ; 
    logic ref_is_clpx_o ; 
    logic uut_scalar_replication_c_o ; 
    logic ref_scalar_replication_c_o ; 
    logic uut_scalar_replication_o ; 
    logic ref_scalar_replication_o ; 
    logic uut_alu_en_o ; 
    logic ref_alu_en_o ; 
    logic uut_alu_bmask_b_mux_sel_o ; 
    logic ref_alu_bmask_b_mux_sel_o ; 
    logic uut_alu_bmask_a_mux_sel_o ; 
    logic ref_alu_bmask_a_mux_sel_o ; 
    logic uut_reg_fp_d_o ; 
    logic ref_reg_fp_d_o ; 
    logic uut_reg_fp_c_o ; 
    logic ref_reg_fp_c_o ; 
    logic uut_reg_fp_b_o ; 
    logic ref_reg_fp_b_o ; 
    logic uut_reg_fp_a_o ; 
    logic ref_reg_fp_a_o ; 
    logic uut_regc_used_o ; 
    logic ref_regc_used_o ; 
    logic uut_regb_used_o ; 
    logic ref_regb_used_o ; 
    logic uut_rega_used_o ; 
    logic ref_rega_used_o ; 
    logic uut_fencei_insn_o ; 
    logic ref_fencei_insn_o ; 
    logic uut_wfi_o ; 
    logic ref_wfi_o ; 
    logic uut_ecall_insn_o ; 
    logic ref_ecall_insn_o ; 
    logic uut_dret_dec_o ; 
    logic ref_dret_dec_o ; 
    logic uut_uret_dec_o ; 
    logic ref_uret_dec_o ; 
    logic uut_mret_dec_o ; 
    logic ref_mret_dec_o ; 
    logic uut_dret_insn_o ; 
    logic ref_dret_insn_o ; 
    logic uut_uret_insn_o ; 
    logic ref_uret_insn_o ; 
    logic uut_mret_insn_o ; 
    logic ref_mret_insn_o ; 
    logic uut_ebrk_insn_o ; 
    logic ref_ebrk_insn_o ; 
    logic uut_illegal_insn_o ; 
    logic ref_illegal_insn_o ; 
    logic [0:0] ref_bmask_a_mux_o ; 
    logic [0:0] uut_bmask_a_mux_o ; 
    logic [1:0] ref_bmask_b_mux_o ; 
    logic [1:0] uut_bmask_b_mux_o ; 
    logic [(ALU_OP_WIDTH - 1):0] ref_alu_operator_o ; 
    logic [(ALU_OP_WIDTH - 1):0] uut_alu_operator_o ; 
    logic [2:0] ref_alu_op_a_mux_sel_o ; 
    logic [2:0] uut_alu_op_a_mux_sel_o ; 
    logic [2:0] ref_alu_op_b_mux_sel_o ; 
    logic [2:0] uut_alu_op_b_mux_sel_o ; 
    logic [1:0] ref_alu_op_c_mux_sel_o ; 
    logic [1:0] uut_alu_op_c_mux_sel_o ; 
    logic [1:0] ref_alu_vec_mode_o ; 
    logic [1:0] uut_alu_vec_mode_o ; 
    logic [0:0] ref_imm_a_mux_sel_o ; 
    logic [0:0] uut_imm_a_mux_sel_o ; 
    logic [3:0] ref_imm_b_mux_sel_o ; 
    logic [3:0] uut_imm_b_mux_sel_o ; 
    logic [1:0] ref_regc_mux_o ; 
    logic [1:0] uut_regc_mux_o ; 
    logic [2:0] ref_mult_operator_o ; 
    logic [2:0] uut_mult_operator_o ; 
    logic [0:0] ref_mult_imm_mux_o ; 
    logic [0:0] uut_mult_imm_mux_o ; 
    logic [1:0] ref_mult_signed_mode_o ; 
    logic [1:0] uut_mult_signed_mode_o ; 
    logic [1:0] ref_mult_dot_signed_o ; 
    logic [1:0] uut_mult_dot_signed_o ; 
    logic [(C_FPNEW_FMTBITS - 1):0] ref_fpu_dst_fmt_o ; 
    logic [(C_FPNEW_FMTBITS - 1):0] uut_fpu_dst_fmt_o ; 
    logic [(C_FPNEW_FMTBITS - 1):0] ref_fpu_src_fmt_o ; 
    logic [(C_FPNEW_FMTBITS - 1):0] uut_fpu_src_fmt_o ; 
    logic [(C_FPNEW_IFMTBITS - 1):0] ref_fpu_int_fmt_o ; 
    logic [(C_FPNEW_IFMTBITS - 1):0] uut_fpu_int_fmt_o ; 
    logic [(WAPUTYPE - 1):0] ref_apu_type_o ; 
    logic [(WAPUTYPE - 1):0] uut_apu_type_o ; 
    logic [(APU_WOP_CPU - 1):0] ref_apu_op_o ; 
    logic [(APU_WOP_CPU - 1):0] uut_apu_op_o ; 
    logic [1:0] ref_apu_lat_o ; 
    logic [1:0] uut_apu_lat_o ; 
    logic [(WAPUTYPE - 1):0] ref_apu_flags_src_o ; 
    logic [(WAPUTYPE - 1):0] uut_apu_flags_src_o ; 
    logic [2:0] ref_fp_rnd_mode_o ; 
    logic [2:0] uut_fp_rnd_mode_o ; 
    logic [1:0] ref_csr_op_o ; 
    logic [1:0] uut_csr_op_o ; 
    logic [1:0] ref_data_type_o ; 
    logic [1:0] uut_data_type_o ; 
    logic [1:0] ref_data_sign_extension_o ; 
    logic [1:0] uut_data_sign_extension_o ; 
    logic [1:0] ref_data_reg_offset_o ; 
    logic [1:0] uut_data_reg_offset_o ; 
    logic [5:0] ref_atop_o ; 
    logic [5:0] uut_atop_o ; 
    logic [2:0] ref_hwlp_we_o ; 
    logic [2:0] uut_hwlp_we_o ; 
    logic [1:0] ref_ctrl_transfer_insn_in_dec_o ; 
    logic [1:0] uut_ctrl_transfer_insn_in_dec_o ; 
    logic [1:0] ref_ctrl_transfer_insn_in_id_o ; 
    logic [1:0] uut_ctrl_transfer_insn_in_id_o ; 
    logic [1:0] ref_ctrl_transfer_target_mux_sel_o ; 
    logic [1:0] uut_ctrl_transfer_target_mux_sel_o ; 
    if ((PULP_XPULP != 1)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with PULP_XPULP = 1 but %0d was passed",PULP_XPULP) ;
    if ((PULP_CLUSTER != 0)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with PULP_CLUSTER = 0 but %0d was passed",PULP_CLUSTER) ;
    if ((A_EXTENSION != 0)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with A_EXTENSION = 0 but %0d was passed",A_EXTENSION) ;
    if ((FPU != 0)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with FPU = 0 but %0d was passed",FPU) ;
    if ((FP_DIVSQRT != 0)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with FP_DIVSQRT = 0 but %0d was passed",FP_DIVSQRT) ;
    if ((PULP_SECURE != 0)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with PULP_SECURE = 0 but %0d was passed",PULP_SECURE) ;
    if ((USE_PMP != 0)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with USE_PMP = 0 but %0d was passed",USE_PMP) ;
    if ((SHARED_FP != 0)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with SHARED_FP = 0 but %0d was passed",SHARED_FP) ;
    if ((SHARED_DSP_MULT != 0)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with SHARED_DSP_MULT = 0 but %0d was passed",SHARED_DSP_MULT) ;
    if ((SHARED_INT_MULT != 0)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with SHARED_INT_MULT = 0 but %0d was passed",SHARED_INT_MULT) ;
    if ((SHARED_INT_DIV != 0)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with SHARED_INT_DIV = 0 but %0d was passed",SHARED_INT_DIV) ;
    if ((SHARED_FP_DIVSQRT != 0)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with SHARED_FP_DIVSQRT = 0 but %0d was passed",SHARED_FP_DIVSQRT) ;
    if ((WAPUTYPE != 1)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with WAPUTYPE = 1 but %0d was passed",WAPUTYPE) ;
    if ((APU_WOP_CPU != 6)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with APU_WOP_CPU = 6 but %0d was passed",APU_WOP_CPU) ;
    if ((DEBUG_TRIGGER_EN != 1)) 
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with DEBUG_TRIGGER_EN = 1 but %0d was passed",DEBUG_TRIGGER_EN) ;
    cv32e40p_decoder ref_i (.mutsel(1'b0), .deassert_we_i(deassert_we_i), .illegal_insn_o(ref_illegal_insn_o), .ebrk_insn_o(ref_ebrk_insn_o), .mret_insn_o(ref_mret_insn_o), .uret_insn_o(ref_uret_insn_o), .dret_insn_o(ref_dret_insn_o), .mret_dec_o(ref_mret_dec_o), .uret_dec_o(ref_uret_dec_o), .dret_dec_o(ref_dret_dec_o), .ecall_insn_o(ref_ecall_insn_o), .wfi_o(ref_wfi_o), .fencei_insn_o(ref_fencei_insn_o), .rega_used_o(ref_rega_used_o), .regb_used_o(ref_regb_used_o), 
                .regc_used_o(ref_regc_used_o), .reg_fp_a_o(ref_reg_fp_a_o), .reg_fp_b_o(ref_reg_fp_b_o), .reg_fp_c_o(ref_reg_fp_c_o), .reg_fp_d_o(ref_reg_fp_d_o), .bmask_a_mux_o(ref_bmask_a_mux_o), .bmask_b_mux_o(ref_bmask_b_mux_o), .alu_bmask_a_mux_sel_o(ref_alu_bmask_a_mux_sel_o), .alu_bmask_b_mux_sel_o(ref_alu_bmask_b_mux_sel_o), .instr_rdata_i(instr_rdata_i), .illegal_c_insn_i(illegal_c_insn_i), .alu_en_o(ref_alu_en_o), .alu_operator_o(ref_alu_operator_o), .alu_op_a_mux_sel_o(ref_alu_op_a_mux_sel_o), .alu_op_b_mux_sel_o(ref_alu_op_b_mux_sel_o), 
                .alu_op_c_mux_sel_o(ref_alu_op_c_mux_sel_o), .alu_vec_mode_o(ref_alu_vec_mode_o), .scalar_replication_o(ref_scalar_replication_o), .scalar_replication_c_o(ref_scalar_replication_c_o), .imm_a_mux_sel_o(ref_imm_a_mux_sel_o), .imm_b_mux_sel_o(ref_imm_b_mux_sel_o), .regc_mux_o(ref_regc_mux_o), .is_clpx_o(ref_is_clpx_o), .is_subrot_o(ref_is_subrot_o), .mult_operator_o(ref_mult_operator_o), .mult_int_en_o(ref_mult_int_en_o), .mult_dot_en_o(ref_mult_dot_en_o), .mult_imm_mux_o(ref_mult_imm_mux_o), .mult_sel_subword_o(ref_mult_sel_subword_o), .mult_signed_mode_o(ref_mult_signed_mode_o), 
                .mult_dot_signed_o(ref_mult_dot_signed_o), .frm_i(frm_i), .fpu_dst_fmt_o(ref_fpu_dst_fmt_o), .fpu_src_fmt_o(ref_fpu_src_fmt_o), .fpu_int_fmt_o(ref_fpu_int_fmt_o), .apu_en_o(ref_apu_en_o), .apu_type_o(ref_apu_type_o), .apu_op_o(ref_apu_op_o), .apu_lat_o(ref_apu_lat_o), .apu_flags_src_o(ref_apu_flags_src_o), .fp_rnd_mode_o(ref_fp_rnd_mode_o), .regfile_mem_we_o(ref_regfile_mem_we_o), .regfile_alu_we_o(ref_regfile_alu_we_o), .regfile_alu_we_dec_o(ref_regfile_alu_we_dec_o), .regfile_alu_waddr_sel_o(ref_regfile_alu_waddr_sel_o), 
                .csr_access_o(ref_csr_access_o), .csr_status_o(ref_csr_status_o), .csr_op_o(ref_csr_op_o), .current_priv_lvl_i(current_priv_lvl_i), .data_req_o(ref_data_req_o), .data_we_o(ref_data_we_o), .prepost_useincr_o(ref_prepost_useincr_o), .data_type_o(ref_data_type_o), .data_sign_extension_o(ref_data_sign_extension_o), .data_reg_offset_o(ref_data_reg_offset_o), .data_load_event_o(ref_data_load_event_o), .atop_o(ref_atop_o), .hwlp_we_o(ref_hwlp_we_o), .hwlp_target_mux_sel_o(ref_hwlp_target_mux_sel_o), .hwlp_start_mux_sel_o(ref_hwlp_start_mux_sel_o), 
                .hwlp_cnt_mux_sel_o(ref_hwlp_cnt_mux_sel_o), .debug_mode_i(debug_mode_i), .debug_wfi_no_sleep_i(debug_wfi_no_sleep_i), .ctrl_transfer_insn_in_dec_o(ref_ctrl_transfer_insn_in_dec_o), .ctrl_transfer_insn_in_id_o(ref_ctrl_transfer_insn_in_id_o), .ctrl_transfer_target_mux_sel_o(ref_ctrl_transfer_target_mux_sel_o), .mcounteren_i(mcounteren_i)) ; 
    cv32e40p_decoder uut_i (.mutsel(1'b1), .deassert_we_i(deassert_we_i), .illegal_insn_o(uut_illegal_insn_o), .ebrk_insn_o(uut_ebrk_insn_o), .mret_insn_o(uut_mret_insn_o), .uret_insn_o(uut_uret_insn_o), .dret_insn_o(uut_dret_insn_o), .mret_dec_o(uut_mret_dec_o), .uret_dec_o(uut_uret_dec_o), .dret_dec_o(uut_dret_dec_o), .ecall_insn_o(uut_ecall_insn_o), .wfi_o(uut_wfi_o), .fencei_insn_o(uut_fencei_insn_o), .rega_used_o(uut_rega_used_o), .regb_used_o(uut_regb_used_o), 
                .regc_used_o(uut_regc_used_o), .reg_fp_a_o(uut_reg_fp_a_o), .reg_fp_b_o(uut_reg_fp_b_o), .reg_fp_c_o(uut_reg_fp_c_o), .reg_fp_d_o(uut_reg_fp_d_o), .bmask_a_mux_o(uut_bmask_a_mux_o), .bmask_b_mux_o(uut_bmask_b_mux_o), .alu_bmask_a_mux_sel_o(uut_alu_bmask_a_mux_sel_o), .alu_bmask_b_mux_sel_o(uut_alu_bmask_b_mux_sel_o), .instr_rdata_i(instr_rdata_i), .illegal_c_insn_i(illegal_c_insn_i), .alu_en_o(uut_alu_en_o), .alu_operator_o(uut_alu_operator_o), .alu_op_a_mux_sel_o(uut_alu_op_a_mux_sel_o), .alu_op_b_mux_sel_o(uut_alu_op_b_mux_sel_o), 
                .alu_op_c_mux_sel_o(uut_alu_op_c_mux_sel_o), .alu_vec_mode_o(uut_alu_vec_mode_o), .scalar_replication_o(uut_scalar_replication_o), .scalar_replication_c_o(uut_scalar_replication_c_o), .imm_a_mux_sel_o(uut_imm_a_mux_sel_o), .imm_b_mux_sel_o(uut_imm_b_mux_sel_o), .regc_mux_o(uut_regc_mux_o), .is_clpx_o(uut_is_clpx_o), .is_subrot_o(uut_is_subrot_o), .mult_operator_o(uut_mult_operator_o), .mult_int_en_o(uut_mult_int_en_o), .mult_dot_en_o(uut_mult_dot_en_o), .mult_imm_mux_o(uut_mult_imm_mux_o), .mult_sel_subword_o(uut_mult_sel_subword_o), .mult_signed_mode_o(uut_mult_signed_mode_o), 
                .mult_dot_signed_o(uut_mult_dot_signed_o), .frm_i(frm_i), .fpu_dst_fmt_o(uut_fpu_dst_fmt_o), .fpu_src_fmt_o(uut_fpu_src_fmt_o), .fpu_int_fmt_o(uut_fpu_int_fmt_o), .apu_en_o(uut_apu_en_o), .apu_type_o(uut_apu_type_o), .apu_op_o(uut_apu_op_o), .apu_lat_o(uut_apu_lat_o), .apu_flags_src_o(uut_apu_flags_src_o), .fp_rnd_mode_o(uut_fp_rnd_mode_o), .regfile_mem_we_o(uut_regfile_mem_we_o), .regfile_alu_we_o(uut_regfile_alu_we_o), .regfile_alu_we_dec_o(uut_regfile_alu_we_dec_o), .regfile_alu_waddr_sel_o(uut_regfile_alu_waddr_sel_o), 
                .csr_access_o(uut_csr_access_o), .csr_status_o(uut_csr_status_o), .csr_op_o(uut_csr_op_o), .current_priv_lvl_i(current_priv_lvl_i), .data_req_o(uut_data_req_o), .data_we_o(uut_data_we_o), .prepost_useincr_o(uut_prepost_useincr_o), .data_type_o(uut_data_type_o), .data_sign_extension_o(uut_data_sign_extension_o), .data_reg_offset_o(uut_data_reg_offset_o), .data_load_event_o(uut_data_load_event_o), .atop_o(uut_atop_o), .hwlp_we_o(uut_hwlp_we_o), .hwlp_target_mux_sel_o(uut_hwlp_target_mux_sel_o), .hwlp_start_mux_sel_o(uut_hwlp_start_mux_sel_o), 
                .hwlp_cnt_mux_sel_o(uut_hwlp_cnt_mux_sel_o), .debug_mode_i(debug_mode_i), .debug_wfi_no_sleep_i(debug_wfi_no_sleep_i), .ctrl_transfer_insn_in_dec_o(uut_ctrl_transfer_insn_in_dec_o), .ctrl_transfer_insn_in_id_o(uut_ctrl_transfer_insn_in_id_o), .ctrl_transfer_target_mux_sel_o(uut_ctrl_transfer_target_mux_sel_o), .mcounteren_i(mcounteren_i)) ; 
    always
        @(*) begin
            assert ((ref_illegal_insn_o == uut_illegal_insn_o)) ;
        if (~ref_illegal_insn_o) begin
            assert ((ref_ebrk_insn_o == uut_ebrk_insn_o)) ;
            assert ((ref_mret_insn_o == uut_mret_insn_o)) ;
            assert ((ref_uret_insn_o == uut_uret_insn_o)) ;
            assert ((ref_dret_insn_o == uut_dret_insn_o)) ;
            assert ((ref_mret_dec_o == uut_mret_dec_o)) ;
            assert ((ref_uret_dec_o == uut_uret_dec_o)) ;
            assert ((ref_dret_dec_o == uut_dret_dec_o)) ;
            assert ((ref_ecall_insn_o == uut_ecall_insn_o)) ;
            assert ((ref_wfi_o == uut_wfi_o)) ;
            assert ((ref_fencei_insn_o == uut_fencei_insn_o)) ;
            assert ((ref_rega_used_o == uut_rega_used_o)) ;
            assert ((ref_regb_used_o == uut_regb_used_o)) ;
            assert ((ref_regc_used_o == uut_regc_used_o)) ;
            assert ((ref_reg_fp_a_o == uut_reg_fp_a_o)) ;
            assert ((ref_reg_fp_b_o == uut_reg_fp_b_o)) ;
            assert ((ref_reg_fp_c_o == uut_reg_fp_c_o)) ;
            assert ((ref_reg_fp_d_o == uut_reg_fp_d_o)) ;
            assert ((ref_bmask_a_mux_o == uut_bmask_a_mux_o)) ;
            assert ((ref_bmask_b_mux_o == uut_bmask_b_mux_o)) ;
            assert ((ref_alu_bmask_a_mux_sel_o == uut_alu_bmask_a_mux_sel_o)) ;
            assert ((ref_alu_bmask_b_mux_sel_o == uut_alu_bmask_b_mux_sel_o)) ;
            assert ((ref_alu_en_o == uut_alu_en_o)) ;
            assert ((ref_alu_operator_o == uut_alu_operator_o)) ;
            assert ((ref_alu_op_a_mux_sel_o == uut_alu_op_a_mux_sel_o)) ;
            assert ((ref_alu_op_b_mux_sel_o == uut_alu_op_b_mux_sel_o)) ;
            assert ((ref_alu_op_c_mux_sel_o == uut_alu_op_c_mux_sel_o)) ;
            assert ((ref_alu_vec_mode_o == uut_alu_vec_mode_o)) ;
            assert ((ref_scalar_replication_o == uut_scalar_replication_o)) ;
            assert ((ref_scalar_replication_c_o == uut_scalar_replication_c_o)) ;
            assert ((ref_imm_a_mux_sel_o == uut_imm_a_mux_sel_o)) ;
            assert ((ref_imm_b_mux_sel_o == uut_imm_b_mux_sel_o)) ;
            assert ((ref_regc_mux_o == uut_regc_mux_o)) ;
            assert ((ref_is_clpx_o == uut_is_clpx_o)) ;
            assert ((ref_is_subrot_o == uut_is_subrot_o)) ;
            assert ((ref_mult_operator_o == uut_mult_operator_o)) ;
            assert ((ref_mult_int_en_o == uut_mult_int_en_o)) ;
            assert ((ref_mult_dot_en_o == uut_mult_dot_en_o)) ;
            assert ((ref_mult_imm_mux_o == uut_mult_imm_mux_o)) ;
            assert ((ref_mult_sel_subword_o == uut_mult_sel_subword_o)) ;
            assert ((ref_mult_signed_mode_o == uut_mult_signed_mode_o)) ;
            assert ((ref_mult_dot_signed_o == uut_mult_dot_signed_o)) ;
            assert ((ref_fpu_dst_fmt_o == uut_fpu_dst_fmt_o)) ;
            assert ((ref_fpu_src_fmt_o == uut_fpu_src_fmt_o)) ;
            assert ((ref_fpu_int_fmt_o == uut_fpu_int_fmt_o)) ;
            assert ((ref_apu_en_o == uut_apu_en_o)) ;
            assert ((ref_apu_type_o == uut_apu_type_o)) ;
            assert ((ref_apu_op_o == uut_apu_op_o)) ;
            assert ((ref_apu_lat_o == uut_apu_lat_o)) ;
            assert ((ref_apu_flags_src_o == uut_apu_flags_src_o)) ;
            assert ((ref_fp_rnd_mode_o == uut_fp_rnd_mode_o)) ;
            assert ((ref_regfile_mem_we_o == uut_regfile_mem_we_o)) ;
            assert ((ref_regfile_alu_we_o == uut_regfile_alu_we_o)) ;
            assert ((ref_regfile_alu_we_dec_o == uut_regfile_alu_we_dec_o)) ;
            assert ((ref_regfile_alu_waddr_sel_o == uut_regfile_alu_waddr_sel_o)) ;
            assert ((ref_csr_access_o == uut_csr_access_o)) ;
            assert ((ref_csr_status_o == uut_csr_status_o)) ;
            assert ((ref_csr_op_o == uut_csr_op_o)) ;
            assert ((ref_data_req_o == uut_data_req_o)) ;
            assert ((ref_data_we_o == uut_data_we_o)) ;
            assert ((ref_prepost_useincr_o == uut_prepost_useincr_o)) ;
            assert ((ref_data_type_o == uut_data_type_o)) ;
            assert ((ref_data_sign_extension_o == uut_data_sign_extension_o)) ;
            assert ((ref_data_reg_offset_o == uut_data_reg_offset_o)) ;
            assert ((ref_data_load_event_o == uut_data_load_event_o)) ;
            assert ((ref_atop_o == uut_atop_o)) ;
            assert ((ref_hwlp_we_o == uut_hwlp_we_o)) ;
            assert ((ref_hwlp_target_mux_sel_o == uut_hwlp_target_mux_sel_o)) ;
            assert ((ref_hwlp_start_mux_sel_o == uut_hwlp_start_mux_sel_o)) ;
            assert ((ref_hwlp_cnt_mux_sel_o == uut_hwlp_cnt_mux_sel_o)) ;
            assert ((ref_ctrl_transfer_insn_in_dec_o == uut_ctrl_transfer_insn_in_dec_o)) ;
            assert ((ref_ctrl_transfer_insn_in_id_o == uut_ctrl_transfer_insn_in_id_o)) ;
            assert ((ref_ctrl_transfer_target_mux_sel_o == uut_ctrl_transfer_target_mux_sel_o)) ;
        end
	end

// cv32e40p_decoder
endmodule



