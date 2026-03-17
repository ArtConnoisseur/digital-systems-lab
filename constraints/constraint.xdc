## Clock signal
set_property PACKAGE_PIN W5 [get_ports CLK]
    set_property IOSTANDARD LVCMOS33 [get_ports CLK]


## =====================================================
## VGA Connector
## Signal order: COLOUR_OUT = Red[0:3], Blue[4:7], Green[8:11]
## =====================================================

# Red
set_property PACKAGE_PIN G19 [get_ports {COLOUR_OUT[0]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[0]}]
set_property PACKAGE_PIN H19 [get_ports {COLOUR_OUT[1]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[1]}]
set_property PACKAGE_PIN J19 [get_ports {COLOUR_OUT[2]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[2]}]
set_property PACKAGE_PIN N19 [get_ports {COLOUR_OUT[3]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[3]}]

# Blue
set_property PACKAGE_PIN N18 [get_ports {COLOUR_OUT[4]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[4]}]
set_property PACKAGE_PIN L18 [get_ports {COLOUR_OUT[5]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[5]}]
set_property PACKAGE_PIN K18 [get_ports {COLOUR_OUT[6]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[6]}]
set_property PACKAGE_PIN J18 [get_ports {COLOUR_OUT[7]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[7]}]

# Green
set_property PACKAGE_PIN J17 [get_ports {COLOUR_OUT[8]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[8]}]
set_property PACKAGE_PIN H17 [get_ports {COLOUR_OUT[9]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[9]}]
set_property PACKAGE_PIN G17 [get_ports {COLOUR_OUT[10]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[10]}]
set_property PACKAGE_PIN D17 [get_ports {COLOUR_OUT[11]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {COLOUR_OUT[11]}]

set_property PACKAGE_PIN P19 [get_ports HS]
    set_property IOSTANDARD LVCMOS33 [get_ports HS]
set_property PACKAGE_PIN R19 [get_ports VS]
    set_property IOSTANDARD LVCMOS33 [get_ports VS]


## =====================================================
## Switches
## =====================================================
set_property PACKAGE_PIN V17 [get_ports {SWITCH[0]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SWITCH[0]}]
set_property PACKAGE_PIN V16 [get_ports {SWITCH[1]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SWITCH[1]}]
set_property PACKAGE_PIN W16 [get_ports {SWITCH[2]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SWITCH[2]}]
set_property PACKAGE_PIN W17 [get_ports {SWITCH[3]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SWITCH[3]}]
set_property PACKAGE_PIN W15 [get_ports {SWITCH[4]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SWITCH[4]}]
set_property PACKAGE_PIN V15 [get_ports {SWITCH[5]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SWITCH[5]}]
set_property PACKAGE_PIN W14 [get_ports {SWITCH[6]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SWITCH[6]}]
set_property PACKAGE_PIN W13 [get_ports {SWITCH[7]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SWITCH[7]}]
set_property PACKAGE_PIN V2  [get_ports {SWITCH[8]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SWITCH[8]}]
set_property PACKAGE_PIN T3  [get_ports {SWITCH[9]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SWITCH[9]}]
set_property PACKAGE_PIN T2  [get_ports {SWITCH[10]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SWITCH[10]}]
set_property PACKAGE_PIN R3  [get_ports {SWITCH[11]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SWITCH[11]}]
set_property PACKAGE_PIN W2  [get_ports {SWITCH[12]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SWITCH[12]}]
set_property PACKAGE_PIN U1  [get_ports {SWITCH[13]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SWITCH[13]}]
set_property PACKAGE_PIN T1  [get_ports {SWITCH[14]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SWITCH[14]}]
set_property PACKAGE_PIN R2  [get_ports {SWITCH[15]}]
    set_property IOSTANDARD LVCMOS33 [get_ports {SWITCH[15]}]


## =====================================================
## Buttons
## =====================================================
set_property PACKAGE_PIN U18 [get_ports RESET]
    set_property IOSTANDARD LVCMOS33 [get_ports RESET]


## =====================================================
## PS/2 Mouse
## =====================================================
set_property PACKAGE_PIN C17 [get_ports CLK_MOUSE]
    set_property IOSTANDARD LVCMOS33 [get_ports CLK_MOUSE]
    set_property PULLUP true [get_ports CLK_MOUSE]

set_property PACKAGE_PIN B17 [get_ports DATA_MOUSE]
    set_property IOSTANDARD LVCMOS33 [get_ports DATA_MOUSE]
    set_property PULLUP true [get_ports DATA_MOUSE]


## =====================================================
## LEDs
## =====================================================
set_property IOSTANDARD LVCMOS33 [get_ports {LED[*]}]

set_property PACKAGE_PIN U16 [get_ports {LED[0]}]
set_property PACKAGE_PIN E19 [get_ports {LED[1]}]
set_property PACKAGE_PIN U19 [get_ports {LED[2]}]
set_property PACKAGE_PIN V19 [get_ports {LED[3]}]
set_property PACKAGE_PIN W18 [get_ports {LED[4]}]
set_property PACKAGE_PIN U15 [get_ports {LED[5]}]
set_property PACKAGE_PIN U14 [get_ports {LED[6]}]
set_property PACKAGE_PIN V14 [get_ports {LED[7]}]
#set_property PACKAGE_PIN V13 [get_ports {LED[8]}]
#set_property PACKAGE_PIN V3  [get_ports {LED[9]}]
#set_property PACKAGE_PIN W3  [get_ports {LED[10]}]
#set_property PACKAGE_PIN U3  [get_ports {LED[11]}]
#set_property PACKAGE_PIN P3  [get_ports {LED[12]}]
#set_property PACKAGE_PIN N3  [get_ports {LED[13]}]
#set_property PACKAGE_PIN P1  [get_ports {LED[14]}]
#set_property PACKAGE_PIN L1  [get_ports {LED[15]}]


## =====================================================
## Seven Segment Display
## =====================================================
set_property IOSTANDARD LVCMOS33 [get_ports {HEX_OUT[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {SEG_SELECT_OUT[*]}]

set_property PACKAGE_PIN W7 [get_ports {HEX_OUT[0]}]
set_property PACKAGE_PIN W6 [get_ports {HEX_OUT[1]}]
set_property PACKAGE_PIN U8 [get_ports {HEX_OUT[2]}]
set_property PACKAGE_PIN V8 [get_ports {HEX_OUT[3]}]
set_property PACKAGE_PIN U5 [get_ports {HEX_OUT[4]}]
set_property PACKAGE_PIN V5 [get_ports {HEX_OUT[5]}]
set_property PACKAGE_PIN U7 [get_ports {HEX_OUT[6]}]
set_property PACKAGE_PIN V7 [get_ports {HEX_OUT[7]}]

set_property PACKAGE_PIN U2 [get_ports {SEG_SELECT_OUT[0]}]
set_property PACKAGE_PIN U4 [get_ports {SEG_SELECT_OUT[1]}]
set_property PACKAGE_PIN V4 [get_ports {SEG_SELECT_OUT[2]}]
set_property PACKAGE_PIN W4 [get_ports {SEG_SELECT_OUT[3]}]


## =====================================================
## Board configuration (required for all Basys3 designs)
## =====================================================
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
