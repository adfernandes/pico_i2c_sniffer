# Build automation for the i2c sniffer targets (RP2040, RP2350, Bus Pirate 5).
#
# Each target uses its own build directory so the CMake caches never mix.
# The historical bin/i2c_sniffer_pio.uf2 (2021 build) is never overwritten:
# the new binaries use suffixed names.
TARGET = i2c_sniffer_pio

.PHONY: all clean pico1 pico2 bp5

all: pico1

# Target para la Pico 1 (RP2040)
pico1:
	cmake -B build-rp2040 -DPICO_BOARD=pico
	$(MAKE) -C build-rp2040
	mkdir -p bin
	cp build-rp2040/$(TARGET).uf2 bin/$(TARGET)_rp2040.uf2

# Target para la Pico 2 (RP2350)
pico2:
	cmake -B build-rp2350 -DPICO_BOARD=pico2
	$(MAKE) -C build-rp2350
	mkdir -p bin
	cp build-rp2350/$(TARGET).uf2 bin/$(TARGET)_rp2350.uf2

# Target para el hardware del Bus Pirate 5 (RP2040)
bp5:
	cmake -B build-bp5 -DPICO_BOARD=pico -DTARGET_BUS_PIRATE_5=ON
	$(MAKE) -C build-bp5
	mkdir -p bin
	cp build-bp5/$(TARGET).uf2 bin/$(TARGET)_bp5.uf2

clean:
	rm -rf build-rp2040/ build-rp2350/ build-bp5/
	rm -f bin/$(TARGET)_rp2040.uf2 bin/$(TARGET)_rp2350.uf2 bin/$(TARGET)_bp5.uf2
