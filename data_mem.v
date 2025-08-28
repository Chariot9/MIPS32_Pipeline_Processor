module data_mem(
input clk,
input [31:0] addr, 
input [31:0] write_data, 
input mem_write, 
input mem_read, 
output reg [31:0] read_data 
);
reg [31:0] mem [0:255]; // 256-word memory
// Synchronous write
 always @(posedge clk) begin
if (mem_write) begin
mem[addr] <= write_data;
  $display("[DMEM] Time=%0t: MEM[%0d] <= %0d", $time, addr, write_data);
end
end
// Asynchronous read
always @(*) begin
if (mem_read)
read_data = mem[addr];
else
 read_data = 32'b0;
end
endmodule
