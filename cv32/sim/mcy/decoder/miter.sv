localparam C_RM = 3;
localparam ALU_OP_WIDTH = 7;
localparam C_FPNEW_FMTBITS = 3;
localparam C_FPNEW_IFMTBITS = 2;
localparam WAPUTYPE = 1;
localparam APU_WOP_CPU = 6;


module miter
(
	// singals running to/from controller
	input  logic        deassert_we_i,           // deassert we, we are stalled or not active
	input  logic        data_misaligned_i,       // misaligned data load/store in progress
	input  logic        mult_multicycle_i,       // multiplier taking multiple cycles, using op c as storage
	// from IF/ID pipeline
	input  logic [31:0] instr_rdata_i,           // instruction read from instr memory/cache
	input  logic        illegal_c_insn_i,        // compressed instruction decode failed

	// FPU
	input  logic [C_RM-1:0]             frm_i,   // Rounding mode from float CSR
	input  logic[1:0]   current_priv_lvl_i,      // The current privilege level

	input  logic        debug_mode_i,            // processor is in debug mode
	input  logic        debug_wfi_no_sleep_i    // do not let WFI cause sleep
	);

logic        ref_instr_multicycle_o;      // true when multiple cycles are decoded

logic        ref_illegal_insn_o;          // illegal instruction encountered
logic        ref_ebrk_insn_o;             // trap instruction encountered

logic        ref_mret_insn_o;             // return from exception instruction encountered (M)
logic        ref_uret_insn_o;             // return from exception instruction encountered (S)
logic        ref_dret_insn_o;             // return from debug (M)

logic        ref_mret_dec_o;              // return from exception instruction encountered (M) without deassert
logic        ref_uret_dec_o;              // return from exception instruction encountered (S) without deassert
logic        ref_dret_dec_o;              // return from debug (M) without deassert

logic        ref_ecall_insn_o;            // environment call (syscall) instruction encountered
logic        ref_pipe_flush_o;            // pipeline flush is requested

logic        ref_fencei_insn_o;           // fence.i instruction

logic        ref_rega_used_o;             // rs1 is used by current instruction
logic        ref_regb_used_o;             // rs2 is used by current instruction
logic        ref_regc_used_o;             // rs3 is used by current instruction

logic        ref_reg_fp_a_o;              // fp reg a is used
logic        ref_reg_fp_b_o;              // fp reg b is used
logic        ref_reg_fp_c_o;              // fp reg c is used
logic        ref_reg_fp_d_o;              // fp reg d is used

logic [ 0:0] ref_bmask_a_mux_o;           // bit manipulation mask a mux
logic [ 1:0] ref_bmask_b_mux_o;           // bit manipulation mask b mux
logic        ref_alu_bmask_a_mux_sel_o;   // bit manipulation mask a mux (reg or imm)
logic        ref_alu_bmask_b_mux_sel_o;   // bit manipulation mask b mux (reg or imm)

	// ALU signals
logic        ref_alu_en_o;                // ALU enable
logic [ALU_OP_WIDTH-1:0] ref_alu_operator_o; // ALU operation selection
logic [2:0]  ref_alu_op_a_mux_sel_o;      // operand a selection: reg value, PC, immediate or zero
logic [2:0]  ref_alu_op_b_mux_sel_o;      // operand b selection: reg value or immediate
logic [1:0]  ref_alu_op_c_mux_sel_o;      // operand c selection: reg value or jump target
logic [1:0]  ref_alu_vec_mode_o;          // selects between 32 bit, 16 bit and 8 bit vectorial modes
logic        ref_scalar_replication_o;    // scalar replication enable
logic        ref_scalar_replication_c_o;  // scalar replication enable for operand C
logic [0:0]  ref_imm_a_mux_sel_o;         // immediate selection for operand a
logic [3:0]  ref_imm_b_mux_sel_o;         // immediate selection for operand b
logic [1:0]  ref_regc_mux_o;              // register c selection: S3, RD or 0
logic        ref_is_clpx_o;               // whether the instruction is complex (pulpv3) or not
logic        ref_is_subrot_o;

	// MUL related control signals
