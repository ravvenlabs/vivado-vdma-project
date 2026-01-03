# ##############################################################################
# Dr. Kaputa
# Vivado Scripting Utopia
# SPDX-License-Identifier: BSD-3-Clause [https://spdx.org/licenses/]
# ##############################################################################

#set projectName
set projectName golden

# 0: setup project, 1: setup and compile project
set compileProject 0

# 0: leave messy, 1: blow away everything but sources and .bit file
set cleanup 0

# ##############################################################################
# setup project
# ##############################################################################
create_project $projectName project -part xck26-sfvc784-2LV-c -force

set_property board_part xilinx.com:kv260_som:part0:1.4 [current_project]

# setup various project properties
set_property target_language VHDL [current_project]
set_property simulator_language VHDL [current_project]
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]
set_property STEPS.OPT_DESIGN.IS_ENABLED false [get_runs impl_1]

# setup repositories
set_property ip_repo_paths ip [current_project]
update_ip_catalog

# add files to project
add_files -norecurse src/design_1.bd
make_wrapper -files [get_files src/design_1.bd] -top -quiet -import
add_files -fileset constrs_1 -norecurse src/constraints.xdc

# either just setup or setup and compile
if { $compileProject == 0 } {
  # just close the project
  close_project
} else {
  # compile and create boot.bin

  # start synthesis
  launch_runs synth_1 -jobs 8
  wait_on_run synth_1
  
  # netlist is complete
  launch_runs impl_1 -to_step write_bitstream -jobs 8
  wait_on_run impl_1
  
  write_hw_platform -fixed -include_bit -force -file system.xsa
  
  close_project
  
  # copy over .bit file to system.bit
  file copy -force project/$projectName.runs/impl_1/design_1_wrapper.bit system.bit
  file copy -force project/$projectName.runs/impl_1/design_1_wrapper.bin system.bin
  
  # create system.bit.bin file for linux flashing
  #exec bootgen -image bootimage.bif -arch zynqmp -process_bitstream bin

  if {$cleanup == 1 } {
    # clean out bloatware from src folder
    file delete src/design_1.bxml
    file delete src/design_1_ooc.xdc
    file delete -force src/ip
    file delete -force src/hdl
    file delete -force src/hw_handoff
    file delete -force src/ipshared
    file delete -force project
    file delete -force .xil
  }
}