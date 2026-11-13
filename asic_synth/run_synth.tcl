# ==========================================
# Cadence Genus Synthesis Script for SAED 90nm
# ==========================================

# 1. Define Library Paths (Update paths based on your lab server setup)
set LIB_PATH "."
# (Note: Use typical, slow, or fast .lib files depending on your lab's guidelines, e.g., saed90nm_rvt_typ.lib)

set_db init_lib_search_path $LIB_PATH
set_db library {saed90nm_typ.lib} 

# 2. Read Verilog RTL Files
set RTL_FILES {
    rtl/mac_unit.v
    rtl/conv_datapath.v
    rtl/cnn_buffers.v
    rtl/cnn_controller.v
    rtl/cnn_accelerator.v
    rtl/cnn_registers.v
    rtl/cnn_top.v
}

read_hdl -verilog $RTL_FILES

# 3. Elaborate Design (Top module name is cnn_top)
elaborate cnn_top
current_design cnn_top

# 4. Apply Constraints
read_sdc constraints/top.sdc

# 5. Run Synthesis Optimization Steps
syn_generic
syn_map
syn_opt

# 6. Create Reports Directory
file mkdir reports

# 7. Generate All Required Project Reports
report_timing > reports/timing_report.rpt
report_area   > reports/area_report.rpt
report_power  > reports/power_report.rpt
report_gates  > reports/gates_report.rpt

# 8. Export Synthesized Netlist & SDF (Crucial for Gate-Level Simulation later!)
write_hdl > reports/cnn_top_netlist.v
write_sdf > reports/cnn_top.sdf

puts "INFO: Synthesis and report generation completed successfully!"
