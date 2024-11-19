module datapath(
    input logic clk, reset,
    // Fetch stage signals
    input logic StallF,
    output logic [31:0] PCF,
    input logic [31:0] InstrF,
    // Decode stage signals
    output logic [6:0] opD,
    output logic [2:0] funct3D,
    output logic funct7b5D,
    input logic StallD, FlushD,
    input logic [2:0] ImmSrcD,
    // Execute stage signals
    input logic FlushE,
    input logic [1:0] ForwardAE, ForwardBE,
    input logic PCSrcE,
    input logic [2:0] ALUControlE,
    input logic ALUSrcAE, // needed for lui
    input logic ALUSrcBE,
    output logic ZeroE,
    // Memory stage signals
    input logic MemWriteM,
    output logic [31:0] WriteDataM, ALUResultM,
    input logic [31:0] ReadDataM,
    // Writeback stage signals
    input logic RegWriteW,
    input logic [1:0] ResultSrcW,
    // Hazard Unit signals
    output logic [4:0] Rs1D, Rs2D, Rs1E, Rs2E,
    output logic [4:0] RdE, RdM, RdW
    );

    // Fetch stage signals
    logic [31:0] PCNextF, PCPlus4F;
    // Decode stage signals
    logic [31:0] InstrD;
    logic [31:0] PCD, PCPlus4D;
    logic [31:0] RD1D, RD2D;
    logic [31:0] ImmExtD;
    logic [4:0] RdD;
    // Execute stage signals
    logic [31:0] RD1E, RD2E;
    logic [31:0] PCE, ImmExtE;
    logic [31:0] SrcAE, SrcBE;
    logic [31:0] SrcAEforward;
    logic [31:0] ALUResultE;
    logic [31:0] WriteDataE;
    logic [31:0] PCPlus4E;
    logic [31:0] PCTargetE;
    // Memory stage signals
    logic [31:0] PCPlus4M;
    // Writeback stage signals
    logic [31:0] ALUResultW;
    logic [31:0] ReadDataW;
    logic [31:0] PCPlus4W;
    logic [31:0] ResultW;

    // Fetch stage pipeline register and logic
    mux2 #(32) pcmux(PCPlus4F, PCTargetE, PCSrcE, PCNextF);
    flopenr #(32) pcreg(clk, reset, ~StallF, PCNextF, PCF);
    adder pcadd(PCF, 32'h4, PCPlus4F);

    // Decode stage pipeline register and logic
    flopenrc #(96) regD(clk, reset, FlushD, ~StallD,
    {InstrF, PCF, PCPlus4F},
    {InstrD, PCD, PCPlus4D});

    assign opD = InstrD[6:0];
    assign funct3D = InstrD[14:12];
    assign funct7b5D = InstrD[30];
    assign Rs1D = InstrD[19:15];
    assign Rs2D = InstrD[24:20];
    assign RdD = InstrD[11:7];

    regfile rf(clk, RegWriteW, Rs1D, Rs2D, RdW, ResultW, RD1D, RD2D);

    extend ext(InstrD[31:7], ImmSrcD, ImmExtD);

    // Execute stage pipeline register and logic
    floprc #(175) regE(clk, reset, FlushE,
    {RD1D, RD2D, PCD, Rs1D, Rs2D, RdD, ImmExtD, PCPlus4D},
    {RD1E, RD2E, PCE, Rs1E, Rs2E, RdE, ImmExtE, PCPlus4E});

    mux3 #(32) faemux(RD1E, ResultW, ALUResultM, ForwardAE, SrcAEforward);

    mux2 #(32) srcamux(SrcAEforward, 32'b0, ALUSrcAE, SrcAE); // for lui

    mux3 #(32) fbemux(RD2E, ResultW, ALUResultM, ForwardBE, WriteDataE);

    mux2 #(32) srcbmux(WriteDataE, ImmExtE, ALUSrcBE, SrcBE);

    alu alu(SrcAE, SrcBE, ALUControlE, ALUResultE, ZeroE);

    adder branchadd(ImmExtE, PCE, PCTargetE);

    // Memory stage pipeline register
    flopr #(101) regM(clk, reset,
    {ALUResultE, WriteDataE, RdE, PCPlus4E},
    {ALUResultM, WriteDataM, RdM, PCPlus4M});

    // Writeback stage pipeline register and logic
    flopr #(101) regW(clk, reset,
    {ALUResultM, ReadDataM, RdM, PCPlus4M},
    {ALUResultW, ReadDataW, RdW, PCPlus4W});

    mux3 #(32) resultmux(ALUResultW, ReadDataW, PCPlus4W, ResultSrcW,
    ResultW);
endmodule


module alu(
    input logic [31:0] a, b,
    input logic [2:0] alucontrol,
    output logic [31:0] result,
    output logic zero
);

    logic [31:0] condinvb, sum;
    logic v; // overflow
    logic isAddSub; // true when is add or subtract operation

    assign condinvb = alucontrol[0] ? ~b : b;

    assign sum = a + condinvb + alucontrol[0];

    assign isAddSub = ~alucontrol[2] & ~alucontrol[1] |
    ~alucontrol[1] & alucontrol[0];

    always_comb
        case (alucontrol)
            3'b000: result = sum; // add
            3'b001: result = sum; // subtract
            3'b010: result = a & b; // and
            3'b011: result = a | b; // or
            3'b100: result = a ^ b; // xor
            3'b101: result = sum[31] ^ v; // slt
            default: result = 32'bx;
        endcase
    
    assign zero = (result == 32'b0);

    assign v = ~(alucontrol[0] ^ a[31] ^ b[31]) & (a[31] ^ sum[31]) & isAddSub;

endmodule