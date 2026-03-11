module tt_um_spi_regs (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] ui_in,
    input  wire [7:0] uio_in,
    output reg  [7:0] uo_out,
    output reg  [7:0] uio_out,
    output reg  [7:0] uio_oe
);

    // Detect which bus is being used for SPI
    wire ui_cs  = ui_in[2];
    wire uio_cs = uio_in[2];
    wire use_uio = (uio_cs == 1'b0);  // prefer uio if active

    wire spi_sclk = use_uio ? uio_in[0] : ui_in[0];
    wire spi_mosi = use_uio ? uio_in[1] : ui_in[1];
    wire spi_ncs  = use_uio ? uio_in[2] : ui_in[2];

    reg        sclk_prev;

    // Capture on both edges
    reg [15:0] rx_rise;
    reg [15:0] rx_fall;
    reg [4:0]  cnt_rise;
    reg [4:0]  cnt_fall;

    reg [7:0] reg0;
    reg [7:0] reg1;

    // Valid address checks
    wire rise_ad_ok = (rx_rise[15:8] == 8'h00) || (rx_rise[15:8] == 8'h01);
    wire rise_da_ok = (rx_rise[7:0]  == 8'h00) || (rx_rise[7:0]  == 8'h01);

    wire fall_ad_ok = (rx_fall[15:8] == 8'h00) || (rx_fall[15:8] == 8'h01);
    wire fall_da_ok = (rx_fall[7:0]  == 8'h00) || (rx_fall[7:0]  == 8'h01);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_prev <= 1'b0;

            rx_rise   <= 16'h0000;
            rx_fall   <= 16'h0000;
            cnt_rise  <= 5'd0;
            cnt_fall  <= 5'd0;

            reg0      <= 8'h00;
            reg1      <= 8'h00;

            uo_out    <= 8'h00;
            uio_out   <= 8'h00;
            uio_oe    <= 8'h00;   // keep uio as inputs
        end else begin
            // keep uio pins as inputs to avoid fighting SPI driver
            uio_oe  <= 8'h00;

            // expose registers on outputs
            uo_out  <= reg0;
            uio_out <= reg1;

            // remember previous sclk
            sclk_prev <= spi_sclk;

            if (!spi_ncs) begin
                // Rising edge detect
                if (!sclk_prev && spi_sclk) begin
                    rx_rise  <= {spi_mosi, rx_rise[15:1]};
                    cnt_rise <= cnt_rise + 5'd1;
                end

                // Falling edge detect
                if (sclk_prev && !spi_sclk) begin
                    rx_fall  <= {spi_mosi, rx_fall[15:1]};
                    cnt_fall <= cnt_fall + 5'd1;
                end
            end else begin
                // Commit when CS goes high
                if (cnt_rise == 5'd16) begin
                    if (rise_ad_ok) begin
                        if (rx_rise[15:8] == 8'h00)
                            reg0 <= rx_rise[7:0];
                        else if (rx_rise[15:8] == 8'h01)
                            reg1 <= rx_rise[7:0];
                    end else if (rise_da_ok) begin
                        if (rx_rise[7:0] == 8'h00)
                            reg0 <= rx_rise[15:8];
                        else if (rx_rise[7:0] == 8'h01)
                            reg1 <= rx_rise[15:8];
                    end
                end else if (cnt_fall == 5'd16) begin
                    if (fall_ad_ok) begin
                        if (rx_fall[15:8] == 8'h00)
                            reg0 <= rx_fall[7:0];
                        else if (rx_fall[15:8] == 8'h01)
                            reg1 <= rx_fall[7:0];
                    end else if (fall_da_ok) begin
                        if (rx_fall[7:0] == 8'h00)
                            reg0 <= rx_fall[15:8];
                        else if (rx_fall[7:0] == 8'h01)
                            reg1 <= rx_fall[15:8];
                    end
                end

                // Reset transaction state
                rx_rise  <= 16'h0000;
                rx_fall  <= 16'h0000;
                cnt_rise <= 5'd0;
                cnt_fall <= 5'd0;
            end
        end
    end

endmodule