module ProgramCounter(
    input clk,
    input reset,
    input control,
    output reg [3:0] pc
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc <= 4'b0000;
        else if (control)
            pc <= pc + 1;
    end
endmodule


module InstructionMemory(
    input [3:0] addr,
    input control,
    output reg [31:0] instruction
);
    always @(*) begin
        if (!control)
            instruction = 32'b0; // NOOP
        else begin
            case (addr)
                4'd0: instruction = {6'b110000, 5'd0, 5'd10, 16'd10}; // ADDI R10, R0, 10
                4'd1: instruction = {6'b110000, 5'd0, 5'd15, 16'd15}; // ADDI R15, R0, 15
                4'd2: instruction = {6'b010000, 5'd10, 5'd15, 5'd25, 11'b0}; // ADD R25, R10, R15
                4'd3: instruction = {6'b111000, 5'd25, 5'd20, 16'd5}; // SUBI R20, R25, 5
                4'd4: instruction = {6'b110000, 5'd0, 5'd5, 16'd2}; // ADDI R5, R0, 2
                4'd5: instruction = {6'b100000, 5'd25, 5'd5, 5'd30, 11'b0}; // SHIFTL R30, R25, R5
                default: instruction = 32'b0;
            endcase
        end
    end
endmodule


module ALU(
    input [2:0] ALUop,
    input [31:0] A, B,
    input [15:0] imm,
    output reg [31:0] Result
);
    always @(*) begin
        case(ALUop)
            3'b000, 3'b001: Result = 32'b0; // NOOP
            3'b010: Result = A + B;         // ADD
            3'b011: Result = A - B;         // SUB
            3'b100: Result = A << B;        // SHIFTL
            3'b101: Result = A >> B;        // SHIFTR
            3'b110: Result = A + imm;       // ADDI
            3'b111: Result = A - imm;       // SUBI
            default: Result = 32'b0;
        endcase
    end
endmodule


module RegisterFile(
    input clk,
    input [4:0] readReg1, readReg2, writeReg,
    input [31:0] writeData,
    input regWrite,
    output [31:0] readData1, readData2
);
    reg [31:0] registers[0:31];

    assign readData1 = registers[readReg1];
    assign readData2 = registers[readReg2];

    always @(posedge clk) begin
        if (regWrite)
            registers[writeReg] <= writeData;
    end
endmodule


module InstructionDecoder(
    input [31:0] instruction,
    output reg [2:0] ALUop,
    output reg [4:0] rs, rt, rd,
    output reg [15:0] imm,
    output reg isImmediate
);
    always @(*) begin
        rs = instruction[25:21];
        rt = instruction[20:16];
        rd = instruction[15:11];
        imm = instruction[15:0];
        case (instruction[31:26])
            6'b000000: ALUop = 3'b000; // NOOP
            6'b010000: begin ALUop = 3'b010; isImmediate = 0; end // ADD
            6'b011000: begin ALUop = 3'b011; isImmediate = 0; end // SUB
            6'b100000: begin ALUop = 3'b100; isImmediate = 0; end // SHIFTL
            6'b101000: begin ALUop = 3'b101; isImmediate = 0; end // SHIFTR
            6'b110000: begin ALUop = 3'b110; isImmediate = 1; end // ADDI
            6'b111000: begin ALUop = 3'b111; isImmediate = 1; end // SUBI
            default: begin ALUop = 3'b000; isImmediate = 0; end
        endcase
    end
endmodule


module TopModule(
    input clk,
    input control, // button
    input reset,   // button
    output [6:0] seg,
    output [3:0] an,
    output [31:0] Result
);
    wire [3:0] pc;
    wire [31:0] instruction;
    wire [4:0] rs, rt, rd;
    wire [15:0] imm;
    wire [31:0] A, B;
    wire [2:0] ALUop;
    wire isImmediate;

    wire [31:0] alu_result;

    ProgramCounter pc_module(clk, reset, control, pc);
    InstructionMemory imem(pc, control, instruction);
    InstructionDecoder decoder(instruction, ALUop, rs, rt, rd, imm, isImmediate);
    RegisterFile rf(clk, rs, rt, rd, alu_result, 1'b1, A, B);
    ALU alu(ALUop, A, B, imm, alu_result);
    DisplayController display(clk, Result, an, seg);

    assign Result = alu_result;
endmodule


module HexDigitTo7Segment(
    input [3:0] hex,
    output reg [6:0] seg
);
    always @(*) begin
        case (hex)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111; // blank
        endcase
    end
endmodule


module DisplayController(
    input clk,
    input [31:0] value,
    output reg [3:0] an,
    output reg [6:0] seg
);
    reg [1:0] sel = 0;
    wire [3:0] digit;
    wire [6:0] seg_temp;

    assign digit = value >> (sel * 4);

    HexDigitTo7Segment digit_to_seg(.hex(digit), .seg(seg_temp));

    always @(posedge clk) begin
        sel <= sel + 1;
        case (sel)
            2'd0: an <= 4'b1110;
            2'd1: an <= 4'b1101;
            2'd2: an <= 4'b1011;
            2'd3: an <= 4'b0111;
        endcase
        seg <= seg_temp;
    end
endmodule

