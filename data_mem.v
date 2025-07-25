module data_mem(
    input clk,
    input [31:0] addr,
    input [31:0] write_data,
    input mem_write,
    input mem_read,
    output reg [31:0] read_data
);
    reg [31:0] mem [0:255];

    always @(posedge clk) begin
        if (mem_write)
            mem[addr] <= write_data;
        if (mem_read)
            read_data <= mem[addr];
    end
endmodule