logic [2:0]  ref_mult_operator_o;         // Multiplication operation selection
logic        ref_mult_int_en_o;           // perform integer multiplication
logic        ref_mult_dot_en_o;           // perform dot multiplication
logic [0:0]  ref_mult_imm_mux_o;          // Multiplication immediate mux selector
logic        ref_mult_sel_subword_o;      // Select subwords for 16x16 bit of multiplier
logic [1:0]  ref_mult_signed_mode_o;      // Multiplication in signed mode
logic [1:0]  ref_mult_dot_signed_o;       // Dot product in signed mode
logic [C_FPNEW_FMTBITS-1:0]  ref_fpu_dst_fmt_o;   // fpu destination format
logic [C_FPNEW_FMTBITS-1:0]  ref_fpu_src_fmt_o;   // fpu source format
logic [C_FPNEW_IFMTBITS-1:0] ref_fpu_int_fmt_o;   // fpu integer format (for casts)

	// APU
logic                ref_apu_en_o;
logic [WAPUTYPE-1:0] ref_apu_type_o;
logic [APU_WOP_CPU-1:0]  ref_apu_op_o;
logic [1:0]          ref_apu_lat_o;
logic [WAPUTYPE-1:0] ref_apu_flags_src_o;
logic [2:0]          ref_fp_rnd_mode_o;

	// register file related signals
logic        ref_regfile_mem_we_o;        // write enable for regfile
logic        ref_regfile_alu_we_o;        // write enable for 2nd regfile port
logic        ref_regfile_alu_we_dec_o;    // write enable for 2nd regfile port without deassert
logic        ref_regfile_alu_waddr_sel_o; // Select register write address for ALU/MUL operations

	// CSR manipulation
logic        ref_csr_access_o;            // access to CSR
logic        ref_csr_status_o;            // access to xstatus CSR
logic [1:0]  ref_csr_op_o;                // operation to perform on CSR

	// LD/ST unit signals
logic        ref_data_req_o;              // start transaction to data memory
logic        ref_data_we_o;               // data memory write enable
logic        ref_prepost_useincr_o;       // when not active bypass the alu result for address calculation
logic [1:0]  ref_data_type_o;             // data type on data memory: byte, half word or word
logic [1:0]  ref_data_sign_extension_o;   // sign extension on read data from data memory / NaN boxing
logic [1:0]  ref_data_reg_offset_o;       // offset in byte inside register for stores
logic        ref_data_load_event_o;       // data request is in the special event range

	// Atomic memory access
logic [5:0] ref_atop_o;

	// hwloop signals
logic [2:0]  ref_hwloop_we_o;             // write enable for hwloop regs
logic        ref_hwloop_target_mux_sel_o; // selects immediate for hwloop target
logic        ref_hwloop_start_mux_sel_o;  // selects hwloop start address input
logic        ref_hwloop_cnt_mux_sel_o;    // selects hwloop counter input

	// jump/branches
logic [1:0]  ref_jump_in_dec_o;           // jump_in_id without deassert
logic [1:0]  ref_jump_in_id_o;            // jump is being calculated in ALU
logic [1:0]  ref_jump_target_mux_sel_o;    // jump target selection


logic        uut_instr_multicycle_o;      // true when multiple cycles are decoded

logic        uut_illegal_insn_o;          // illegal instruction encountered
logic        uut_ebrk_insn_o;             // trap instruction encountered

logic        uut_mret_insn_o;             // return from exception instruction encountered (M)
logic        uut_uret_insn_o;             // return from exception instruction encountered (S)
logic        uut_dret_insn_o;             // return from debug (M)

logic        uut_mret_dec_o;              // return from exception instruction encountered (M) without deassert
logic        uut_uret_dec_o;              // return from exception instruction encountered (S) without deassert
logic        uut_dret_dec_o;              // return from debug (M) without deassert

