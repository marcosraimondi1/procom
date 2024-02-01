launch_simulation
restart
add_force {/axi_stream/axi_clk} -radix hex {1 0ns} {0 5000ps} -repeat_every 10000ps
add_force {/axi_stream/axi_reset_n} -radix hex {1 0ns}
add_force {/axi_stream/s_axis_valid} -radix hex {0 0ns}
add_force {/axi_stream/s_axis_data} -radix hex {0 0ns}
add_force {/axi_stream/s_axis_valid} -radix hex {0 0ns}
add_force {/axi_stream/m_axis_ready} -radix hex {0 0ns}
run 10 ns
run 10 ns
run 10 ns
run 10 ns
run 10 ns
add_force {/axi_stream/axi_clk} -radix hex {0 0ns} {1 5000ps} -repeat_every 10000ps
run 1 ms
run 10 ns
run 10 ns
restart
run 10 ns
run 10 ns
run 10 ns
add_force {/axi_stream/axi_clk} -radix hex {0 0ns} {1 5000ps} -repeat_every 10000ps
run 10 ns
run 10 ns
run 10 ns
run 10 ns
run 10 ns
run 10 ns
run 10 ns
run 10 ns
run 10 ns
add_force {/axi_stream/s_axis_valid} -radix hex {1 0ns}
run 10 ns
add_force {/axi_stream/m_axis_ready} -radix hex {1 0ns}
run 10 ns
add_force {/axi_stream/s_axis_valid} -radix hex {0 0ns}
run 10 ns
add_force {/axi_stream/s_axis_data} -radix hex {00ff00ff 0ns}
add_force {/axi_stream/s_axis_valid} -radix hex {1 0ns}
run 10 ns
add_force {/axi_stream/s_axis_data} -radix hex {ff00ff00 0ns}
add_force {/axi_stream/m_axis_ready} -radix hex {0 0ns}
run 10 ns
run 10 ns
run 10 ns
report_drivers {/axi_stream/s_axis_valid}
add_force {/axi_stream/s_axis_valid} -radix hex {0 0ns}
run 10 ns
add_force {/axi_stream/m_axis_ready} -radix hex {1 0ns}
run 10 ns
run 10 ns
add_force {/axi_stream/s_axis_valid} -radix hex {1 0ns}
run 10 ns
add_force {/axi_stream/s_axis_valid} -radix hex {0 0ns}
run 10 ns
run 10 ns