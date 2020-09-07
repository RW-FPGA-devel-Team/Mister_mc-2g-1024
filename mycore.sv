//============================================================================
//  Grant’s multi computer
// 
//  Port to MiSTer.
//
//  Based on Grant’s multi computer
//  http://searle.hostei.com/grant/
//  http://searle.hostei.com/grant/Multicomp/index.html
//	 and WiSo's collector blog (MiST port)
//	 https://ws0.org/building-your-own-custom-computer-with-the-mist-fpga-board-part-1/
//	 https://ws0.org/building-your-own-custom-computer-with-the-mist-fpga-board-part-2/
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
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] VIDEO_ARX,
	output  [7:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,

	

	output        LED_USER,  // 1 - ON, 0 - OFF.
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

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,


	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);


assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
//assign {UART_RTS, UART_TXD, UART_DTR} = 0;
//assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  

assign VGA_SL = 0;
assign VGA_F1 = 0;

assign AUDIO_S = 0;
assign AUDIO_L = 0;
assign AUDIO_R = 0;
assign AUDIO_MIX = 0;

assign BUTTONS = 0;

assign LED_USER  = 0;
assign LED_DISK  = ~driveLED;
assign LED_POWER = 0;

assign VIDEO_ARX = 4;
assign VIDEO_ARY = 3;


`include "build_id.v"
localparam CONF_STR = {
	"MultiComp;;",
	"-;",
	"T0,Reset;",
	"-;",
	"V,v1.1.",`BUILD_DATE
};


//////////////////   HPS I/O   ///////////////////
wire  [1:0] buttons;
wire [31:0] status;

wire PS2_CLK;
wire PS2_DAT;

wire forced_scandoubler;

wire [31:0] sd_lba;
wire        sd_rd;
wire        sd_wr;
wire        sd_ack;
wire  [8:0] sd_buff_addr;
wire  [7:0] sd_buff_dout;
wire  [7:0] sd_buff_din;
wire        sd_buff_wr;
wire        sd_ack_conf;


wire pll_locked;
wire clk_sys;


pll pll
(
  .refclk  (CLK_50M),
  .rst     (0),
  .outclk_0(clk_sys),
  .locked  (pll_locked)
);



hps_io #(.STRLEN($size(CONF_STR)>>3), .PS2DIV(1923)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.forced_scandoubler(forced_scandoubler),

	.ps2_kbd_clk_out(PS2_CLK),
	.ps2_kbd_data_out(PS2_DAT)
);

/////////////////  RESET  /////////////////////////

wire reset = RESET | status[0] | buttons[1];

///////////////////////////////////////////////////

assign CLK_VIDEO = clk_sys;



wire hblank, vblank;
wire hs, vs;
wire [1:0] r,g,b;
wire driveLED;

wire [2:0] _hblank, _vblank;
wire [2:0] _hs, _vs;
wire [1:0] _r;
wire [1:0] _g;
wire [1:0] _b;
wire [2:0] _CE_PIXEL;
wire [2:0] _SD_CS;
wire [2:0] _SD_MOSI;
wire [2:0] _SD_SCK;
wire [2:0] _driveLED;

always_comb 
begin
	hblank 		<= _hblank;
	vblank 		<= _vblank;
	hs 		 	<= _hs;
	vs				<= _vs;
	r 				<= _r[1:0];
	g 				<= _g[1:0];
	b				<= _b[1:0];
	CE_PIXEL		<= _CE_PIXEL;
	SD_CS			<= _SD_CS;
	SD_MOSI		<= _SD_MOSI;
	SD_SCK		<= _SD_SCK;
	driveLED 	<= _driveLED;
end

Microcomputer Microcomputer
(
	.n_reset(~reset),
	.clk(clk_sys),
	//
  	.sramData		(),
	.sramAddress	(),
	.n_sRamWE		(),
	.n_sRamOE		(),
	.n_sRam1CS		(),
	.n_sRam2CS		(),

	//
	.videoR0 (_r[0]),
	.videoR1 (_r[1]),
	.videoG0 (_g[0]),
	.videoG1 (_g[1]),
	.videoB0 (_b[0]),
	.videoB1 (_b[1]),
	.hSync   (_hs[0]),
	.vSync   (_vs[0]),
	.hBlank(_hblank[0]),
	.vBlank(_vblank[0]),
	.cepix(_CE_PIXEL[0]),
	//
	.ps2Clk(PS2_CLK),
	.ps2Data(PS2_DAT),
	//
	.rxd1		(UART_RXD),
	.txd1		(UART_TXD),
	.rts1		(UART_RTS),
	.cts1		(UART_CTS),

	.sdCS(_SD_CS[0]),
	.sdMOSI(_SD_MOSI[0]),
	.sdMISO(SD_MISO),
	.sdSCLK(_SD_SCK[0]),
	.driveLED(_driveLED[0])
);
		


video_cleaner video_cleaner
(
	.clk_vid(CLK_VIDEO),
	.ce_pix(CE_PIXEL),

	.R({4{r}}),
	.G({4{g}}),
	.B({4{b}}),
	.HSync(hs),
	.VSync(vs),
	.HBlank(hblank),
	.VBlank(vblank),

	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),
	.VGA_VS(VGA_VS),
	.VGA_HS(VGA_HS),
	.VGA_DE(VGA_DE)
);


endmodule