logic        uut_ecall_insn_o;            // environment call (syscall) instruction encountered
logic        uut_pipe_flush_o;            // pipeline flush is requested

logic        uut_fencei_insn_o;           // fence.i instruction

logic        uut_rega_used_o;             // rs1 is used by current instruction
logic        uut_regb_used_o;             // rs2 is used by current instruction
logic        uut_regc_used_o;             // rs3 is used by current instruction

logic        uut_reg_fp_a_o;              // fp reg a is used
logic        uut_reg_fp_b_o;              // fp reg b is used
logic        uut_reg_fp_c_o;              // fp reg c is used
logic        uut_reg_fp_d_o;              // fp reg d is used

logic [ 0:0] uut_bmask_a_mux_o;           // bit manipulation mask a mux
logic [ 1:0] uut_bmask_b_mux_o;           // bit manipulation mask b mux
logic        uut_alu_bmask_a_mux_sel_o;   // bit manipulation mask a mux (reg or imm)
logic        uut_alu_bmask_b_mux_sel_o;   // bit manipulation mask b mux (reg or imm)

	// ALU signals
logic        uut_alu_en_o;                // ALU enable
logic [ALU_OP_WIDTH-1:0] uut_alu_operator_o; // ALU operation selection
logic [2:0]  uut_alu_op_a_mux_sel_o;      // operand a selection: reg value, PC, immediate or zero
logic [2:0]  uut_alu_op_b_mux_sel_o;      // operand b selection: reg value or immediate
logic [1:0]  uut_alu_op_c_mux_sel_o;      // operand c selection: reg value or jump target
logic [1:0]  uut_alu_vec_mode_o;          // selects between 32 bit, 16 bit and 8 bit vectorial modes
logic        uut_scalar_replication_o;    // scalar replication enable
logic        uut_scalar_replication_c_o;  // scalar replication enable for operand C
logic [0:0]  uut_imm_a_mux_sel_o;         // immediate selection for operand a
logic [3:0]  uut_imm_b_mux_sel_o;         // immediate selection for operand b
logic [1:0]  uut_regc_mux_o;              // register c selection: S3, RD or 0
logic        uut_is_clpx_o;               // whether the instruction is complex (pulpv3) or not
logic        uut_is_subrot_o;

	// MUL related control signals
logic [2:0]  uut_mult_operator_o;         // Multiplication operation selection
logic        uut_mult_int_en_o;           // perform integer multiplication
logic        uut_mult_dot_en_o;           // perform dot multiplication
logic [0:0]  uut_mult_imm_mux_o;          // Multiplication immediate mux selector
logic        uut_mult_sel_subword_o;      // Select subwords for 16x16 bit of multiplier
logic [1:0]  uut_mult_signed_mode_o;      // Multiplication in signed mode
logic [1:0]  uut_mult_dot_signed_o;       // Dot product in signed mode
logic [C_FPNEW_FMTBITS-1:0]  uut_fpu_dst_fmt_o;   // fpu destination format
logic [C_FPNEW_FMTBITS-1:0]  uut_fpu_src_fmt_o;   // fpu source format
logic [C_FPNEW_IFMTBITS-1:0] uut_fpu_int_fmt_o;   // fpu integer format (for casts)

	// APU
logic                uut_apu_en_o;
logic [WAPUTYPE-1:0] uut_apu_type_o;
logic [APU_WOP_CPU-1:0]  uut_apu_op_o;
logic [1:0]          uut_apu_lat_o;
logic [WAPUTYPE-1:0] uut_apu_flags_src_o;
logic [2:0]          uut_fp_rnd_mode_o;

	// register file related signals
logic        uut_regfile_mem_we_o;        // write enable for regfile
logic        uut_regfile_alu_we_o;        // write enable for 2nd regfile port
logic        uut_regfile_alu_we_dec_o;    // write enable for 2nd regfile port without deassert
logic        uut_regfile_alu_waddr_sel_o; // Select register write address for ALU/MUL operations

	// CSR manipulation
