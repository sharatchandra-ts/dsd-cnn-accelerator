# RISC-V Based CNN Hardware Accelerator

A self-contained Vivado hardware design project featuring a custom 3x3 convolution neural network (CNN) accelerator integrated with a register bank, controller, and datapath, targeting Artix-7/Basys 3 style architectures.

## Repository Structure

- `dsd_project.srcs/sources_1/new/` — All Verilog RTL design sources (`cnn_top.v`, `cnn_accelerator.v`, `cnn_controller.v`, `cnn_buffers.v`, `conv_datapath.v`, `mac_unit.v`, `cnn_registers.v`)
- `dsd_project.srcs/sim_1/new/` — SystemVerilog testbenches (`tb_cnn_top.sv`, `tb_cnn_accelerator.sv`, etc.)
- `dsd_project.srcs/constrs_1/new/` — Synthesis constraints (`top_xdc.xdc`)
- `build_project.tcl` — Automatic project generation script

---

## How to Build and Run the Project

You can recreate and build the entire Vivado project from scratch using the provided Tcl script.

### Prerequisites
- Xilinx Vivado (v2025.2 or compatible version) installed on your system.

### Steps to Rebuild & Simulate:

1. Open **Vivado** (you can open the Vivado Tcl Shell or start Vivado GUI without opening a project).
2. Change your working directory to the project root folder:
```tcl
cd path/to/dsd_project
```

3. Run the project generation Tcl script in the Tcl Console:
```tcl
source build_project.tcl
```


4. Once the project opens in the Vivado GUI:
* **To Run Simulation:** Click **Run Simulation** -> **Run Behavioral Simulation** in the Flow Navigator (ensure `tb_cnn_top` is set as the top simulation module).
* **To Run Synthesis:** Click **Run Synthesis** to check resource utilization and timing reports.
