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
    // ui_in[1] = MOSI (COPI)
    // ui_in[2] = nCS (active low)

    reg        sclk_prev;
    reg [4:0]  bit_count;
    reg [15:0] rx_word;

    reg [7:0] reg0;
    reg [7:0] reg1;

    always @(negedge rst_n or posedge clk) begin
        if (!rst_n) begin
            sclk_prev <= 1'b0;

            bit_count <= 5'd0;
            rx_word   <= 16'h0000;

            reg0      <= 8'h00;
            reg1      <= 8'h00;

            uo_out    <= 8'h00;
            uio_out   <= 8'h00;
            uio_oe    <= 8'hFF;
        end else begin
            // always drive outputs
            uio_oe  <= 8'hFF;
            uo_out  <= reg0;
            uio_out <= reg1;

            // keep previous SCLK for edge detect
            sclk_prev <= ui_in[0];

            if (!ui_in[2]) begin
                // CS low: receive bits
                // sample MOSI on rising edge of SCLK
                if (!sclk_prev && ui_in[0]) begin
                    // MSB-first shift in (addr then data)
                    rx_word   <= {ui_in[1], rx_word[15:1]};
                    bit_count <= bit_count + 5'd1;
                end
            end else begin
                // CS high: commit once at end of transaction
                if (bit_count == 5'd16) begin
                    // [15:8] = addr, [7:0] = data
                    if (rx_word[15:8] == 8'h00) reg0 <= rx_word[7:0];
                    else if (rx_word[15:8] == 8'h01) reg1 <= rx_word[7:0];
                end

                // reset for next transaction
                bit_count <= 5'd0;
                rx_word   <= 16'h0000;
            end
        end
    end

endmodule
