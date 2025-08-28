module tb_mips32_pipeline;
    reg clk, reset;
    mips32_pipeline dut (
        .clk(clk),
        .reset(reset)
    );
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    initial begin
        reset = 1;
        #10;
        reset = 0;
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_mips32_pipeline);
    end

    integer i;
    always @(posedge clk) begin
        $display("\nTime=%0t Register File", $time);
        for (i = 0; i < 8; i = i + 1) begin
            $display("R[%0d] = %0d", i, dut.regfile.Regs[i]);
        end
    end
    initial begin
        #500;
        $display("Stopping simulation at time=%0t", $time);
        $finish;
    end

endmodule
