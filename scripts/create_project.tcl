
set project_name "mc_pulse-generator"
set project_dir  "./mc_pulse-generator"
set part         "xczu7ev-ffvc1156-2-e"

create_project ${project_name} ${project_dir} -part ${part} -force

# Set project properties
set obj [current_project]
set_property -name "board_part" -value "xilinx.com:zcu104:part0:1.1" -objects $obj
set_property -name "default_lib" -value "xil_defaultlib" -objects $obj
set_property -name "dsa.accelerator_binary_content" -value "bitstream" -objects $obj
set_property -name "dsa.accelerator_binary_format" -value "xclbin2" -objects $obj
set_property -name "dsa.board_id" -value "zcu104" -objects $obj
set_property -name "dsa.description" -value "Vivado generated DSA" -objects $obj
set_property -name "dsa.dr_bd_base_address" -value "0" -objects $obj
set_property -name "dsa.emu_dir" -value "emu" -objects $obj
set_property -name "dsa.flash_interface_type" -value "bpix16" -objects $obj
set_property -name "dsa.flash_offset_address" -value "0" -objects $obj
set_property -name "dsa.flash_size" -value "1024" -objects $obj
set_property -name "dsa.host_architecture" -value "x86_64" -objects $obj
set_property -name "dsa.host_interface" -value "pcie" -objects $obj
set_property -name "dsa.num_compute_units" -value "60" -objects $obj
set_property -name "dsa.platform_state" -value "pre_synth" -objects $obj
set_property -name "dsa.vendor" -value "xilinx" -objects $obj
set_property -name "dsa.version" -value "0.0" -objects $obj
set_property -name "enable_vhdl_2008" -value "1" -objects $obj
set_property -name "ip_cache_permissions" -value "read write" -objects $obj
set_property -name "ip_output_repo" -value "${project_dir}/${project_name}.cache/ip" -objects $obj
set_property -name "mem.enable_memory_map_generation" -value "1" -objects $obj
set_property -name "sim.central_dir" -value "${project_dir}/${project_name}.ip_user_files" -objects $obj
set_property -name "sim.ip.auto_export_scripts" -value "1" -objects $obj
set_property -name "simulator_language" -value "Mixed" -objects $obj
set_property -name "webtalk.activehdl_export_sim" -value "80" -objects $obj
set_property -name "webtalk.ies_export_sim" -value "80" -objects $obj
set_property -name "webtalk.modelsim_export_sim" -value "80" -objects $obj
set_property -name "webtalk.questa_export_sim" -value "80" -objects $obj
set_property -name "webtalk.riviera_export_sim" -value "80" -objects $obj
set_property -name "webtalk.vcs_export_sim" -value "80" -objects $obj
set_property -name "webtalk.xcelium_export_sim" -value "1" -objects $obj
set_property -name "webtalk.xsim_export_sim" -value "80" -objects $obj
set_property -name "xpm_libraries" -value "XPM_CDC XPM_MEMORY" -objects $obj

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set IP repository paths
set obj [get_filesets sources_1]

# Enable IP repo (custom IP)
set_property ip_repo_paths ./src/ip [current_project]
update_ip_catalog -rebuild

#get_ipdefs user.org:user:trigger_logic_v1.0
# Add constraints
#add_files -fileset constrs_1 ./constraints/top.xdc

# Create Block Design
source ./bd/${project_name}.tcl
make_wrapper -files [get_files *.bd] -top
#add_files -norecurse ${project_dir}/${project_name}.srcs/sources_1/bd/*/hdl/*.v

# Set top
#set_property -name top -value ${project_name}_zynq_wrapper [current_fileset]

#update_compile_order -fileset sources_1
