module cv32e40p_decoder import cv32e40p_pkg::*; import cv32e40p_apu_core_pkg::*;
#(
  parameter PULP_XPULP        = 1,              // PULP ISA Extension (including PULP specific CSRs and hardware loop, excluding p.elw)
  parameter PULP_CLUSTER      =  0,
  parameter A_EXTENSION       = 0,
  parameter FPU               = 0,
  parameter FP_DIVSQRT        = 0,
  parameter PULP_SECURE       = 0,
  parameter USE_PMP           = 0,
  parameter SHARED_FP         = 0,
  parameter SHARED_DSP_MULT   = 0,
  parameter SHARED_INT_MULT   = 0,
  parameter SHARED_INT_DIV    = 0,
  parameter SHARED_FP_DIVSQRT = 0,
  parameter WAPUTYPE          = 0,
  parameter APU_WOP_CPU       = 6,
  parameter DEBUG_TRIGGER_EN  = 1
)
(
  // singals running to/from controller
  input  logic        deassert_we_i,           // deassert we, we are stalled or not active
  input  logic        data_misaligned_i,       // misaligned data load/store in progress
  input  logic        mult_multicycle_i,       // multiplier taking multiple cycles, using op c as storage
  output logic        instr_multicycle_o,      // true when multiple cycles are decoded

  output logic        illegal_insn_o,          // illegal instruction encountered
  output logic        ebrk_insn_o,             // trap instruction encountered

  output logic        mret_insn_o,             // return from exception instruction encountered (M)
  output logic        uret_insn_o,             // return from exception instruction encountered (S)
  output logic        dret_insn_o,             // return from debug (M)

  output logic        mret_dec_o,              // return from exception instruction encountered (M) without deassert
  output logic        uret_dec_o,              // return from exception instruction encountered (S) without deassert
  output logic        dret_dec_o,              // return from debug (M) without deassert

  output logic        ecall_insn_o,            // environment call (syscall) instruction encountered
  output logic        pipe_flush_o,            // pipeline flush is requested

  output logic        fencei_insn_o,           // fence.i instruction

  output logic        rega_used_o,             // rs1 is used by current instruction
  output logic        regb_used_o,             // rs2 is used by current instruction
  output logic        regc_used_o,             // rs3 is used by current instruction

  output logic        reg_fp_a_o,              // fp reg a is used
  output logic        reg_fp_b_o,              // fp reg b is used
  output logic        reg_fp_c_o,              // fp reg c is used
  output logic        reg_fp_d_o,              // fp reg d is used

  output logic [ 0:0] bmask_a_mux_o,           // bit manipulation mask a mux
  output logic [ 1:0] bmask_b_mux_o,           // bit manipulation mask b mux
  output logic        alu_bmask_a_mux_sel_o,   // bit manipulation mask a mux (reg or imm)
  output logic        alu_bmask_b_mux_sel_o,   // bit manipulation mask b mux (reg or imm)

  // from IF/ID pipeline
  input  logic [31:0] instr_rdata_i,           // instruction read from instr memory/cache
  input  logic        illegal_c_insn_i,        // compressed instruction decode failed

  // ALU signals
  output logic        alu_en_o,                // ALU enable
  output logic [ALU_OP_WIDTH-1:0] alu_operator_o, // ALU operation selection
  output logic [2:0]  alu_op_a_mux_sel_o,      // operand a selection: reg value, PC, immediate or zero
  output logic [2:0]  alu_op_b_mux_sel_o,      // operand b selection: reg value or immediate
  output logic [1:0]  alu_op_c_mux_sel_o,      // operand c selection: reg value or jump target
  output logic [1:0]  alu_vec_mode_o,          // selects between 32 bit, 16 bit and 8 bit vectorial modes
  output logic        scalar_replication_o,    // scalar replication enable
  output logic        scalar_replication_c_o,  // scalar replication enable for operand C
  output logic [0:0]  imm_a_mux_sel_o,         // immediate selection for operand a
  output logic [3:0]  imm_b_mux_sel_o,         // immediate selection for operand b
  output logic [1:0]  regc_mux_o,              // register c selection: S3, RD or 0
  output logic        is_clpx_o,               // whether the instruction is complex (pulpv3) or not
  output logic        is_subrot_o,

  // MUL related control signals
  output logic [2:0]  mult_operator_o,         // Multiplication operation selection
  output logic        mult_int_en_o,           // perform integer multiplication
  output logic        mult_dot_en_o,           // perform dot multiplication
  output logic [0:0]  mult_imm_mux_o,          // Multiplication immediate mux selector
  output logic        mult_sel_subword_o,      // Select subwords for 16x16 bit of multiplier
  output logic [1:0]  mult_signed_mode_o,      // Multiplication in signed mode
  output logic [1:0]  mult_dot_signed_o,       // Dot product in signed mode

  // FPU
  input  logic [C_RM-1:0]             frm_i,   // Rounding mode from float CSR

  output logic [C_FPNEW_FMTBITS-1:0]  fpu_dst_fmt_o,   // fpu destination format
  output logic [C_FPNEW_FMTBITS-1:0]  fpu_src_fmt_o,   // fpu source format
  output logic [C_FPNEW_IFMTBITS-1:0] fpu_int_fmt_o,   // fpu integer format (for casts)

  // APU
  output logic                apu_en_o,
  output logic [WAPUTYPE-1:0] apu_type_o,
  output logic [APU_WOP_CPU-1:0]  apu_op_o,
  output logic [1:0]          apu_lat_o,
  output logic [WAPUTYPE-1:0] apu_flags_src_o,
  output logic [2:0]          fp_rnd_mode_o,

  // register file related signals
  output logic        regfile_mem_we_o,        // write enable for regfile
  output logic        regfile_alu_we_o,        // write enable for 2nd regfile port
  output logic        regfile_alu_we_dec_o,    // write enable for 2nd regfile port without deassert
  output logic        regfile_alu_waddr_sel_o, // Select register write address for ALU/MUL operations

  // CSR manipulation
  output logic        csr_access_o,            // access to CSR
  output logic        csr_status_o,            // access to xstatus CSR
  output logic [1:0]  csr_op_o,                // operation to perform on CSR
  input  PrivLvl_t    current_priv_lvl_i,      // The current privilege level

  // LD/ST unit signals
  output logic        data_req_o,              // start transaction to data memory
  output logic        data_we_o,               // data memory write enable
  output logic        prepost_useincr_o,       // when not active bypass the alu result for address calculation
  output logic [1:0]  data_type_o,             // data type on data memory: byte, half word or word
  output logic [1:0]  data_sign_extension_o,   // sign extension on read data from data memory / NaN boxing
  output logic [1:0]  data_reg_offset_o,       // offset in byte inside register for stores
  output logic        data_load_event_o,       // data request is in the special event range

  // Atomic memory access
  output  logic [5:0] atop_o,

  // hwloop signals
  output logic [2:0]  hwloop_we_o,             // write enable for hwloop regs
  output logic        hwloop_target_mux_sel_o, // selects immediate for hwloop target
  output logic        hwloop_start_mux_sel_o,  // selects hwloop start address input
  output logic        hwloop_cnt_mux_sel_o,    // selects hwloop counter input

  input  logic        debug_mode_i,            // processor is in debug mode
  input  logic        debug_wfi_no_sleep_i,    // do not let WFI cause sleep

  // jump/branches
  output logic [1:0]  jump_in_dec_o,           // jump_in_id without deassert
  output logic [1:0]  jump_in_id_o,            // jump is being calculated in ALU
  output logic [1:0]  jump_target_mux_sel_o    // jump target selection
);

