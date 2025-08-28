module alu(
input [31:0] a, b, 
input [5:0] func, 
output reg [31:0] result 
);
always @(*) begin
case (func)
// R-type operations
6'b100000: result = a + b; // ADD
6'b100010: result = a - b; // SUB
6'b100100: result = a & b; // AND
6'b100101: result = a | b; // OR
6'b101010: result = (a < b) ? 1 : 0; // SLT
6'b000010: result = a * b; // MUL 
// I-type operations using opcode as ALU control
6'b001000: result = a + b; // ADDI
6'b001100: result = a & b; // ANDI
6'b001101: result = a | b; // ORI
default: result = 32'h00000000; // Default: 0
endcase
end
endmodule
