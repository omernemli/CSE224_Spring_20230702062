###############################################################################
# Created by write_sdc
# Mon Jun  9 18:11:31 2025
###############################################################################
current_design TopModule
###############################################################################
# Timing Constraints
###############################################################################
create_clock -name core_clock -period 10.0000 [get_ports {clk}]
set_propagated_clock [get_clocks {core_clock}]
###############################################################################
# Environment
###############################################################################
###############################################################################
# Design Rules
###############################################################################
