# Build script

# Open project
open_project ultra96v2.xpr
update_compile_order -fileset sources_1

# Generating the bitstream, this can be heavily improved
reset_run impl_1 -prev_step
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# Export the hardware XSA
write_hw_platform -fixed -force -include_bit -file ultra96v2.xsa
