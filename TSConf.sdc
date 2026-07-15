derive_pll_clocks
derive_clock_uncertainty

# The TSConf core updates video data only on its pixel enable. The MiSTer
# video pipeline samples it on the 56 MHz video clock, so this related-clock
# crossing intentionally has more than one destination cycle to settle.
set core_clk  [get_clocks {emu|pll|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}]
set video_clk [get_clocks {emu|pll|pll_inst|altera_pll_i|general[1].gpll~PLL_OUTPUT_COUNTER|divclk}]
set_multicycle_path -from $core_clk -to $video_clk -setup 2
set_multicycle_path -from $core_clk -to $video_clk -hold 1

# CPU cores run from enables derived from the 84 MHz system clock.
set_multicycle_path -from {emu|tsconf|CPU|*} -setup 2
set_multicycle_path -from {emu|tsconf|CPU|*} -hold 1
set_multicycle_path -to   {emu|tsconf|CPU|*} -setup 2
set_multicycle_path -to   {emu|tsconf|CPU|*} -hold 1

set saa_keepers [get_keepers -no_duplicates -nowarn {*|saa1099:saa1099|*}]
set_multicycle_path -to $saa_keepers -setup 2
set_multicycle_path -to $saa_keepers -hold 1

set gs_cpu_keepers [get_keepers -no_duplicates -nowarn {*|gs_top:gs_top|gs:gs|*CPU|*}]
set_multicycle_path -to $gs_cpu_keepers -setup 2
set_multicycle_path -to $gs_cpu_keepers -hold 1

# Most of the TSConf logic is clocked by fclk, a clock-enable-gated version of
# the 84 MHz system clock which advances once every three system cycles.  Keep
# the SDRAM controller itself at one-cycle timing, but allow three cycles for
# requests coming from the explicitly listed 28 MHz source blocks.
set sdram_keepers [get_keepers -no_duplicates -nowarn {*|sdram:sdram|*}]
foreach source_pattern {
	{*|arbiter:arbiter|*}
	{*|zmem:zmem|*}
	{*|dma:dma|*}
	{*|zsignals:zsignals|*}
	{*|zports:zports|*}
	{*|video_top:video_top|*}
} {
	set source_keepers [get_keepers -no_duplicates -nowarn $source_pattern]
	set_multicycle_path -from $source_keepers -to $sdram_keepers -setup 3
	set_multicycle_path -from $source_keepers -to $sdram_keepers -hold 2
}

# The SPI engine is in the same 28 MHz domain while the MiSTer virtual SD
# bridge is clocked directly at 84 MHz.
set spi_keepers     [get_keepers -no_duplicates -nowarn {*|spi:spi|*}]
set sdcard_keepers  [get_keepers -no_duplicates -nowarn {*|sd_card:sd_card|*}]
set_multicycle_path -from $spi_keepers -to $sdcard_keepers -setup 3
set_multicycle_path -from $spi_keepers -to $sdcard_keepers -hold 2

# RTC runs at 84 MHz but its bus controls originate in the 28 MHz CPU domain.
set rtc_keepers [get_keepers -no_duplicates -nowarn {*|mc146818a:mc146818a|*}]
foreach source_pattern {
	{*|zports:zports|*}
	{*|zmem:zmem|*}
	{*|zsignals:zsignals|*}
} {
	set source_keepers [get_keepers -no_duplicates -nowarn $source_pattern]
	set_multicycle_path -from $source_keepers -to $rtc_keepers -setup 3
	set_multicycle_path -from $source_keepers -to $rtc_keepers -hold 2
}
