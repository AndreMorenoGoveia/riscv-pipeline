module top(input logic clk, reset,
    output logic [31:0] WriteDataM, DataAdrM,
    output logic MemWriteM);
    logic [31:0] PCF, InstrF, ReadDataM;

    // instantiate processor and memories
    riscv riscv(clk, reset, PCF, InstrF, MemWriteM, DataAdrM,
    WriteDataM, ReadDataM);
    imem imem(PCF, InstrF);
    dmem dmem(clk, MemWriteM, DataAdrM, WriteDataM, ReadDataM);
endmodule

module imem (
    input logic [31:0] a,
    output logic [31:0] rd
);

    logic [31:0] RAM[63:0];

    initial
        $readmemh("example.txt",RAM);
    
    assign rd = RAM[a[31:2]]; // word aligned
endmodule

module dmem(
    input logic clk, we,
    input logic [31:0] a, wd,
    output logic [31:0] rd
);

    logic [31:0] RAM[63:0];

    assign rd = RAM[a[31:2]]; // word aligned

    always_ff @(posedge clk)
        if (we) RAM[a[31:2]] <= wd;
endmodule


