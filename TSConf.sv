//============================================================================
//  TSConf for MiSTer
//
//  Port to MiSTer
//  Copyright (C) 2017-2019 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign ADC_BUS     = 'Z;
assign USER_OUT    = '1;
assign VGA_F1      = 0;
assign UART_RTS    = 0;
assign UART_DTR    = 0;
assign LED_POWER   = 0;
assign BUTTONS     = 0;
assign VGA_SCALER  = 0;
assign VGA_DISABLE = 0;
assign HDMI_FREEZE = 0;

`ifdef MISTER_FB
assign FB_EN          = 0;
assign FB_FORMAT      = 0;
assign FB_WIDTH       = 0;
assign FB_HEIGHT      = 0;
assign FB_BASE        = 0;
assign FB_STRIDE      = 0;
assign FB_FORCE_BLANK = 0;
`ifdef MISTER_FB_PALETTE
assign FB_PAL_CLK  = 0;
assign FB_PAL_ADDR = 0;
assign FB_PAL_DOUT = 0;
assign FB_PAL_WR   = 0;
`endif
`endif

`ifdef MISTER_DUAL_SDRAM
assign SDRAM2_CLK  = 1'b0;
assign SDRAM2_A    = 'Z;
assign SDRAM2_BA   = 'Z;
assign SDRAM2_DQ   = 'Z;
assign SDRAM2_nCS  = 1'b1;
assign SDRAM2_nCAS = 1'b1;
assign SDRAM2_nRAS = 1'b1;
assign SDRAM2_nWE  = 1'b1;
`endif

`include "build_id.v"
localparam CONF_STR = {
	"TSConf;;",
	"SC0,VHD,Mount virtual SD;",
	"F3F,NVR,Load NVRAM;",
	"-;",
	"o01,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O12,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%;",
	"d0o2,Vertical Crop,Disabled,270p(5x);",
	"o34,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;",
	"-;",
	"O34,Stereo mix,None,25%,50%,100%;",
	"O78,Joystick 1,Kempston,Sinclair 1,Sinclair 2,Cursor;",
	"O9A,Joystick 2,Kempston,Sinclair 1,Sinclair 2,Cursor;",
	"OB,Swap mouse buttons,OFF,ON;",
	"OC,Vsync,49 Hz,60 Hz;",
	"OD,VDAC1,ON,OFF;",
	"OE,CPU Type,CMOS,NMOS;",
	"TF,Save NVRAM settings;",
	"T0,Reset;",
	"J,Fire 1,Fire 2;",
	"V,v",`BUILD_DATE
};

wire [127:0] status;
wire [1:0] scale = status[2:1];
wire [1:0] cfg_joystick1 = status[8:7];
wire [1:0] cfg_joystick2 = status[10:9];
wire cfg_mouse_swap = status[11];
wire cfg_60hz = ~status[12];
wire cfg_vdac = ~status[13];
wire cfg_out0 = ~status[14];

wire [1:0] ar = status[33:32];
wire vcrop_en = status[34];
reg en270p;
always @(posedge CLK_VIDEO) begin
	en270p <= ((HDMI_WIDTH == 1920) && (HDMI_HEIGHT == 1080) && !forced_scandoubler && !scale);
end

wire vga_de;
video_freak video_freak
(
	.*,
	.VGA_DE_IN(vga_de),
	.ARX((!ar) ? 12'd4 : (ar - 1'd1)),
	.ARY((!ar) ? 12'd3 : 12'd0),
	.CROP_SIZE((en270p & vcrop_en) ? 10'd270 : 10'd0),
	.CROP_OFF(0),
	.SCALE(status[36:35])
);