// if ( PULP_XPULP        != 1 ||
//      PULP_CLUSTER      != 0 ||
//      A_EXTENSION       != 0 ||
//      FPU               != 0 ||
//      FP_DIVSQRT        != 0 ||
//      PULP_SECURE       != 0 ||
//      USE_PMP           != 0 ||
//      SHARED_FP         != 0 ||
//      SHARED_DSP_MULT   != 0 ||
//      SHARED_INT_MULT   != 0 ||
//      SHARED_INT_DIV    != 0 ||
//      SHARED_FP_DIVSQRT != 0 ||
//      WAPUTYPE          != 0 ||
//      APU_WOP_CPU       != 6 ||
//      DEBUG_TRIGGER_EN  != 1 )
// 	$error("Changing parameters for mutated modules not supported.");

reg [7:0] mutsel = 8'h01;

export "DPI-C" task set_mutidx;
task set_mutidx(input [7:0] idx);
  mutsel = idx;
endtask

mutated decoder_i (
	.mutsel (mutsel),

	.deassert_we_i (deassert_we_i),
	.data_misaligned_i (data_misaligned_i),
	.mult_multicycle_i (mult_multicycle_i),
	.instr_multicycle_o (instr_multicycle_o),
	.illegal_insn_o (illegal_insn_o),
	.ebrk_insn_o (ebrk_insn_o),
	.mret_insn_o (mret_insn_o),
	.uret_insn_o (uret_insn_o),
	.dret_insn_o (dret_insn_o),
	.mret_dec_o (mret_dec_o),
	.uret_dec_o (uret_dec_o),
	.dret_dec_o (dret_dec_o),
	.ecall_insn_o (ecall_insn_o),
	.pipe_flush_o (pipe_flush_o),
	.fencei_insn_o (fencei_insn_o),
	.rega_used_o (rega_used_o),
	.regb_used_o (regb_used_o),
	.regc_used_o (regc_used_o),
	.reg_fp_a_o (reg_fp_a_o),
	.reg_fp_b_o (reg_fp_b_o),
	.reg_fp_c_o (reg_fp_c_o),
	.reg_fp_d_o (reg_fp_d_o),
	.bmask_a_mux_o (bmask_a_mux_o),
	.bmask_b_mux_o (bmask_b_mux_o),
	.alu_bmask_a_mux_sel_o (alu_bmask_a_mux_sel_o),
	.alu_bmask_b_mux_sel_o (alu_bmask_b_mux_sel_o),

	.instr_rdata_i (instr_rdata_i),
	.illegal_c_insn_i (illegal_c_insn_i),
	.alu_en_o (alu_en_o),
	.alu_operator_o (alu_operator_o),
	.alu_op_a_mux_sel_o (alu_op_a_mux_sel_o),
	.alu_op_b_mux_sel_o (alu_op_b_mux_sel_o),
	.alu_op_c_mux_sel_o (alu_op_c_mux_sel_o),
	.alu_vec_mode_o (alu_vec_mode_o),
	.scalar_replication_o (scalar_replication_o),
	.scalar_replication_c_o (scalar_replication_c_o),
	.imm_a_mux_sel_o (imm_a_mux_sel_o),
	.imm_b_mux_sel_o (imm_b_mux_sel_o),
	.regc_mux_o (regc_mux_o),
	.is_clpx_o (is_clpx_o),
	.is_subrot_o (is_subrot_o),
	.mult_operator_o (mult_operator_o),
	.mult_int_en_o (mult_int_en_o),
	.mult_dot_en_o (mult_dot_en_o),
	.mult_imm_mux_o (mult_imm_mux_o),
	.mult_sel_subword_o (mult_sel_subword_o),
	.mult_signed_mode_o (mult_signed_mode_o),
	.mult_dot_signed_o (mult_dot_signed_o),
	.frm_i (frm_i),
	.fpu_dst_fmt_o (fpu_dst_fmt_o),
	.fpu_src_fmt_o (fpu_src_fmt_o),
	.fpu_int_fmt_o (fpu_int_fmt_o),

	// APU
	.apu_en_o (apu_en_o),
	.apu_type_o (apu_type_o),
	.apu_op_o (apu_op_o),
	.apu_lat_o (apu_lat_o),
	.apu_flags_src_o (apu_flags_src_o),
	.fp_rnd_mode_o (fp_rnd_mode_o),

	// register file related signals
	.regfile_mem_we_o (regfile_mem_we_o),        // write enable for regfile
	.regfile_alu_we_o (regfile_alu_we_o),        // write enable for 2nd regfile port
	.regfile_alu_we_dec_o (regfile_alu_we_dec_o),    // write enable for 2nd regfile port without deassert
	.regfile_alu_waddr_sel_o (regfile_alu_waddr_sel_o), // Select register write address for ALU/MUL operations
	// CSR manipulation
	.csr_access_o (csr_access_o),            // access to CSR
	.csr_status_o (csr_status_o),            // access to xstatus CSR
	.csr_op_o (csr_op_o),                // operation to perform on CSR
	.current_priv_lvl_i (current_priv_lvl_i),      // The current privilege level

	// LD/ST unit signals
	.data_req_o (data_req_o),              // start transaction to data memory
	.data_we_o (data_we_o),               // data memory write enable
	.prepost_useincr_o (prepost_useincr_o),       // when not active bypass the alu result for address calculation
	.data_type_o (data_type_o),             // data type on data memory: byte, half word or word
	.data_sign_extension_o (data_sign_extension_o),   // sign extension on read data from data memory / NaN boxing
	.data_reg_offset_o (data_reg_offset_o),       // offset in byte inside register for stores
	.data_load_event_o (data_load_event_o),       // data request is in the special event range

	// Atomic memory access
	.atop_o (atop_o),

	// hwloop signals
	.hwloop_we_o (hwloop_we_o),             // write enable for hwloop regs
	.hwloop_target_mux_sel_o (hwloop_target_mux_sel_o), // selects immediate for hwloop target
	.hwloop_start_mux_sel_o (hwloop_start_mux_sel_o),  // selects hwloop start address input
	.hwloop_cnt_mux_sel_o (hwloop_cnt_mux_sel_o),    // selects hwloop counter input

	.debug_mode_i (debug_mode_i),            // processor is in debug mode
	.debug_wfi_no_sleep_i (debug_wfi_no_sleep_i),    // do not let WFI cause sleep

	// jump/branches
	.jump_in_dec_o (jump_in_dec_o),           // jump_in_id without deassert
	.jump_in_id_o (jump_in_id_o),            // jump is being calculated in ALU
	.jump_target_mux_sel_o (jump_target_mux_sel_o)    // jump target selection
);

endmodule