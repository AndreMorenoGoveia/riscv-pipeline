module riscv(
    input logic clk, reset,
    output logic [31:0] PCF,
    input logic [31:0] InstrF,
    output logic MemWriteM,
    output logic [31:0] ALUResultM, WriteDataM,
    input logic [31:0] ReadDataM
    );

    logic [6:0] opD;
    logic [2:0] funct3D;
    logic funct7b5D;
    logic [2:0] ImmSrcD;
    logic ZeroE;
    logic PCSrcE;
    logic [2:0] ALUControlE;
    logic ALUSrcAE, ALUSrcBE;
    logic ResultSrcEb0;
    logic RegWriteM;
    logic [1:0] ResultSrcW;
    logic RegWriteW;
    logic [1:0] ForwardAE, ForwardBE;
    logic StallF, StallD, FlushD, FlushE;
    logic [4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW;

    controller c(clk, reset,
                opD, funct3D, funct7b5D, ImmSrcD,
                FlushE, ZeroE, PCSrcE, ALUControlE, ALUSrcAE, ALUSrcBE,
                ResultSrcEb0,
                MemWriteM, RegWriteM,
                RegWriteW, ResultSrcW);

    datapath dp(clk, reset,
                StallF, PCF, InstrF,
                opD, funct3D, funct7b5D, StallD, FlushD, ImmSrcD, FlushE, ForwardAE, ForwardBE, PCSrcE, ALUControlE,
                ALUSrcAE, ALUSrcBE, ZeroE,
                MemWriteM, WriteDataM, ALUResultM, ReadDataM,
                RegWriteW, ResultSrcW,
                Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW);

    hazard hu(Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW,
                PCSrcE, ResultSrcEb0, RegWriteM, RegWriteW,
                ForwardAE, ForwardBE, StallF, StallD, FlushD, FlushE);
endmodule