////////////////////   CLOCKS   ///////////////////
wire clk_sys;
pll pll
(
	.refclk(CLK_50M),
	.rst(1'b0),
	.outclk_0(clk_sys),
	.outclk_1(CLK_VIDEO)
);

reg ce_28m;
always @(negedge clk_sys) begin
	reg [1:0] div;
	div <= div + 1'd1;
	if(div == 2) div <= 0;
	ce_28m <= !div;
end

//////////////////   HPS I/O   ///////////////////
wire [31:0] joy_0;
wire [31:0] joy_1;
wire [1:0] buttons;
wire [24:0] ps2_mouse;
wire [15:0] ps2_mouse_ext;
wire [10:0] ps2_key;
wire forced_scandoubler;
wire [21:0] gamma_bus;

wire [31:0] sd_lba;
wire sd_rd;
wire sd_wr;
wire sd_ack;
wire [8:0] sd_buff_addr;
wire [7:0] sd_buff_dout;
wire [7:0] sd_buff_din;
wire sd_buff_wr;
wire img_mounted;
wire img_readonly;
wire [63:0] img_size;
wire [64:0] RTC;

wire ioctl_wr;
wire [26:0] ioctl_addr;
wire [7:0] ioctl_dout;
wire [7:0] ioctl_din;
wire ioctl_download;
wire ioctl_upload;
wire [15:0] ioctl_index;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.joystick_0(joy_0),
	.joystick_1(joy_1),
	.buttons(buttons),
	.status(status),
	.status_menumask({15'd0,en270p}),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),

	.RTC(RTC),
	.ps2_mouse(ps2_mouse),
	.ps2_mouse_ext(ps2_mouse_ext),
	.ps2_key(ps2_key),

	.sd_lba('{sd_lba}),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),
	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din('{sd_buff_din}),
	.sd_buff_wr(sd_buff_wr),
	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_download(ioctl_download),
	.ioctl_upload(ioctl_upload),
	.ioctl_upload_req(status[15]),
	.ioctl_upload_index(8'h3F),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),
	.ioctl_wait(1'b0)
);

wire mouse_b0 = cfg_mouse_swap ? ps2_mouse[1] : ps2_mouse[0];
wire mouse_b1 = cfg_mouse_swap ? ps2_mouse[0] : ps2_mouse[1];
wire [28:0] core_mouse = {
	ps2_mouse[24], ps2_mouse_ext[3:0], ps2_mouse[23:8],
	ps2_mouse[7:2], mouse_b1, mouse_b0
};

////////////////////  MAIN  //////////////////////
wire [7:0] R,G,B;
wire HBlank,VBlank;
wire VS,HS;
wire ce_vid;
wire [15:0] sound_l,sound_r;
wire tape_out,midi_out,uart_out;

tsconf tsconf
(
	.clk(clk_sys),
	.ce(ce_28m),

	.SDRAM_DQ(SDRAM_DQ),
	.SDRAM_A(SDRAM_A),
	.SDRAM_BA(SDRAM_BA),
	.SDRAM_DQML(SDRAM_DQML),
	.SDRAM_DQMH(SDRAM_DQMH),
	.SDRAM_nWE(SDRAM_nWE),
	.SDRAM_nCAS(SDRAM_nCAS),
	.SDRAM_nRAS(SDRAM_nRAS),
	.SDRAM_CKE(SDRAM_CKE),
	.SDRAM_nCS(SDRAM_nCS),
	.SDRAM_CLK(SDRAM_CLK),

	.VRED(R),
	.VGRN(G),
	.VBLU(B),
	.VHSYNC(HS),
	.VVSYNC(VS),
	.VGA_HBLANK(HBlank),
	.VGA_VBLANK(VBlank),
	.VGA_CEPIX(ce_vid),

	.SD_SO(sdmiso),
	.SD_SI(sdmosi),
	.SD_CLK(sdclk),
	.SD_CS_N(sdss),

	.SOUND_L(sound_l),
	.SOUND_R(sound_r),

	.COLD_RESET(RESET | status[0] | reset_img | ioctl_download),
	.WARM_RESET(buttons[1]),
	.RTC(RTC),
	.TAPE_IN(UART_RXD),
	.TAPE_OUT(tape_out),
	.MIDI_OUT(midi_out),
	.UART_RX(UART_RXD),
	.UART_TX(uart_out),

	.CFG_OUT0(cfg_out0),
	.CFG_60HZ(cfg_60hz),
	.CFG_SCANDOUBLER(1'b0),
	.CFG_VDAC(cfg_vdac),
	.CFG_JOYSTICK1(cfg_joystick1),
	.CFG_JOYSTICK2(cfg_joystick2),

	.PS2_KEY(ps2_key),
	.PS2_MOUSE(core_mouse),
	.JOYSTICK1({joy_0[9:8],joy_0[5:0]}),
	.JOYSTICK2({joy_1[9:8],joy_1[5:0]}),

	.loader_act(ioctl_download),
	.loader_addr(ioctl_addr[15:0]),
	.loader_do(ioctl_dout),
	.loader_di(ioctl_din),
	.loader_wr(ioctl_wr),
	.loader_cs_rom_main(ioctl_index == 16'h0000),
	.loader_cs_rom_gs(ioctl_index == 16'h0040),
	.loader_cs_cmos(ioctl_index == 16'h003F)
);

assign AUDIO_L = sound_l;
assign AUDIO_R = sound_r;
assign AUDIO_S = 1'b1;
assign AUDIO_MIX = status[4:3];

reg uart_tx = 1'b1;
reg tape_out_old = 1'b0;
reg midi_out_old = 1'b0;
reg uart_out_old = 1'b0;
always @(posedge clk_sys) begin
	if(tape_out_old != tape_out) begin
		tape_out_old <= tape_out;
		uart_tx <= tape_out;
	end
	if(midi_out_old != midi_out) begin
		midi_out_old <= midi_out;
		uart_tx <= midi_out;
	end
	if(uart_out_old != uart_out) begin
		uart_out_old <= uart_out;
		uart_tx <= uart_out;
	end
end
assign UART_TXD = uart_tx;

assign DDRAM_CLK      = clk_sys;
assign DDRAM_BURSTCNT = 0;
assign DDRAM_ADDR     = 0;
assign DDRAM_RD       = 0;
assign DDRAM_DIN      = 0;
assign DDRAM_BE       = 0;
assign DDRAM_WE       = 0;

assign LED_USER = (vsd_sel & sd_act) | ioctl_download | ioctl_upload;
assign LED_DISK = {1'b1, ~vsd_sel & sd_act};

//////////////////   VIDEO   ///////////////////
reg ce_pix;
always @(posedge CLK_VIDEO) begin
	reg old_ce;
	old_ce <= ce_vid;
	ce_pix <= ~old_ce & ce_vid;
end

reg VSync,HSync;
always @(posedge CLK_VIDEO) begin
	HSync <= HS;
	if(~HSync & HS) VSync <= VS;
end

assign VGA_SL = {scale == 3,scale == 2};
video_mixer #(.GAMMA(1)) video_mixer
(
	.CLK_VIDEO(CLK_VIDEO),
	.CE_PIXEL(CE_PIXEL),
	.ce_pix(ce_pix),
	.scandoubler(scale || forced_scandoubler),
	.hq2x(scale == 1),
	.gamma_bus(gamma_bus),
	.R(R),
	.G(G),
	.B(B),
	.HSync(HSync),
	.VSync(VSync),
	.HBlank(HBlank),
	.VBlank(VBlank),
	.HDMI_FREEZE(HDMI_FREEZE),
	.freeze_sync(),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.VGA_DE(vga_de)
);

//////////////////   SD   ///////////////////
wire sdclk;
wire sdmosi;
wire sdmiso = vsd_sel ? vsdmiso : SD_MISO;
wire sdss;

reg reset_img;
reg vsd_sel = 0;
always @(posedge clk_sys) begin
	integer reset_timeout = 0;
	if(reset_timeout) reset_timeout <= reset_timeout - 1;
	else reset_img <= 0;

	if(img_mounted) begin
		vsd_sel <= |img_size;
		reset_img <= 1;
		reset_timeout <= 10000000;
	end
end

wire vsdmiso;
sd_card sd_card
(
	.*,
	.reset(RESET | status[0]),
	.clk_spi(clk_sys),
	.sdhc(1),
	.sck(sdclk),
	.ss(~vsd_sel | sdss),
	.mosi(sdmosi),
	.miso(vsdmiso)
);

assign SD_CS = vsd_sel | sdss;
assign SD_SCK = sdclk & ~SD_CS;
assign SD_MOSI = sdmosi & ~SD_CS;

reg sd_act;
always @(posedge clk_sys) begin
	reg old_mosi,old_miso;
	integer activity_timeout = 0;
	old_mosi <= sdmosi;
	old_miso <= sdmiso;

	sd_act <= 0;
	if(activity_timeout < 1000000) begin
		activity_timeout <= activity_timeout + 1;
		sd_act <= 1;
	end
	if((old_mosi ^ sdmosi) || (old_miso ^ sdmiso)) activity_timeout <= 0;
end

endmodule
