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

    // SPI pins (use uio_in because many TT cocotb tests drive SPI on uio)
    // uio_in[0] = SCLK
    // uio_in[1] = MOSI (COPI)
    // uio_in[2] = nCS (active low)
    wire spi_sclk = uio_in[0];
    wire spi_mosi = uio_in[1];
    wire spi_ncs  = uio_in[2];

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
            uio_oe    <= 8'h00;   // IMPORTANT: don't drive uio pins during SPI
        end else begin
            // Keep uio as inputs (avoid contention with testbench driving SPI)
            uio_oe <= 8'h00;

            // Drive outputs
            uo_out  <= reg0;
            uio_out <= reg1;

            // Edge detect SCLK
            sclk_prev <= spi_sclk;

            if (!spi_ncs) begin
                // CS low: sample MOSI on rising edge of SCLK
                if (!sclk_prev && spi_sclk) begin
                    // MSB-first: first 8 bits = addr, next 8 bits = data
                    rx_word   <= {spi_mosi, rx_word[15:1]};
                    bit_count <= bit_count + 5'd1;
                end
            end else begin
                // CS high: commit
                if (bit_count == 5'd16) begin
                    if (rx_word[15:8] == 8'h00) reg0 <= rx_word[7:0];
                    else if (rx_word[15:8] == 8'h01) reg1 <= rx_word[7:0];
                end

                // Reset for next transaction
                bit_count <= 5'd0;
                rx_word   <= 16'h0000;
            end
        end
    end

endmodule
