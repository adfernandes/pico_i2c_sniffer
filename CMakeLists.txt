# Set minimum required version of CMake
cmake_minimum_required(VERSION 3.12)

# Include build functions from Pico SDK
include($ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake)
include($ENV{PICO_SDK_PATH}/tools/CMakeLists.txt)

# Set name of project (as PROJECT_NAME) and C/C++ standards
project(i2c_sniffer_pio C CXX ASM)
set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# Creates a pico-sdk subdirectory in our project for the libraries
pico_sdk_init()

# ==============================================================================
# Target hardware profile
# ==============================================================================
option(TARGET_BUS_PIRATE_5 "Build for Bus Pirate 5 hardware" OFF)
option(INT_CAPTURE_EN "Capture an interrupt (INT) line on a second PIO block" ON)

if (TARGET_BUS_PIRATE_5)
    # Bus Pirate 5 (REV10): SDA on BUFIO7 (header IO7), SCL on BUFIO0
    # (header IO0). EV0/EV1 are the sniffer's internal event pins and must
    # land on GPIOs that are NOT driven by the IO buffers: SPI_CDI (the on
    # board NAND flash stays deselected, see bp5_deselect_spi_slaves) and
    # RGB_CDO (LED strip data input, high impedance).
    set(I2C_SDA_PIN 15)  # BUFIO7 = header IO7
    set(I2C_EV0_PIN 16)  # SPI_CDI (internal)
    set(I2C_EV1_PIN 17)  # RGB_CDO (internal)
    set(I2C_SCL_PIN 8)   # BUFIO0 = header IO0
else()
    # Standard Pico / Pico 2 (legacy 2021 pinout).
    set(I2C_SDA_PIN 0)
    set(I2C_EV0_PIN 1)
    set(I2C_EV1_PIN 2)
    set(I2C_SCL_PIN 3)
endif()

# Generate i2c_sniffer.pio with the pin map of the selected target baked in.
configure_file(
    ${CMAKE_CURRENT_LIST_DIR}/i2c_sniffer.pio.in
    ${CMAKE_CURRENT_BINARY_DIR}/i2c_sniffer.pio
    @ONLY
)

# Tell CMake where to find the executable source file
add_executable(${PROJECT_NAME} 
    main.c
    ram_fifo.c
)

# Create C header file with the name <pio program>.pio.h
pico_generate_pio_header(${PROJECT_NAME}  
    ${CMAKE_CURRENT_BINARY_DIR}/i2c_sniffer.pio
)

# Create map/bin/hex/uf2 files
pico_add_extra_outputs(${PROJECT_NAME})

# Link to pico_stdlib (gpio, time, etc. functions)
target_link_libraries(${PROJECT_NAME} 
    pico_stdlib
    hardware_pio
    pico_multicore
)

target_compile_definitions(${PROJECT_NAME} PUBLIC 
    PICO_STDOUT_MUTEX=0 
    PICO_STDIO_ENABLE_CRLF_SUPPORT=0
    TARGET_BUS_PIRATE_5=$<BOOL:${TARGET_BUS_PIRATE_5}>
    INT_CAPTURE_EN=$<BOOL:${INT_CAPTURE_EN}>
)

# Enable usb output, disable uart output
pico_enable_stdio_usb(${PROJECT_NAME} 1)
pico_enable_stdio_uart(${PROJECT_NAME} 0)
