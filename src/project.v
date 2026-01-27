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

    // Synchronize ONLY SCLK and MOSI into clk domain (optional but nice)
    reg sclk_meta, sclk_sync;
    reg mosi_meta, mosi_sync;

    // Use nCS directly (no 2-FF delay), but still edge-detect in clk domain
    reg cs_d;

    // Edge detect for SCLK in clk domain
    reg sclk_d;

    // SPI receive state
    reg [4:0]  bit_count;
    reg [15:0] rx_word;

    // Output registers
    reg [7:0] reg0;
    reg [7:0] reg1;

    always @(negedge rst_n or posedge clk) begin
        if (!rst_n) begin
            sclk_meta <= 1'b0;
            sclk_sync <= 1'b0;
            mosi_meta <= 1'b0;
            mosi_sync <= 1'b0;

            sclk_d    <= 1'b0;
            cs_d      <= 1'b1;

            bit_count <= 5'd0;
            rx_word   <= 16'h0000;

            reg0      <= 8'h00;
            reg1      <= 8'h00;

            uo_out    <= 8'h00;
            uio_out   <= 8'h00;
            uio_oe    <= 8'hFF;
        end else begin
            // Always drive uio pins as outputs
            uio_oe <= 8'hFF;

            // Sync SCLK/MOSI
            sclk_meta <= ui_in[0];
            sclk_sync <= sclk_meta;
            mosi_meta <= ui_in[1];
            mosi_sync <= mosi_meta;

            // Track previous values for edge detection
            sclk_d <= sclk_sync;
            cs_d   <= ui_in[2];      // nCS direct

            // --- Shift on SCLK rising edge while nCS is low ---
            if (!ui_in[2] && !sclk_d && sclk_sync) begin
                // Test sends MSB-first; this shift builds the correct 16-bit word
                rx_word   <= {rx_word[14:0], mosi_sync};
                bit_count <= bit_count + 5'd1;
            end

            // --- Commit on nCS rising edge (end of transaction) ---
            if (!cs_d && ui_in[2]) begin
                if (bit_count == 5'd16) begin
                    // frame: [15:8]=addr, [7:0]=data
                    if (rx_word[15:8] == 8'h00) reg0 <= rx_word[7:0];
                    else if (rx_word[15:8] == 8'h01) reg1 <= rx_word[7:0];
                    // tolerate swapped order just in case
                    else if (rx_word[7:0]  == 8'h00) reg0 <= rx_word[15:8];
                    else if (rx_word[7:0]  == 8'h01) reg1 <= rx_word[15:8];
                end

                // reset SPI state
                bit_count <= 5'd0;
                rx_word   <= 16'h0000;
            end

            // Outputs reflect registers
            uo_out  <= reg0;
            uio_out <= reg1;
        end
    end

endmodule
