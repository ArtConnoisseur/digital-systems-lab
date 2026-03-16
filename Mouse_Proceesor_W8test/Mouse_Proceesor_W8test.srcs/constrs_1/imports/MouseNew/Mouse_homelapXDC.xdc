## =====================================================
## 100 MHz Clock
## =====================================================
set_property PACKAGE_PIN W5 [get_ports CLK]
set_property IOSTANDARD LVCMOS33 [get_ports CLK]
create_clock -period 10.000 -name sys_clk [get_ports CLK]

## =====================================================
## Reset Button (BTNC)
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
set_property IOSTANDARD LVCMOS33 [get_ports LED[*]]

set_property PACKAGE_PIN U16 [get_ports LED[0]]
set_property PACKAGE_PIN E19 [get_ports LED[1]]
set_property PACKAGE_PIN U19 [get_ports LED[2]]
set_property PACKAGE_PIN V19 [get_ports LED[3]]
set_property PACKAGE_PIN W18 [get_ports LED[4]]
set_property PACKAGE_PIN U15 [get_ports LED[5]]
set_property PACKAGE_PIN U14 [get_ports LED[6]]
set_property PACKAGE_PIN V14 [get_ports LED[7]]
#set_property PACKAGE_PIN V13 [get_ports LED[8]]
#set_property PACKAGE_PIN V3  [get_ports LED[9]]
#set_property PACKAGE_PIN W3  [get_ports LED[10]]
#set_property PACKAGE_PIN U3  [get_ports LED[11]]
#set_property PACKAGE_PIN P3  [get_ports LED[12]]
#set_property PACKAGE_PIN N3  [get_ports LED[13]]
#set_property PACKAGE_PIN P1  [get_ports LED[14]]
#set_property PACKAGE_PIN L1  [get_ports LED[15]]

## =====================================================
## Seven Segment Display
## =====================================================
set_property IOSTANDARD LVCMOS33 [get_ports HEX_OUT[*]]
set_property IOSTANDARD LVCMOS33 [get_ports SEG_SELECT_OUT[*]]

set_property PACKAGE_PIN W7 [get_ports HEX_OUT[0]]
set_property PACKAGE_PIN W6 [get_ports HEX_OUT[1]]
set_property PACKAGE_PIN U8 [get_ports HEX_OUT[2]]
set_property PACKAGE_PIN V8 [get_ports HEX_OUT[3]]
set_property PACKAGE_PIN U5 [get_ports HEX_OUT[4]]
set_property PACKAGE_PIN V5 [get_ports HEX_OUT[5]]
set_property PACKAGE_PIN U7 [get_ports HEX_OUT[6]]
set_property PACKAGE_PIN V7 [get_ports HEX_OUT[7]]

set_property PACKAGE_PIN U2 [get_ports SEG_SELECT_OUT[0]]
set_property PACKAGE_PIN U4 [get_ports SEG_SELECT_OUT[1]]
set_property PACKAGE_PIN V4 [get_ports SEG_SELECT_OUT[2]]
set_property PACKAGE_PIN W4 [get_ports SEG_SELECT_OUT[3]]
