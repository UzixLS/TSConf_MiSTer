module opl
(
    input  wire               reset,
    input  wire               clk,
    input  wire               wr_n,
    input  wire               cs_n,
    input  wire         [7:0] din,
    input  wire               a,
    output wire         [7:0] dout,
    output wire signed [15:0] out_l,
    output wire signed [15:0] out_r
);

// Fractional 3.579545 MHz clock enable derived from the 28 MHz system clock.
reg [15:0] accumulator;
reg clk_en;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        accumulator <= 16'd0;
        clk_en <= 1'b0;
    end
    else begin
        {clk_en, accumulator} <= accumulator + 16'd8377;
    end
end

// The Z80 holds WR active for several 28 MHz clocks.
// Convert the bus cycle into the single-clock write pulse expected by JTOPL.
reg prev_wr_n = 1'b1;
reg opl_wr = 1'b0;
always @(posedge clk or posedge reset) begin
    if (reset) begin
        prev_wr_n <= 1'b1;
        opl_wr <= 1'b0;
    end
    else begin
        prev_wr_n <= wr_n | cs_n;
        opl_wr <= !cs_n && !wr_n && prev_wr_n;
    end
end

wire signed [15:0] snd;

jtopl #(.OPL_TYPE(2)) jtopl_inst
(
    .rst    (reset),
    .clk    (clk),
    .cen    (clk_en),
    .din    (din),
    .addr   (a),
    .cs_n   (1'b0),
    .wr_n   (!opl_wr),
    .dout   (dout),
    .irq_n  (),
    .snd    (snd),
    .sample ()
);

assign out_l = snd;
assign out_r = snd;

endmodule
