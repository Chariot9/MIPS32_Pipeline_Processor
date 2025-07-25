module alu(input [31:0] a, b, input [5:0] func, output reg [31:0] result);
    always @(*) begin
        case (func)
            6'b000000: result = a + b; // ADD
            6'b000001: result = a - b; // SUB
            6'b000010: result = a & b; // AND
            6'b000011: result = a | b; // OR
            6'b000100: result = (a < b) ? 1 : 0; // SLT
            6'b000101: result = a * b; // MUL
            default: result = 32'h00000000;
        endcase
    end
endmodule