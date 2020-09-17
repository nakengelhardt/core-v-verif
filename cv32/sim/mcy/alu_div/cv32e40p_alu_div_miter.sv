//
// Copyright 2020 OpenHW Group
// Copyright 2020 Symbiotic EDA
//
// Licensed under the Solderpad Hardware License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://solderpad.org/licenses/
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
//
module miter #(parameter C_WIDTH = 32, parameter C_LOG_WIDTH = 6) (
    input logic Clk_CI,
    input logic Rst_RBI,
    // input IF
    input logic [(C_WIDTH - 1):0] OpA_DI,
    input logic [(C_WIDTH - 1):0] OpB_DI,
    input logic [(C_LOG_WIDTH - 1):0] OpBShift_DI,
    input logic OpBIsZero_SI,
    //
    input logic OpBSign_SI,  // gate this to 0 in case of unsigned ops
    input logic [1:0] OpCode_SI,  // 0: udiv, 2: urem, 1: div, 3: rem
    // handshake
    input logic InVld_SI,
    // output IF
    input logic OutRdy_SI) ;
    logic uut_OutVld_SO ;
    logic ref_OutVld_SO ;
    logic [(C_WIDTH - 1):0] ref_Res_DO ;
    logic [(C_WIDTH - 1):0] uut_Res_DO ;
    if ((C_WIDTH != 32))
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with C_WIDTH = 32 but %0d was passed",C_WIDTH) ;
    if ((C_LOG_WIDTH != 6))
        $error ("Changing parameters for mutated modules not supported: mutated module was generated with C_LOG_WIDTH = 6 but %0d was passed",C_LOG_WIDTH) ;
    cv32e40p_alu_div ref_i (.mutsel(1'b0), .Clk_CI(Clk_CI), .Rst_RBI(Rst_RBI), .OpA_DI(OpA_DI), .OpB_DI(OpB_DI), .OpBShift_DI(OpBShift_DI), .OpBIsZero_SI(OpBIsZero_SI), .OpBSign_SI(OpBSign_SI), .OpCode_SI(OpCode_SI), .InVld_SI(InVld_SI), .OutRdy_SI(OutRdy_SI), .OutVld_SO(ref_OutVld_SO), .Res_DO(ref_Res_DO)) ;
    cv32e40p_alu_div uut_i (.mutsel(1'b1), .Clk_CI(Clk_CI), .Rst_RBI(Rst_RBI), .OpA_DI(OpA_DI), .OpB_DI(OpB_DI), .OpBShift_DI(OpBShift_DI), .OpBIsZero_SI(OpBIsZero_SI), .OpBSign_SI(OpBSign_SI), .OpCode_SI(OpCode_SI), .InVld_SI(InVld_SI), .OutRdy_SI(OutRdy_SI), .OutVld_SO(uut_OutVld_SO), .Res_DO(uut_Res_DO)) ;

    logic init_cycle = 1'b1;
    always @ (posedge clk) begin
      init_cycle = 1'b0;
    end
    always @(*) begin
      if (init_cycle) assume (!Rst_RBI);
      if (Rst_RBI) begin
        assume (OutRdy_SI);
        assert ((ref_OutVld_SO == uut_OutVld_SO)) ;
        if (ref_OutVld_SO) begin
          assert ((ref_Res_DO == uut_Res_DO)) ;
        end
      end
    end

///////////////////////////////////////////////////////////////////////////////
// assertions
///////////////////////////////////////////////////////////////////////////////
// serDiv
endmodule
