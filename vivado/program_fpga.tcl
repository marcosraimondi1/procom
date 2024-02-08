# Run after bitstream was generated
# create .xsa file: export hardware with bitstream
set proj_dir [get_property directory [current_project]]
write_hw_platform -fixed -include_bit -force -file $proj_dir/top_ethernet_wrapper.xsa

# program fpga - after connecting to putty
set target_fpga 210319A2CE12A
open_hw_manager
connect_hw_server -url localhost:3121 -allow_non_jtag
current_hw_target [get_hw_targets */xilinx_tcf/Digilent/$target_fpga]
set_property PARAM.FREQUENCY 15000000 [get_hw_targets */xilinx_tcf/Digilent/$target_fpga]
open_hw_target
current_hw_device [get_hw_devices xc7a35t_0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7a35t_0] 0]
set_property PROBES.FILE {$proj_dir/tpfinal.project.runs/impl_1/top_ethernet_wrapper.ltx} [get_hw_devices xc7a35t_0]
set_property FULL_PROBES.FILE {$proj_dir/tpfinal.project.runs/impl_1/top_ethernet_wrapper.ltx} [get_hw_devices xc7a35t_0]
set_property PROGRAM.FILE {$proj_dir/tpfinal.project.runs/impl_1/top_ethernet_wrapper.bit} [get_hw_devices xc7a35t_0]
program_hw_devices [get_hw_devices xc7a35t_0]
refresh_hw_device [lindex [get_hw_devices xc7a35t_0] 0]
display_hw_ila_data [ get_hw_ila_data hw_ila_data_1 -of_objects [get_hw_ilas -of_objects [get_hw_devices xc7a35t_0] -filter {CELL_NAME=~"top_ethernet_i/ila_0"}]]
