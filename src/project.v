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

    reg        sclk_d;
    reg        cs_d;
    reg [4:0]  bit_count;
    reg [15:0] rx_word;

    reg [7:0]  reg0;
    reg [7:0]  reg1;

    always @(posedge clk) begin
        if (!rst_n) begin
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
            // Always drive uio pins as outputs (test expects this)
            uio_oe <= 8'hFF;

            // sample previous pins
            sclk_d <= ui_in[0];
            cs_d   <= ui_in[2];

            // While CS low, shift on SCLK rising edge
            if (!ui_in[2] && !sclk_d && ui_in[0]) begin
                rx_word   <= {rx_word[14:0], ui_in[1]};
                bit_count <= bit_count + 5'd1;
            end

            // On CS rising edge, commit if exactly 16 bits received
            if (!cs_d && ui_in[2]) begin
                if (bit_count == 5'd16) begin
                    // frame: [15:8] address, [7:0] data
                    case (rx_word[15:8])
                        8'h00: reg0 <= rx_word[7:0];
                        8'h01: reg1 <= rx_word[7:0];
                        default: ;
                    endcase
                end
                bit_count <= 5'd0;
                rx_word   <= 16'h0000;
            end

            // Outputs reflect registers
            uo_out  <= reg0;
            uio_out <= reg1;
        end
    end

endmodule
