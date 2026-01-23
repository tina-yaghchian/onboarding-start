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

    // ui_in[0] = SCLK
    // ui_in[1] = MOSI
    // ui_in[2] = nCS (active low)

    reg [15:0] shift_reg;
    reg [4:0]  bit_count;

    reg [7:0] reg0;
    reg [7:0] reg1;

    reg sclk_d;

    always @(posedge clk) begin
        if (!rst_n) begin
            shift_reg <= 16'h0000;
            bit_count <= 0;
            reg0 <= 8'h00;
            reg1 <= 8'h00;
            uo_out <= 8'h00;
            uio_out <= 8'h00;
            uio_oe <= 8'hFF;
            sclk_d <= 0;
        end else begin
            uio_oe <= 8'hFF;

            // Reset receiver when CS is high
            if (ui_in[2]) begin
                bit_count <= 0;
            end

            // detect rising edge of SCLK (ui_in[0]) while CS low (ui_in[2]==0)
            sclk_d <= ui_in[0];
            if (!ui_in[2] && !sclk_d && ui_in[0]) begin
                // form the next shift_reg including *this* MOSI bit
                reg [15:0] next_shift;
                next_shift = {shift_reg[14:0], ui_in[1]};
                shift_reg <= next_shift;

                if (bit_count == 15) begin
                    // next_shift now contains the full 16-bit word:
                    // [15]=R/W, [14:8]=addr, [7:0]=data
                    if (next_shift[15]) begin
                        if (next_shift[14:8] == 7'h00)
                            reg0 <= next_shift[7:0];
                        else if (next_shift[14:8] == 7'h01)
                            reg1 <= next_shift[7:0];
                    end
                    bit_count <= 0;
                end else begin
                    bit_count <= bit_count + 1;
                end
            end


            uo_out <= reg0;
            uio_out <= reg1;
        end
    end

endmodule

