`timescale 1ns / 1ps

module tb_mips32_pipeline;

    reg clk, reset;

    // Instantiate the pipeline (Unit Under Test)
    mips32_pipeline uut (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation: 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Apply reset
    initial begin
        reset = 1;
        #10;
        reset = 0;
    end

    // Generate waveform
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_mips32_pipeline);
    end

    // Display register file contents after simulation
    initial begin
        #500;
        $display("\n--- Register File Contents ---");
        for (integer i = 0; i < 8; i = i + 1) begin
            $display("R[%0d] = %0d", i, uut.regfile.Regs[i]);
        end
        $finish;
    end

endmodule