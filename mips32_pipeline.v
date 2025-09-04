module mips32_pipeline(
    input  wire clk,
    input  wire reset
);
    // IF stage
    reg [31:0] PC; 
    wire [31:0] instruction;
    wire [31:0] IF_ID_IR, IF_ID_NPC;   
    reg  [31:0] IF_ID_IR_reg, IF_ID_NPC_reg;
  reg branch_taken;
    reg [31:0] branch_target;

    instr_mem imem (.addr(PC), .instr(instruction));  


    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC <= 0;
            IF_ID_IR_reg <= 0;
            IF_ID_NPC_reg <= 0;
        end else begin
            if (branch_taken) begin
                // Branch taken: flush IF stage
                PC <= branch_target;
                IF_ID_IR_reg <= 0;
                IF_ID_NPC_reg <= 0;
            end else begin
                IF_ID_IR_reg <= instruction;   
                IF_ID_NPC_reg <= PC + 1;       
                PC <= PC + 1;                  
            end
             end
          end

    assign IF_ID_IR = IF_ID_IR_reg;
    assign IF_ID_NPC = IF_ID_NPC_reg;

    wire [31:0] regfile_rs_data, regfile_rt_data;

  
    wire [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;
    wire [2:0]  MEM_WB_type;
    wire [4:0]  MEM_WB_rd;
    wire        MEM_WB_reg_write;



    // Instantiate register file
    reg_file regfile (
        .clk(clk),
        .rs(IF_ID_IR[25:21]),
        .rt(IF_ID_IR[20:16]),
        .rd(MEM_WB_rd),
        .write_data(write_back_data),
        .reg_write(MEM_WB_reg_write),
        .rs_data(regfile_rs_data),
        .rt_data(regfile_rt_data)
    );

    // ---------------- ID/EX stage ----------------
    reg [31:0] ID_EX_IR_reg, ID_EX_NPC_reg, ID_EX_A_reg, ID_EX_B_reg, ID_EX_Imm_reg;
    reg [2:0]  ID_EX_type_reg;
    reg        ID_EX_reg_write_reg;
    reg [4:0]  ID_EX_dest_reg; 

    wire [31:0] sign_ext_imm = {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]}; // Sign-extend immediate

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ID_EX_IR_reg   <= 0;
            ID_EX_NPC_reg  <= 0;
            ID_EX_A_reg    <= 0;
            ID_EX_B_reg    <= 0;
            ID_EX_Imm_reg  <= 0;
            ID_EX_type_reg <= 3'b101;
            ID_EX_reg_write_reg <= 1'b0;
            ID_EX_dest_reg <= 5'b0;
        end else begin
            if (branch_taken) begin
                // Flush stage on branch
                ID_EX_IR_reg   <= 0;
                ID_EX_NPC_reg  <= 0;
                ID_EX_A_reg    <= 0;
                ID_EX_B_reg    <= 0;
                ID_EX_Imm_reg  <= 0;
                ID_EX_type_reg <= 3'b101;
                ID_EX_reg_write_reg <= 1'b0;
                ID_EX_dest_reg <= 5'b0;
            end else begin
                ID_EX_IR_reg   <= IF_ID_IR;
                ID_EX_NPC_reg  <= IF_ID_NPC;
                ID_EX_A_reg    <= regfile_rs_data;
                ID_EX_B_reg    <= regfile_rt_data;
                ID_EX_Imm_reg  <= sign_ext_imm;

                ID_EX_reg_write_reg <= 1'b0;
                ID_EX_dest_reg <= 5'b0;

                case (IF_ID_IR[31:26])
                    6'b000000: begin // R-type
                        ID_EX_type_reg <= 3'b000;
                        ID_EX_reg_write_reg <= 1'b1;
                        ID_EX_dest_reg <= IF_ID_IR[15:11]; // rd
                    end
                    6'b001000, 6'b001100, 6'b001101: begin // I-type ALU
                        ID_EX_type_reg <= 3'b001;
                        ID_EX_reg_write_reg <= 1'b1;
                        ID_EX_dest_reg <= IF_ID_IR[20:16]; // rt
                    end
                    6'b100011: begin // LOAD
                        ID_EX_type_reg <= 3'b010;
                        ID_EX_reg_write_reg <= 1'b1;
                        ID_EX_dest_reg <= IF_ID_IR[20:16];
                    end
                    6'b101011: begin // STORE
                        ID_EX_type_reg <= 3'b011;
                        ID_EX_reg_write_reg <= 1'b0;
                    end
                    6'b000100: begin // BEQ
                        ID_EX_type_reg <= 3'b100;
                        ID_EX_reg_write_reg <= 1'b0;
                    end
                    6'b111111: begin // HLT
                        ID_EX_type_reg <= 3'b101;
                        ID_EX_reg_write_reg <= 1'b0;
                    end
                    default: begin
                        ID_EX_type_reg <= 3'b101;
                        ID_EX_reg_write_reg <= 1'b0;
                    end
                endcase
                  end
              end
                end

    // ID/EX outputs
    wire [31:0] ID_EX_IR  = ID_EX_IR_reg;
    wire [31:0] ID_EX_NPC = ID_EX_NPC_reg;
    wire [31:0] ID_EX_A   = ID_EX_A_reg;
    wire [31:0] ID_EX_B   = ID_EX_B_reg;
    wire [31:0] ID_EX_Imm = ID_EX_Imm_reg;
    wire [2:0]  ID_EX_type= ID_EX_type_reg;
    wire        ID_EX_reg_write = ID_EX_reg_write_reg;
    wire [4:0]  ID_EX_dest = ID_EX_dest_reg;

    // Branch logic for BEQ
    always @(*) begin
        if (ID_EX_type == 3'b100) begin
            branch_taken  = (ID_EX_IR[31:26] == 6'b000100 && ID_EX_A == ID_EX_B);
            branch_target = ID_EX_NPC + ID_EX_Imm;
        end else begin
            branch_taken  = 1'b0;
            branch_target = PC + 1;
        end
    end

    // ---------------- EX stage ----------------
    wire [5:0] alu_ctrl = (ID_EX_type == 3'b000) ? ID_EX_IR[5:0] : ID_EX_IR[31:26]; // ALU control
    wire [31:0] alu_in_b = (ID_EX_type == 3'b001 || ID_EX_type == 3'b010) ? ID_EX_Imm : ID_EX_B;
    wire [31:0] alu_result;

    alu main_alu (.a(ID_EX_A), .b(alu_in_b), .func(alu_ctrl), .result(alu_result));

    // EX/MEM pipeline registers
    reg [31:0] EX_MEM_IR_reg, EX_MEM_ALUOut_reg, EX_MEM_B_reg;
    reg [2:0]  EX_MEM_type_reg;
    reg        EX_MEM_reg_write_reg;
    reg [4:0]  EX_MEM_dest_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            EX_MEM_IR_reg <= 0;
            EX_MEM_ALUOut_reg <= 0;
            EX_MEM_B_reg <= 0;
            EX_MEM_type_reg <= 3'b101;
            EX_MEM_reg_write_reg <= 1'b0;
            EX_MEM_dest_reg <= 5'b0;
        end else begin
            EX_MEM_IR_reg <= ID_EX_IR;
            EX_MEM_ALUOut_reg <= alu_result;
            EX_MEM_B_reg <= ID_EX_B;
            EX_MEM_type_reg <= ID_EX_type;
            EX_MEM_reg_write_reg <= ID_EX_reg_write;
            EX_MEM_dest_reg <= ID_EX_dest;
        end
    end

    wire [31:0] EX_MEM_IR = EX_MEM_IR_reg;
    wire [31:0] EX_MEM_ALUOut = EX_MEM_ALUOut_reg;
    wire [31:0] EX_MEM_B = EX_MEM_B_reg;
    wire [2:0]  EX_MEM_type = EX_MEM_type_reg;
    wire        EX_MEM_reg_write = EX_MEM_reg_write_reg;
    wire [4:0]  EX_MEM_dest = EX_MEM_dest_reg;

    // ---------------- MEM stage ----------------
    wire [31:0] dmem_read_data;

    data_mem dmem (
        .addr(EX_MEM_ALUOut),
        .write_data(EX_MEM_B),
        .mem_write(EX_MEM_type == 3'b011),
        .mem_read (EX_MEM_type == 3'b010),
        .clk(clk),
        .read_data(dmem_read_data)
    );

    // MEM/WB pipeline registers
    reg [31:0] MEM_WB_IR_reg, MEM_WB_ALUOut_reg, MEM_WB_LMD_reg;
    reg [2:0]  MEM_WB_type_reg;
    reg        MEM_WB_reg_write_reg;
    reg [4:0]  MEM_WB_dest_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            MEM_WB_IR_reg <= 0;
            MEM_WB_ALUOut_reg <= 0;
            MEM_WB_LMD_reg <= 0;
            MEM_WB_type_reg <= 3'b101;
            MEM_WB_reg_write_reg <= 1'b0;
            MEM_WB_dest_reg <= 5'b0;
        end else begin
            MEM_WB_IR_reg <= EX_MEM_IR;
            MEM_WB_ALUOut_reg <= EX_MEM_ALUOut;
            MEM_WB_LMD_reg <= dmem_read_data;
            MEM_WB_type_reg <= EX_MEM_type;
            MEM_WB_reg_write_reg <= EX_MEM_reg_write;
            MEM_WB_dest_reg <= EX_MEM_dest;
        end
    end

    assign MEM_WB_IR = MEM_WB_IR_reg;
    assign MEM_WB_ALUOut = MEM_WB_ALUOut_reg;
    assign MEM_WB_LMD = MEM_WB_LMD_reg;
    assign MEM_WB_type = MEM_WB_type_reg;
    assign MEM_WB_rd = MEM_WB_dest_reg;
    assign MEM_WB_reg_write = MEM_WB_reg_write_reg;

    // ---------------- WB stage ----------------
        // Choose write-back data: ALU or loaded memory
    wire [31:0] write_back_data = (MEM_WB_type == 3'b010) ? MEM_WB_LMD : MEM_WB_ALUOut;
    always @(posedge clk) begin
        if (MEM_WB_reg_write_reg) begin
            $display("[WB] Time=%0t: Writing to R[%0d] value=%0d (type=%b)", $time, MEM_WB_dest_reg, write_back_data, MEM_WB_type_reg);
        end
        // HLT detection
        if (MEM_WB_IR_reg[31:26] == 6'b111111) begin
            $display("HLT encountered. PC=%0d @ time %0t", PC, $time);
            $finish;
        end
    end

endmodule
