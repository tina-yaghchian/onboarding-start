
module tt_um_tina_onboarding (
    input  wire [7:0] ui_in,
    output reg  [7:0] uo_out,
    input  wire [7:0] uio_in,
    output reg  [7:0] uio_out,
    output reg  [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // Mapping used by your cocotb test:
    // ui_in[0] = SCLK
    // ui_in[1] = COPI / MOSI
    // ui_in[2] = nCS (active low)

    reg commit_pending;
    reg [15:0] shift_reg;
    reg [4:0]  bit_count;

    reg [7:0] reg0;
    reg [7:0] reg1;

    reg sclk_d;

    // Hold the 16-bit word including the bit captured on this rising edge
    reg [15:0] word16;

    // Optional: only accept addresses 0x00..0x04
    localparam [6:0] MAX_ADDR = 7'h04;

    always @(posedge clk) begin
        if (!rst_n) begin
            shift_reg <= 16'h0000;
            bit_count <= 5'd0;

            reg0 <= 8'h00;
            reg1 <= 8'h00;

            uo_out  <= 8'h00;
            uio_out <= 8'h00;
            uio_oe  <= 8'hFF;

            sclk_d <= 1'b0;
            word16 <= 16'h0000;

        end else begin
            // Drive uio pins as outputs (matches your test expectations)
            uio_oe <= 8'hFF;

            // If CS is high, reset receiver state for next transaction
            if (ui_in[2]) begin
                bit_count <= 5'd0;
                shift_reg <= 16'h0000;
		commit_pending <= 1'b0;
            end

            // Edge detect in clk domain
            sclk_d <= ui_in[0];

// Rising edge of SCLK while CS low
if (!ui_in[2] && (sclk_d == 1'b0) && (ui_in[0] == 1'b1)) begin
    // Shift in MOSI on SCLK rising edge
    shift_reg <= {shift_reg[14:0], ui_in[1]};

    if (bit_count == 5'd15) begin
        // Capture complete 16-bit word at the end of the transaction
        word16         <= {shift_reg[14:0], ui_in[1]};
        commit_pending <= 1'b1;
        bit_count      <= 5'd0;
    end else begin
        bit_count <= bit_count + 5'd1;
    end
end

            // Outputs reflect registers
            uo_out  <= reg0;
            uio_out <= reg1;

            // Unused inputs (kept for TT interface)
            // ena, uio_in
        end
    end

endmodule

