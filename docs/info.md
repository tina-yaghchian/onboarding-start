## How it works

This project implements a write-only SPI peripheral operating in SPI mode 0.
The SPI interface receives 16-bit transactions consisting of:

- 1-bit Read/Write flag (writes only are supported)
- 7-bit address
- 8-bit data

SPI signals (nCS, SCLK, COPI/MOSI) are synchronized into the system clock domain.
Bits are shifted in on the rising edge of SCLK while nCS is low.
Registers are updated only after a complete transaction has been received.

Address map:
- Address 0x00: updates `uo_out`
- Address 0x01: updates `uio_out`
- Other addresses are ignored

## How to test

The design is verified using cocotb-based Python tests.

To run the tests locally:
1. Activate the Python virtual environment
2. Run `make -C test`

The SPI test performs multiple write transactions and checks that outputs
update correctly. Additional tests validate PWM behavior.

## External hardware

No external hardware is required. The design is fully self-contained and
intended for simulation and ASIC synthesis.

