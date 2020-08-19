
module mutsel_gen_cv32e40p_decoder (output reg [7:0] mutsel) ;
    export "DPI-C"  task  set_mutidx;
    task  set_mutidx(input [7:0] idx) ; 
        mutsel = idx ;
    endtask
endmodule



module cv32e40p_decoder 
    import cv32e40p_pkg:: * ;
    import cv32e40p_apu_core_pkg:: * ;
#(parameter PULP_XPULP = 1, parameter PULP_CLUSTER = 0, parameter A_EXTENSION = 0, parameter FPU = 0, parameter FP_DIVSQRT = 0, parameter PULP_SECURE = 0, parameter USE_PMP = 0, parameter SHARED_FP = 0, parameter SHARED_DSP_MULT = 0, parameter SHARED_INT_MULT = 0, parameter SHARED_INT_DIV = 0, parameter SHARED_FP_DIVSQRT = 0, parameter WAPUTYPE = 0, parameter APU_WOP_CPU = 6, parameter DEBUG_TRIGGER_EN = 1) (
    input logic deassert_we_i, 
    input logic data_misaligned_i, 
    input logic mult_multicycle_i, 
    output logic instr_multicycle_o, 
    output logic illegal_insn_o, 
    output logic ebrk_insn_o, 
    output logic mret_insn_o, 
    output logic uret_insn_o, 
    output logic dret_insn_o, 
    output logic mret_dec_o, 
    output logic uret_dec_o, 
    output logic dret_dec_o, 
    output logic ecall_insn_o, 
    output logic pipe_flush_o, 
    output logic fencei_insn_o, 
    output logic rega_used_o, 
    output logic regb_used_o, 
    output logic regc_used_o, 
    output logic reg_fp_a_o, 
    output logic reg_fp_b_o, 
    output logic reg_fp_c_o, 
    output logic reg_fp_d_o, 
    output logic [0:0] bmask_a_mux_o, 
    output logic [1:0] bmask_b_mux_o, 
    output logic alu_bmask_a_mux_sel_o, 
    output logic alu_bmask_b_mux_sel_o, 
    input logic [31:0] instr_rdata_i, 
    input logic illegal_c_insn_i, 
    output logic alu_en_o, 
    output logic [(ALU_OP_WIDTH - 1):0] alu_operator_o, 
    output logic [2:0] alu_op_a_mux_sel_o, 
    output logic [2:0] alu_op_b_mux_sel_o, 
    output logic [1:0] alu_op_c_mux_sel_o, 
    output logic [1:0] alu_vec_mode_o, 
    output logic scalar_replication_o, 
    output logic scalar_replication_c_o, 
    output logic [0:0] imm_a_mux_sel_o, 
    output logic [3:0] imm_b_mux_sel_o, 
    output logic [1:0] regc_mux_o, 
    output logic is_clpx_o, 
    output logic is_subrot_o, 
    output logic [2:0] mult_operator_o, 
    output logic mult_int_en_o, 
    output logic mult_dot_en_o, 
    output logic [0:0] mult_imm_mux_o, 
    output logic mult_sel_subword_o, 
    output logic [1:0] mult_signed_mode_o, 
    output logic [1:0] mult_dot_signed_o, 
    input logic [(C_RM - 1):0] frm_i, 
    output logic [(C_FPNEW_FMTBITS - 1):0] fpu_dst_fmt_o, 
    output logic [(C_FPNEW_FMTBITS - 1):0] fpu_src_fmt_o, 
    output logic [(C_FPNEW_IFMTBITS - 1):0] fpu_int_fmt_o, 
    output logic apu_en_o, 
    output logic [(WAPUTYPE - 1):0] apu_type_o, 
    output logic [(APU_WOP_CPU - 1):0] apu_op_o, 
    output logic [1:0] apu_lat_o, 
    output logic [(WAPUTYPE - 1):0] apu_flags_src_o, 
    output logic [2:0] fp_rnd_mode_o, 
    output logic regfile_mem_we_o, 
    output logic regfile_alu_we_o, 
    output logic regfile_alu_we_dec_o, 
    output logic regfile_alu_waddr_sel_o, 
    output logic csr_access_o, 
    output logic csr_status_o, 
    output logic [1:0] csr_op_o, 
    input PrivLvl_t current_priv_lvl_i, 
    output logic data_req_o, 
    output logic data_we_o, 
    output logic prepost_useincr_o, 
    output logic [1:0] data_type_o, 
    output logic [1:0] data_sign_extension_o, 
    output logic [1:0] data_reg_offset_o, 
    output logic data_load_event_o, 
    output logic [5:0] atop_o, 
    output logic [2:0] hwloop_we_o, 
    output logic hwloop_target_mux_sel_o, 
    output logic hwloop_start_mux_sel_o, 
    output logic hwloop_cnt_mux_sel_o, 
    input logic debug_mode_i, 
    input logic debug_wfi_no_sleep_i, 
    output logic [1:0] jump_in_dec_o, 
    output logic [1:0] jump_in_id_o, 
    output logic [1:0] jump_target_mux_sel_o) ;
    wire [7:0] mutsel ; 
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
    mutsel_gen_cv32e40p_decoder mutsel_i (.mutsel(mutsel)) ; 
    mutated wrapped_i (.mutsel(mutsel), .deassert_we_i(deassert_we_i), .data_misaligned_i(data_misaligned_i), .mult_multicycle_i(mult_multicycle_i), .instr_multicycle_o(instr_multicycle_o), .illegal_insn_o(illegal_insn_o), .ebrk_insn_o(ebrk_insn_o), .mret_insn_o(mret_insn_o), .uret_insn_o(uret_insn_o), .dret_insn_o(dret_insn_o), .mret_dec_o(mret_dec_o), .uret_dec_o(uret_dec_o), .dret_dec_o(dret_dec_o), .ecall_insn_o(ecall_insn_o), .pipe_flush_o(pipe_flush_o), 
                .fencei_insn_o(fencei_insn_o), .rega_used_o(rega_used_o), .regb_used_o(regb_used_o), .regc_used_o(regc_used_o), .reg_fp_a_o(reg_fp_a_o), .reg_fp_b_o(reg_fp_b_o), .reg_fp_c_o(reg_fp_c_o), .reg_fp_d_o(reg_fp_d_o), .bmask_a_mux_o(bmask_a_mux_o), .bmask_b_mux_o(bmask_b_mux_o), .alu_bmask_a_mux_sel_o(alu_bmask_a_mux_sel_o), .alu_bmask_b_mux_sel_o(alu_bmask_b_mux_sel_o), .instr_rdata_i(instr_rdata_i), .illegal_c_insn_i(illegal_c_insn_i), .alu_en_o(alu_en_o), 
                .alu_operator_o(alu_operator_o), .alu_op_a_mux_sel_o(alu_op_a_mux_sel_o), .alu_op_b_mux_sel_o(alu_op_b_mux_sel_o), .alu_op_c_mux_sel_o(alu_op_c_mux_sel_o), .alu_vec_mode_o(alu_vec_mode_o), .scalar_replication_o(scalar_replication_o), .scalar_replication_c_o(scalar_replication_c_o), .imm_a_mux_sel_o(imm_a_mux_sel_o), .imm_b_mux_sel_o(imm_b_mux_sel_o), .regc_mux_o(regc_mux_o), .is_clpx_o(is_clpx_o), .is_subrot_o(is_subrot_o), .mult_operator_o(mult_operator_o), .mult_int_en_o(mult_int_en_o), .mult_dot_en_o(mult_dot_en_o), 
                .mult_imm_mux_o(mult_imm_mux_o), .mult_sel_subword_o(mult_sel_subword_o), .mult_signed_mode_o(mult_signed_mode_o), .mult_dot_signed_o(mult_dot_signed_o), .frm_i(frm_i), .fpu_dst_fmt_o(fpu_dst_fmt_o), .fpu_src_fmt_o(fpu_src_fmt_o), .fpu_int_fmt_o(fpu_int_fmt_o), .apu_en_o(apu_en_o), .apu_type_o(apu_type_o), .apu_op_o(apu_op_o), .apu_lat_o(apu_lat_o), .apu_flags_src_o(apu_flags_src_o), .fp_rnd_mode_o(fp_rnd_mode_o), .regfile_mem_we_o(regfile_mem_we_o), 
                .regfile_alu_we_o(regfile_alu_we_o), .regfile_alu_we_dec_o(regfile_alu_we_dec_o), .regfile_alu_waddr_sel_o(regfile_alu_waddr_sel_o), .csr_access_o(csr_access_o), .csr_status_o(csr_status_o), .csr_op_o(csr_op_o), .current_priv_lvl_i(current_priv_lvl_i), .data_req_o(data_req_o), .data_we_o(data_we_o), .prepost_useincr_o(prepost_useincr_o), .data_type_o(data_type_o), .data_sign_extension_o(data_sign_extension_o), .data_reg_offset_o(data_reg_offset_o), .data_load_event_o(data_load_event_o), .atop_o(atop_o), 
                .hwloop_we_o(hwloop_we_o), .hwloop_target_mux_sel_o(hwloop_target_mux_sel_o), .hwloop_start_mux_sel_o(hwloop_start_mux_sel_o), .hwloop_cnt_mux_sel_o(hwloop_cnt_mux_sel_o), .debug_mode_i(debug_mode_i), .debug_wfi_no_sleep_i(debug_wfi_no_sleep_i), .jump_in_dec_o(jump_in_dec_o), .jump_in_id_o(jump_in_id_o), .jump_target_mux_sel_o(jump_target_mux_sel_o)) ; 
endmodule



