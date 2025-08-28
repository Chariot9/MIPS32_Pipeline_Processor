
module reg_file(
input clk, 
input [4:0] rs, rt, rd, // Source (rs, rt)  destination (rd) 
input [31:0] write_data, 
input reg_write, 
output [31:0] rs_data, rt_data 
);
reg [31:0] Regs [0:31]; 
integer i;
initial begin
for (i = 0; i < 32; i = i + 1)
Regs[i] = 0;
end
assign rs_data = (rs == 0) ? 0 : Regs[rs];
assign rt_data = (rt == 0) ? 0 : Regs[rt];
always @(posedge clk) begin
if (reg_write && rd != 0) begin 
Regs[rd] <= write_data;
$display("[REGFILE] Time=%0t: Write R[%0d] = %0d", $time, rd, write_data);
end
end
endmodule
