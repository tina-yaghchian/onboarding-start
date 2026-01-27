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
    // ui_in[2] = nCS  (active low)

    // --- Synchronize SPI pins into clk domain (OpenLane-safe) ---
    reg sclk_meta, sclk_sync;
    reg cs_meta,   cs_sync;
    reg mosi_meta, mosi_sync;

    // Previous values for edge detect (in clk domain)
    reg sclk_d;
    reg cs_d;

    // SPI receive state
    reg [4:0]  bit_count;
    reg [15:0] rx_word;

    // Registers mapped to outputs
    reg [7:0] reg0;
    reg [7:0] reg1;

    always @(negedge rst_n or posedge clk) begin
        if (!rst_n) begin
            // sync regs
            sclk_meta <= 1'b0;  sclk_sync <= 1'b0;
            cs_meta   <= 1'b1;  cs_sync   <= 1'b1;
            mosi_meta <= 1'b0;  mosi_sync <= 1'b0;

            // edge detect regs
            sclk_d    <= 1'b0;
            cs_d      <= 1'b1;

            // spi state
            bit_count <= 5'd0;
            rx_word   <= 16'h0000;

            // user regs / outputs
            reg0      <= 8'h00;
            reg1      <= 8'h00;

            uo_out    <= 8'h00;
            uio_out   <= 8'h00;
            uio_oe    <= 8'hFF;
        end else begin
            // Always drive uio pins as outputs (matches onboarding tests)
            uio_oe <= 8'hFF;

            // 2-FF synchronize external SPI pins
            sclk_meta <= ui_in[0];  sclk_sync <= sclk_meta;
            cs_meta   <= ui_in[2];  cs_sync   <= cs_meta;
            mosi_meta <= ui_in[1];  mosi_sync <= mosi_meta;

            // edge detect (use synced signals)
            sclk_d <= sclk_sync;
            cs_d   <= cs_sync;

            // SCLK rising edge while CS low -> shift in one bit
            if (!cs_sync && !sclk_d && sclk_sync) begin
                // MSB-first shift in: after 16 edges, rx_word[15:0] matches bitstream order
                rx_word   <= {rx_word[14:0], mosi_sync};
                bit_count <= bit_count + 5'd1;
            end

            // CS rising edge -> end of transaction, commit if 16 bits received
            if (!cs_d && cs_sync) begin
                if (bit_count == 5'd16) begin
                    // Support both common layouts:
                    // 1 [15:8]=addr, [7:0]=data
                    if (rx_word[15:8] == 8'h00) reg0 <= rx_word[7:0];
                    else if (rx_word[15:8] == 8'h01) reg1 <= rx_word[7:0];
                    // 2 [15:8]=data, [7:0]=addr
                    else if (rx_word[7:0]  == 8'h00) reg0 <= rx_word[15:8];
                    else if (rx_word[7:0]  == 8'h01) reg1 <= rx_word[15:8];
                end

                // Reset SPI state for next transaction
                bit_count <= 5'd0;
                rx_word   <= 16'h0000;
            end

            // Outputs reflect registers
            uo_out  <= reg0;
            uio_out <= reg1;

            // Unused inputs: ena, uio_in (fine)
        end
    end

endmodule
