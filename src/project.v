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

    reg [4:0]  bit_count;
    reg [15:0] rx_word;
    reg [7:0]  reg0, reg1;

    // SPI: shift on SCLK posedge, commit on nCS posedge
    always @(negedge rst_n or posedge ui_in[0] or posedge ui_in[2]) begin
        if (!rst_n) begin
            bit_count <= 5'd0;
            rx_word   <= 16'h0000;
            reg0      <= 8'h00;
            reg1      <= 8'h00;
        end else if (ui_in[2]) begin
            // nCS high => end transaction
            if (bit_count == 5'd16) begin
                // Most common: MSB-first, [15:8]=addr, [7:0]=data
                if (rx_word[15:8] == 8'h00) reg0 <= rx_word[7:0];
                else if (rx_word[15:8] == 8'h01) reg1 <= rx_word[7:0];
                // Also allow swapped just in case
                else if (rx_word[7:0] == 8'h00) reg0 <= rx_word[15:8];
                else if (rx_word[7:0] == 8'h01) reg1 <= rx_word[15:8];
            end
            bit_count <= 5'd0;
            rx_word   <= 16'h0000;
        end else begin
            // SCLK posedge while nCS low
            rx_word   <= {rx_word[14:0], ui_in[1]};
            bit_count <= bit_count + 5'd1;
        end
    end

    // Drive outputs in clk domain
    always @(posedge clk) begin
        if (!rst_n) begin
            uo_out  <= 8'h00;
            uio_out <= 8'h00;
            uio_oe  <= 8'hFF;
        end else begin
            uio_oe  <= 8'hFF;
            uo_out  <= reg0;
            uio_out <= reg1;
        end
    end

endmodule
