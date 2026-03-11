`default_nettype none

module tt_um_spi_regs (
    input  wire [7:0] ui_in,
    output reg  [7:0] uo_out,
    input  wire [7:0] uio_in,
    output reg  [7:0] uio_out,
    output reg  [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // SPI on dedicated inputs per info.yaml
    // ui_in[0] = nCS
    // ui_in[1] = COPI / MOSI
    // ui_in[2] = SCLK
    wire spi_sclk  = ui_in[0];
    wire spi_mosi = ui_in[1];
    wire spi_ncs = ui_in[2];

    reg        sclk_prev;
    reg [4:0]  bit_count;
    reg [15:0] shift_reg;

    reg [7:0] reg0;
    reg [7:0] reg1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_prev <= 1'b0;
            bit_count <= 5'd0;
            shift_reg <= 16'h0000;
            reg0      <= 8'h00;
            reg1      <= 8'h00;
            uo_out    <= 8'h00;
            uio_out   <= 8'h00;
            uio_oe    <= 8'h00;
        end else begin
            // ena is present for TT compatibility; design can ignore it
            sclk_prev <= spi_sclk;

            // default outputs
            uo_out  <= reg0;
            uio_out <= reg1;
            uio_oe  <= 8'h00;   // keep bidir pins as inputs for now

            if (!spi_ncs) begin
                // capture on rising edge of SCLK
                if (!sclk_prev && spi_sclk) begin
                    shift_reg <= {shift_reg[14:0], spi_mosi};
                    bit_count <= bit_count + 5'd1;
                end
            end else begin
                // commit when CS goes high after 16 bits
                if (bit_count == 5'd16) begin
                    if (shift_reg[15]) begin
                        case (shift_reg[14:8])
                        7'h00: reg0 <= shift_reg[7:0];
                        7'h01: reg1 <= shift_reg[7:0];
                        default: begin end
                        endcase
                    end
                end

                bit_count <= 5'd0;
                shift_reg <= 16'h0000;
            end
        end
    end

endmodule

`default_nettype wire