logic        uut_csr_access_o;            // access to CSR
logic        uut_csr_status_o;            // access to xstatus CSR
logic [1:0]  uut_csr_op_o;                // operation to perform on CSR

	// LD/ST unit signals
logic        uut_data_req_o;              // start transaction to data memory
logic        uut_data_we_o;               // data memory write enable
logic        uut_prepost_useincr_o;       // when not active bypass the alu result for address calculation
logic [1:0]  uut_data_type_o;             // data type on data memory: byte, half word or word
logic [1:0]  uut_data_sign_extension_o;   // sign extension on read data from data memory / NaN boxing
logic [1:0]  uut_data_reg_offset_o;       // offset in byte inside register for stores
logic        uut_data_load_event_o;       // data request is in the special event range

	// Atomic memory access
logic [5:0] uut_atop_o;

	// hwloop signals
logic [2:0]  uut_hwloop_we_o;             // write enable for hwloop regs
logic        uut_hwloop_target_mux_sel_o; // selects immediate for hwloop target
logic        uut_hwloop_start_mux_sel_o;  // selects hwloop start address input
logic        uut_hwloop_cnt_mux_sel_o;    // selects hwloop counter input

	// jump/branches
logic [1:0]  uut_jump_in_dec_o;           // jump_in_id without deassert
logic [1:0]  uut_jump_in_id_o;            // jump is being calculated in ALU
logic [1:0]  uut_jump_target_mux_sel_o;    // jump target selection

