module alu (
    input wire [31:0] A,
    input wire [31:0] B,
    input wire [1:0] opcode,
    output reg [31:0] result
);

    always @(*) begin
        case (opcode)
            2'b00: result = A + B;          // ADD
            2'b01: result = A - B;          // SUB
            2'b10: result = A << B;         // SHIFTL
            2'b11: result = A >> B;         // SHIFTR
            default: result = 32'b0;
        endcase
    end
endmodule

module project4 (
    input wire clk,
    input wire WE3,
    input wire [4:0] A1, A2, A3,
    input wire [31:0] WD3,
    output wire [31:0] RD1, RD2
);
    reg [31:0] registers [31:0];

    // Read operations (combinational)
    assign RD1 = registers[A1];
    assign RD2 = registers[A2];

    // Write operation (synchronous)
    always @(posedge clk) begin
        if (WE3) begin
            registers[A3] <= WD3;
        end
    end
endmodule
