# TSConf for MiSTer

TSConf is an advanced ZX Spectrum-compatible platform based on ZX Evolution.
This fork contains the MiSTer port together with the later TSConf RTL fixes and
features which were developed in the MiST version of the core.

## Features

- VDAC1 video, MiSTer HDMI/scaler output and 49/60 Hz modes
- RTC and persistent NVRAM
- ZiFi (Wi-Fi)
- tape input, MIDI output and UART through the MiSTer UART pins
- TurboSound FM (dual YM2203), OPL2 (YM3812), General Sound, SAA1099, Covox and Soundrive
- two configurable Kempston/Sinclair/Cursor joysticks
- Kempston mouse with wheel support and optional button swap
- physical secondary SD card and MiSTer virtual VHD image

The TSConf platform provides multiple video modes, tile and sprite planes,
programmable memory paging, 3.5/7/14 MHz Z80 modes and a DMA controller. See
the [TSConf documentation](https://github.com/tslabs/zx-evo/blob/master/pentevo/docs/TSconf/tsconf_en.md)
for the full hardware description.

## Installation

1. Copy the generated `TSConf.rbf` to the MiSTer `_Computer` directory (a dated
   filename such as `TSConf_YYYYMMDD.rbf` may be used).
2. Copy `release/TSConf.rom` as `games/TSConf/boot0.rom` on the MiSTer SD card.
3. Copy `release/TSConf.r01` as `games/TSConf/boot1.rom`. MiSTer loads both ROMs
   automatically when the core starts.
4. Put a FAT-formatted TSConf VHD image in `games/TSConf` and mount it from the
   core menu, or use a physical secondary SD card.

The original TSConf F12 reset key is mapped to F11 because F12 opens the MiSTer
OSD. Use Left Shift+F11 for BASIC and Right Shift+F11 for the TS-BIOS setup.
NVRAM can be saved from the OSD and loaded again as an `.NVR` file.

## Building

The project targets the MiSTer Cyclone V device and Quartus Prime Lite 17.0.
Quartus is expected in `C:\Hwdev\quartus170`. Build from Cygwin-compatible make:

```text
C:\cygwin64\bin\make.exe build
```

The resulting bitstream is written to `output_files/TSConf.rbf`.

## Credits

- [TSConf / ZX Evolution](https://github.com/tslabs/zx-evo)
- [original TSConf MiSTer core](https://github.com/MiSTer-devel/TSConf_MiSTer)
- T80 Z80 HDL implementation
- [JT12 Yamaha OPN HDL implementation](https://github.com/jotego/jt12)
- [JTOPL Yamaha OPL HDL implementation](https://github.com/jotego/jtopl)