cv32e40p_decoder ref_i (
	.mutsel (1'b0),

	.deassert_we_i (deassert_we_i),
	.data_misaligned_i (data_misaligned_i),
	.mult_multicycle_i (mult_multicycle_i),
	.instr_multicycle_o (ref_instr_multicycle_o),
	.illegal_insn_o (ref_illegal_insn_o),
	.ebrk_insn_o (ref_ebrk_insn_o),
	.mret_insn_o (ref_mret_insn_o),
	.uret_insn_o (ref_uret_insn_o),
	.dret_insn_o (ref_dret_insn_o),
	.mret_dec_o (ref_mret_dec_o),
	.uret_dec_o (ref_uret_dec_o),
	.dret_dec_o (ref_dret_dec_o),
	.ecall_insn_o (ref_ecall_insn_o),
	.pipe_flush_o (ref_pipe_flush_o),
	.fencei_insn_o (ref_fencei_insn_o),
	.rega_used_o (ref_rega_used_o),
	.regb_used_o (ref_regb_used_o),
	.regc_used_o (ref_regc_used_o),
	.reg_fp_a_o (ref_reg_fp_a_o),
	.reg_fp_b_o (ref_reg_fp_b_o),
	.reg_fp_c_o (ref_reg_fp_c_o),
	.reg_fp_d_o (ref_reg_fp_d_o),
	.bmask_a_mux_o (ref_bmask_a_mux_o),
	.bmask_b_mux_o (ref_bmask_b_mux_o),
	.alu_bmask_a_mux_sel_o (ref_alu_bmask_a_mux_sel_o),
	.alu_bmask_b_mux_sel_o (ref_alu_bmask_b_mux_sel_o),

	.instr_rdata_i (instr_rdata_i),
	.illegal_c_insn_i (illegal_c_insn_i),
	.alu_en_o (ref_alu_en_o),
	.alu_operator_o (ref_alu_operator_o),
	.alu_op_a_mux_sel_o (ref_alu_op_a_mux_sel_o),
	.alu_op_b_mux_sel_o (ref_alu_op_b_mux_sel_o),
	.alu_op_c_mux_sel_o (ref_alu_op_c_mux_sel_o),
	.alu_vec_mode_o (ref_alu_vec_mode_o),
	.scalar_replication_o (ref_scalar_replication_o),
	.scalar_replication_c_o (ref_scalar_replication_c_o),
	.imm_a_mux_sel_o (ref_imm_a_mux_sel_o),
	.imm_b_mux_sel_o (ref_imm_b_mux_sel_o),
	.regc_mux_o (ref_regc_mux_o),
	.is_clpx_o (ref_is_clpx_o),
	.is_subrot_o (ref_is_subrot_o),
	.mult_operator_o (ref_mult_operator_o),
	.mult_int_en_o (ref_mult_int_en_o),
	.mult_dot_en_o (ref_mult_dot_en_o),
	.mult_imm_mux_o (ref_mult_imm_mux_o),
	.mult_sel_subword_o (ref_mult_sel_subword_o),
	.mult_signed_mode_o (ref_mult_signed_mode_o),
	.mult_dot_signed_o (ref_mult_dot_signed_o),
	.frm_i (frm_i),
	.fpu_dst_fmt_o (ref_fpu_dst_fmt_o),
	.fpu_src_fmt_o (ref_fpu_src_fmt_o),
	.fpu_int_fmt_o (ref_fpu_int_fmt_o),

	// APU
	.apu_en_o (ref_apu_en_o),
	.apu_type_o (ref_apu_type_o),
	.apu_op_o (ref_apu_op_o),
	.apu_lat_o (ref_apu_lat_o),
	.apu_flags_src_o (ref_apu_flags_src_o),
	.fp_rnd_mode_o (ref_fp_rnd_mode_o),

	// register file related signals
	.regfile_mem_we_o (ref_regfile_mem_we_o),        // write enable for regfile
	.regfile_alu_we_o (ref_regfile_alu_we_o),        // write enable for 2nd regfile port
	.regfile_alu_we_dec_o (ref_regfile_alu_we_dec_o),    // write enable for 2nd regfile port without deassert
	.regfile_alu_waddr_sel_o (ref_regfile_alu_waddr_sel_o), // Select register write address for ALU/MUL operations
	// CSR manipulation
	.csr_access_o (ref_csr_access_o),            // access to CSR
	.csr_status_o (ref_csr_status_o),            // access to xstatus CSR
	.csr_op_o (ref_csr_op_o),                // operation to perform on CSR
	.current_priv_lvl_i (current_priv_lvl_i),      // The current privilege level

	// LD/ST unit signals
	.data_req_o (ref_data_req_o),              // start transaction to data memory
	.data_we_o (ref_data_we_o),               // data memory write enable
	.prepost_useincr_o (ref_prepost_useincr_o),       // when not active bypass the alu result for address calculation
	.data_type_o (ref_data_type_o),             // data type on data memory: byte, half word or word
	.data_sign_extension_o (ref_data_sign_extension_o),   // sign extension on read data from data memory / NaN boxing
	.data_reg_offset_o (ref_data_reg_offset_o),       // offset in byte inside register for stores
	.data_load_event_o (ref_data_load_event_o),       // data request is in the special event range

	// Atomic memory access
	.atop_o (ref_atop_o),

	// hwloop signals
	.hwloop_we_o (ref_hwloop_we_o),             // write enable for hwloop regs
	.hwloop_target_mux_sel_o (ref_hwloop_target_mux_sel_o), // selects immediate for hwloop target
	.hwloop_start_mux_sel_o (ref_hwloop_start_mux_sel_o),  // selects hwloop start address input
	.hwloop_cnt_mux_sel_o (ref_hwloop_cnt_mux_sel_o),    // selects hwloop counter input

	.debug_mode_i (debug_mode_i),            // processor is in debug mode
	.debug_wfi_no_sleep_i (debug_wfi_no_sleep_i),    // do not let WFI cause sleep

	// jump/branches
	.jump_in_dec_o (ref_jump_in_dec_o),           // jump_in_id without deassert
	.jump_in_id_o (ref_jump_in_id_o),            // jump is being calculated in ALU
	.jump_target_mux_sel_o (ref_jump_target_mux_sel_o)    // jump target selection
);

cv32e40p_decoder uut_i (
	.mutsel (1'b1),

	.deassert_we_i (deassert_we_i),
	.data_misaligned_i (data_misaligned_i),
	.mult_multicycle_i (mult_multicycle_i),
	.instr_multicycle_o (uut_instr_multicycle_o),
	.illegal_insn_o (uut_illegal_insn_o),
	.ebrk_insn_o (uut_ebrk_insn_o),
	.mret_insn_o (uut_mret_insn_o),
	.uret_insn_o (uut_uret_insn_o),
	.dret_insn_o (uut_dret_insn_o),
	.mret_dec_o (uut_mret_dec_o),
	.uret_dec_o (uut_uret_dec_o),
	.dret_dec_o (uut_dret_dec_o),
	.ecall_insn_o (uut_ecall_insn_o),
	.pipe_flush_o (uut_pipe_flush_o),
	.fencei_insn_o (uut_fencei_insn_o),
	.rega_used_o (uut_rega_used_o),
	.regb_used_o (uut_regb_used_o),
	.regc_used_o (uut_regc_used_o),
	.reg_fp_a_o (uut_reg_fp_a_o),
	.reg_fp_b_o (uut_reg_fp_b_o),
	.reg_fp_c_o (uut_reg_fp_c_o),
	.reg_fp_d_o (uut_reg_fp_d_o),
	.bmask_a_mux_o (uut_bmask_a_mux_o),
	.bmask_b_mux_o (uut_bmask_b_mux_o),
	.alu_bmask_a_mux_sel_o (uut_alu_bmask_a_mux_sel_o),
	.alu_bmask_b_mux_sel_o (uut_alu_bmask_b_mux_sel_o),

	.instr_rdata_i (instr_rdata_i),
	.illegal_c_insn_i (illegal_c_insn_i),
	.alu_en_o (uut_alu_en_o),
	.alu_operator_o (uut_alu_operator_o),
	.alu_op_a_mux_sel_o (uut_alu_op_a_mux_sel_o),
	.alu_op_b_mux_sel_o (uut_alu_op_b_mux_sel_o),
	.alu_op_c_mux_sel_o (uut_alu_op_c_mux_sel_o),
	.alu_vec_mode_o (uut_alu_vec_mode_o),
	.scalar_replication_o (uut_scalar_replication_o),
	.scalar_replication_c_o (uut_scalar_replication_c_o),
	.imm_a_mux_sel_o (uut_imm_a_mux_sel_o),
	.imm_b_mux_sel_o (uut_imm_b_mux_sel_o),
	.regc_mux_o (uut_regc_mux_o),
	.is_clpx_o (uut_is_clpx_o),
	.is_subrot_o (uut_is_subrot_o),
	.mult_operator_o (uut_mult_operator_o),
	.mult_int_en_o (uut_mult_int_en_o),
	.mult_dot_en_o (uut_mult_dot_en_o),
	.mult_imm_mux_o (uut_mult_imm_mux_o),
	.mult_sel_subword_o (uut_mult_sel_subword_o),
	.mult_signed_mode_o (uut_mult_signed_mode_o),
	.mult_dot_signed_o (uut_mult_dot_signed_o),
	.frm_i (frm_i),
	.fpu_dst_fmt_o (uut_fpu_dst_fmt_o),
	.fpu_src_fmt_o (uut_fpu_src_fmt_o),
	.fpu_int_fmt_o (uut_fpu_int_fmt_o),

	// APU
	.apu_en_o (uut_apu_en_o),
	.apu_type_o (uut_apu_type_o),
	.apu_op_o (uut_apu_op_o),
	.apu_lat_o (uut_apu_lat_o),
	.apu_flags_src_o (uut_apu_flags_src_o),
	.fp_rnd_mode_o (uut_fp_rnd_mode_o),

	// register file related signals
	.regfile_mem_we_o (uut_regfile_mem_we_o),        // write enable for regfile
	.regfile_alu_we_o (uut_regfile_alu_we_o),        // write enable for 2nd regfile port
	.regfile_alu_we_dec_o (uut_regfile_alu_we_dec_o),    // write enable for 2nd regfile port without deassert
	.regfile_alu_waddr_sel_o (uut_regfile_alu_waddr_sel_o), // Select register write address for ALU/MUL operations
	// CSR manipulation
	.csr_access_o (uut_csr_access_o),            // access to CSR
	.csr_status_o (uut_csr_status_o),            // access to xstatus CSR
	.csr_op_o (uut_csr_op_o),                // operation to perform on CSR
	.current_priv_lvl_i (current_priv_lvl_i),      // The current privilege level

	// LD/ST unit signals
	.data_req_o (uut_data_req_o),              // start transaction to data memory
	.data_we_o (uut_data_we_o),               // data memory write enable
	.prepost_useincr_o (uut_prepost_useincr_o),       // when not active bypass the alu result for address calculation
	.data_type_o (uut_data_type_o),             // data type on data memory: byte, half word or word
	.data_sign_extension_o (uut_data_sign_extension_o),   // sign extension on read data from data memory / NaN boxing
	.data_reg_offset_o (uut_data_reg_offset_o),       // offset in byte inside register for stores
	.data_load_event_o (uut_data_load_event_o),       // data request is in the special event range

	// Atomic memory access
	.atop_o (uut_atop_o),

	// hwloop signals
	.hwloop_we_o (uut_hwloop_we_o),             // write enable for hwloop regs
	.hwloop_target_mux_sel_o (uut_hwloop_target_mux_sel_o), // selects immediate for hwloop target
	.hwloop_start_mux_sel_o (uut_hwloop_start_mux_sel_o),  // selects hwloop start address input
	.hwloop_cnt_mux_sel_o (uut_hwloop_cnt_mux_sel_o),    // selects hwloop counter input

	.debug_mode_i (debug_mode_i),            // processor is in debug mode
	.debug_wfi_no_sleep_i (debug_wfi_no_sleep_i),    // do not let WFI cause sleep

	// jump/branches
	.jump_in_dec_o (uut_jump_in_dec_o),           // jump_in_id without deassert
	.jump_in_id_o (uut_jump_in_id_o),            // jump is being calculated in ALU
	.jump_target_mux_sel_o (uut_jump_target_mux_sel_o)    // jump target selection
);

always @(*) begin
assert(ref_instr_multicycle_o == uut_instr_multicycle_o);      

assert(ref_illegal_insn_o == uut_illegal_insn_o);          
assert(ref_ebrk_insn_o == uut_ebrk_insn_o);             

assert(ref_mret_insn_o == uut_mret_insn_o); 
assert(ref_uret_insn_o == uut_uret_insn_o);
assert(ref_dret_insn_o == uut_dret_insn_o);

assert(ref_mret_dec_o == uut_mret_dec_o);
assert(ref_uret_dec_o == uut_uret_dec_o);
assert(ref_dret_dec_o == uut_dret_dec_o);

assert(ref_ecall_insn_o == uut_ecall_insn_o); 
assert(ref_pipe_flush_o == uut_pipe_flush_o);

assert(ref_fencei_insn_o == uut_fencei_insn_o);

assert(ref_rega_used_o == uut_rega_used_o);
assert(ref_regb_used_o == uut_regb_used_o);
assert(ref_regc_used_o == uut_regc_used_o);

assert(ref_reg_fp_a_o == uut_reg_fp_a_o);
assert(ref_reg_fp_b_o == uut_reg_fp_b_o);
assert(ref_reg_fp_c_o == uut_reg_fp_c_o);
assert(ref_reg_fp_d_o == uut_reg_fp_d_o);

assert(ref_bmask_a_mux_o == uut_bmask_a_mux_o);
assert(ref_bmask_b_mux_o == uut_bmask_b_mux_o);
assert(ref_alu_bmask_a_mux_sel_o == uut_alu_bmask_a_mux_sel_o);
assert(ref_alu_bmask_b_mux_sel_o == uut_alu_bmask_b_mux_sel_o);

assert(ref_alu_en_o == uut_alu_en_o);
assert(ref_alu_operator_o == uut_alu_operator_o);
assert(ref_alu_op_a_mux_sel_o == uut_alu_op_a_mux_sel_o);
assert(ref_alu_op_b_mux_sel_o == uut_alu_op_b_mux_sel_o);
assert(ref_alu_op_c_mux_sel_o == uut_alu_op_c_mux_sel_o);
assert(ref_alu_vec_mode_o == uut_alu_vec_mode_o);
assert(ref_scalar_replication_o == uut_scalar_replication_o);
assert(ref_scalar_replication_c_o == uut_scalar_replication_c_o);
assert(ref_imm_a_mux_sel_o == uut_imm_a_mux_sel_o);
assert(ref_imm_b_mux_sel_o == uut_imm_b_mux_sel_o);
assert(ref_regc_mux_o == uut_regc_mux_o);
assert(ref_is_clpx_o == uut_is_clpx_o);
assert(ref_is_subrot_o == uut_is_subrot_o);

assert(ref_mult_operator_o == uut_mult_operator_o);
assert(ref_mult_int_en_o == uut_mult_int_en_o);
assert(ref_mult_dot_en_o == uut_mult_dot_en_o);
assert(ref_mult_imm_mux_o == uut_mult_imm_mux_o);
assert(ref_mult_sel_subword_o == uut_mult_sel_subword_o);
assert(ref_mult_signed_mode_o == uut_mult_signed_mode_o);
assert(ref_mult_dot_signed_o == uut_mult_dot_signed_o);
assert(ref_fpu_dst_fmt_o == uut_fpu_dst_fmt_o);
assert(ref_fpu_src_fmt_o == uut_fpu_src_fmt_o);
assert(ref_fpu_int_fmt_o == uut_fpu_int_fmt_o);

assert(ref_apu_en_o == uut_apu_en_o);
assert(ref_apu_type_o == uut_apu_type_o);
assert(ref_apu_op_o == uut_apu_op_o);
assert(ref_apu_lat_o == uut_apu_lat_o);
assert(ref_apu_flags_src_o == uut_apu_flags_src_o);
assert(ref_fp_rnd_mode_o == uut_fp_rnd_mode_o);

assert(ref_regfile_mem_we_o == uut_regfile_mem_we_o);
assert(ref_regfile_alu_we_o == uut_regfile_alu_we_o);
assert(ref_regfile_alu_we_dec_o == uut_regfile_alu_we_dec_o);
assert(ref_regfile_alu_waddr_sel_o == uut_regfile_alu_waddr_sel_o);

assert(ref_csr_access_o == uut_csr_access_o);
assert(ref_csr_status_o == uut_csr_status_o);
assert(ref_csr_op_o == uut_csr_op_o);

assert(ref_data_req_o == uut_data_req_o);
assert(ref_data_we_o == uut_data_we_o);
assert(ref_prepost_useincr_o == uut_prepost_useincr_o);
assert(ref_data_type_o == uut_data_type_o);
assert(ref_data_sign_extension_o == uut_data_sign_extension_o);
assert(ref_data_reg_offset_o == uut_data_reg_offset_o);
assert(ref_data_load_event_o == uut_data_load_event_o);

assert(ref_atop_o == uut_atop_o);


assert(ref_hwloop_we_o == uut_hwloop_we_o);
assert(ref_hwloop_target_mux_sel_o == uut_hwloop_target_mux_sel_o);
assert(ref_hwloop_start_mux_sel_o == uut_hwloop_start_mux_sel_o);
assert(ref_hwloop_cnt_mux_sel_o == uut_hwloop_cnt_mux_sel_o);

assert(ref_jump_in_dec_o == uut_jump_in_dec_o);
assert(ref_jump_in_id_o == uut_jump_in_id_o);
assert(ref_jump_target_mux_sel_o == uut_jump_target_mux_sel_o);
end

endmodule
