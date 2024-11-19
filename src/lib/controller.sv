module controller(input logic clk, reset,
    // Decode stage control signals
    input logic [6:0] opD,
    input logic [2:0] funct3D,
    input logic funct7b5D,
    output logic [2:0] ImmSrcD,
    // Execute stage control signals
    input logic FlushE,
    input logic ZeroE,
    output logic PCSrcE, // for datapath and Hazard Unit
    output logic [2:0] ALUControlE,
    output logic ALUSrcAE,
    output logic ALUSrcBE, // for lui
    output logic ResultSrcEb0, // for Hazard Unit
    // Memory stage control signals
    output logic MemWriteM,
    output logic RegWriteM, // for Hazard Unit

    // Writeback stage control signals
    output logic RegWriteW, // for datapath and Hazard Unit
    output logic [1:0] ResultSrcW);
    // pipelined control signals
    logic RegWriteD, RegWriteE;
    logic [1:0] ResultSrcD, ResultSrcE, ResultSrcM;
    logic MemWriteD, MemWriteE;
    logic JumpD, JumpE;
    logic BranchD, BranchE;
    logic [1:0] ALUOpD;
    logic [2:0] ALUControlD;
    logic ALUSrcAD;
    logic ALUSrcBD; // for lui

    // Decode stage logic
    maindec md(opD, ResultSrcD, MemWriteD, BranchD,
    ALUSrcAD, ALUSrcBD, RegWriteD, JumpD, ImmSrcD, ALUOpD);
    aludec ad(opD[5], funct3D, funct7b5D, ALUOpD, ALUControlD);

    // Execute stage pipeline control register and logic
    floprc #(11) controlregE(clk, reset, FlushE,
    {RegWriteD, ResultSrcD, MemWriteD, JumpD, BranchD,
    ALUControlD, ALUSrcAD, ALUSrcBD}, {RegWriteE, ResultSrcE, MemWriteE, JumpE, BranchE,
    ALUControlE, ALUSrcAE, ALUSrcBE});
    assign PCSrcE = (BranchE & ZeroE) | JumpE;
    assign ResultSrcEb0 = ResultSrcE[0];

    // Memory stage pipeline control register
    flopr #(4) controlregM(clk, reset,
    {RegWriteE, ResultSrcE, MemWriteE},
    {RegWriteM, ResultSrcM, MemWriteM});

    // Writeback stage pipeline control register
    flopr #(3) controlregW(clk, reset,
    {RegWriteM, ResultSrcM},
    {RegWriteW, ResultSrcW});
endmodule


module maindec(input logic [6:0] op,
    output logic [1:0] ResultSrc,
    output logic MemWrite,
    output logic Branch,
    output logic ALUSrcA,
    output logic ALUSrcB,
    output logic RegWrite, Jump,
    output logic [2:0] ImmSrc,
    output logic [1:0] ALUOp);
    logic [12:0] controls;
    assign {RegWrite, ImmSrc, ALUSrcA, ALUSrcB, MemWrite,
    ResultSrc, Branch, ALUOp, Jump} = controls;
    always_comb
    case(op)
    // RegWrite_ImmSrc_ALUSrcA_ALUSrcB_MemWrite_ResultSrc_Branch_ALUOp_Jump
    7'b0000011: controls = 13'b1_000_0_1_0_01_0_00_0; // lw
    7'b0100011: controls = 13'b0_001_0_1_1_00_0_00_0; // sw
    7'b0110011: controls = 13'b1_xxx_0_0_0_00_0_10_0; // R-type
    7'b1100011: controls = 13'b0_010_0_0_0_00_1_01_0; // beq
    7'b0010011: controls = 13'b1_000_0_1_0_00_0_10_0; // I-type ALU
    7'b1101111: controls = 13'b1_011_0_0_0_10_0_00_1; // jal
    7'b0110111: controls = 13'b1_100_1_1_0_00_0_00_0; // lui
    7'b0000000: controls = 13'b0_000_0_0_0_00_0_00_0; // need valid values
    // at reset
    default: controls = 13'bx_xxx_x_x_x_xx_x_xx_x; // non-implemented
    // instruction
    endcase
endmodule

module aludec(input logic opb5,
    input logic [2:0] funct3,
    input logic funct7b5,
    input logic [1:0] ALUOp,
    output logic [2:0] ALUControl
    );

    logic RtypeSub;
    assign RtypeSub = funct7b5 & opb5; // TRUE for R-type subtract instruction 
    always_comb
        case(ALUOp)
            2'b00: ALUControl = 3'b000; // addition
            2'b01: ALUControl = 3'b001; // subtraction
            default: case(funct3) // R-type or I-type ALU
                        3'b000: if (RtypeSub)
                                    ALUControl = 3'b001; // sub
                        else
                            ALUControl = 3'b000; // add, addi
                        3'b010: ALUControl = 3'b101; // slt, slti
                        3'b100: ALUControl = 3'b100; // xor
                        3'b110: ALUControl = 3'b011; // or, ori
                        3'b111: ALUControl = 3'b010; // and, andi
                        default: ALUControl = 3'bxxx; // ???
                    endcase
        endcase
endmodule
