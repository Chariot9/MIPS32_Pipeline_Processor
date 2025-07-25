// mips32_pipeline.v (Top-Level Integration with Branch Support)
module mips32_pipeline(
    input wire clk,
    input wire reset
);
    reg [31:0] PC;
    wire [31:0] instruction;
    wire [31:0] IF_ID_IR, IF_ID_NPC;
    wire [31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm;
    wire [2:0]  ID_EX_type;
    wire [31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;
    wire        EX_MEM_cond;
    wire [2:0]  EX_MEM_type;
    wire [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD;
    wire [2:0]  MEM_WB_type;
    wire [31:0] regfile_rs_data, regfile_rt_data;

    wire [31:0] sign_ext_imm = {{16{IF_ID_IR[15]}}, IF_ID_IR[15:0]};

    // === IF Stage ===
    instr_mem imem (.addr(PC), .instr(instruction));

    reg [31:0] IF_ID_IR_reg, IF_ID_NPC_reg;
    reg branch_taken;
    reg [31:0] branch_target;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC <= 0;
            IF_ID_IR_reg <= 0;
            IF_ID_NPC_reg <= 0;
        end else begin
            if (branch_taken) begin
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

    reg_file regfile (
        .clk(clk),
        .rs(IF_ID_IR[25:21]),
        .rt(IF_ID_IR[20:16]),
        .rd(MEM_WB_IR[15:11]),
        .write_data(MEM_WB_ALUOut),
        .reg_write((MEM_WB_type == 3'b000 || MEM_WB_type == 3'b001)),
        .rs_data(regfile_rs_data),
        .rt_data(regfile_rt_data)
    );

    reg [31:0] ID_EX_IR_reg, ID_EX_NPC_reg, ID_EX_A_reg, ID_EX_B_reg, ID_EX_Imm_reg;
    reg [2:0]  ID_EX_type_reg;

    always @(posedge clk) begin
        if (branch_taken) begin
            ID_EX_IR_reg <= 0;
            ID_EX_type_reg <= 3'b101;
        end else begin
            ID_EX_IR_reg <= IF_ID_IR;
            ID_EX_NPC_reg <= IF_ID_NPC;
            ID_EX_A_reg <= regfile_rs_data;
            ID_EX_B_reg <= regfile_rt_data;
            ID_EX_Imm_reg <= sign_ext_imm;
            case (IF_ID_IR[31:26])
                6'b000000,6'b000001,6'b000010,6'b000011,6'b000100,6'b000101: ID_EX_type_reg <= 3'b000;
                6'b001010,6'b001011,6'b001100: ID_EX_type_reg <= 3'b001;
                6'b001000: ID_EX_type_reg <= 3'b010;
                6'b001001: ID_EX_type_reg <= 3'b011;
                6'b001101,6'b001110: ID_EX_type_reg <= 3'b100;
                6'b111111: ID_EX_type_reg <= 3'b101;
                default: ID_EX_type_reg <= 3'b101;
            endcase
        end
    end

    assign ID_EX_IR = ID_EX_IR_reg;
    assign ID_EX_NPC = ID_EX_NPC_reg;
    assign ID_EX_A = ID_EX_A_reg;
    assign ID_EX_B = ID_EX_B_reg;
    assign ID_EX_Imm = ID_EX_Imm_reg;
    assign ID_EX_type = ID_EX_type_reg;

    alu main_alu (
        .a(ID_EX_A),
        .b(ID_EX_type == 3'b001 ? ID_EX_Imm : ID_EX_B),
        .func(ID_EX_IR[31:26]),
        .result(EX_MEM_ALUOut)
    );

    assign EX_MEM_IR = ID_EX_IR;
    assign EX_MEM_B = ID_EX_B;
    assign EX_MEM_type = ID_EX_type;
    assign EX_MEM_cond = (ID_EX_A == 0);

    always @(*) begin
        if (ID_EX_type == 3'b100) begin
            branch_taken = ((ID_EX_IR[31:26] == 6'b001110) && (ID_EX_A == 0)) ||
                           ((ID_EX_IR[31:26] == 6'b001101) && (ID_EX_A != 0));
            branch_target = ID_EX_NPC + ID_EX_Imm;
        end else begin
            branch_taken = 0;
            branch_target = PC + 1;
        end
    end

    data_mem dmem (
        .addr(EX_MEM_ALUOut),
        .write_data(EX_MEM_B),
        .mem_write(EX_MEM_type == 3'b011),
        .mem_read(EX_MEM_type == 3'b010),
        .clk(clk),
        .read_data(MEM_WB_LMD)
    );

    assign MEM_WB_IR = EX_MEM_IR;
    assign MEM_WB_ALUOut = EX_MEM_ALUOut;
    assign MEM_WB_type = EX_MEM_type;
endmodule
