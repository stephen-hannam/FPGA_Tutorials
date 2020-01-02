# UNDER CONSTRUCTION

## FPGA Tutorial Source

### Intended Audience

Those who are starting to move from beginner to intermediate levels of knowledge/skill with FPGA and Hardware Description.

### Assumed Knowledge

1. basic syntax of either VHDL, verilog or both
2. what an FPGA fundamentally is (and is not)
3. what Hardware Description fundamentally is (and is not)
4. basic design workflow followed for simple FPGA designs: RTL -> Simulation -> Synth -> bitstream -> Hardware
5. basic familiarity with a synth-tool/IDE, preferably Vivado - ModelSim is used too, but all hardware is Xilinx (Arty)

### Vivado Workflow

Used to gen bitstreams and for post-synth/post-impl sims if any are conducted.

NB: source files were **not** copied (interred might be a better word) into the wandering, Kafka-esque hall-of-mirrors directory structures that Vivado insists on creating. Source files are kept in one of three locations:

1. the hardwareHarness\_src directory in the parent folder
2. a verilog folder in the folder specific to a given exercise
3. a VHDL folder in the folder specific to a given exercise

Additionally, exercise folders will also have an XDC folder containing constraints specific to a given exercise, although the .xdc file may often not differ between exercises.

Modifications made to files in these locations will flow directly through to the exercise/s.

### ModelSim Workflow

ModelSim used for RTL/Elaboration level simulations to explore and verify the functionality (and functional correctness) of the 'algorithms'/descriptions.

? Configuring the files in the repo such that ModelSim project building is automated was briefly attempted but dropped as ?
? download and use without manual building of ModelSim project ... ?

### Resources

NB: the PMOD OLED module used for demonstration requires Vivado 2019.1. I've tried running it with other versions of Vivado, and there seems to be an issue with encryption of some underlying IP cores used. I think the IP cores I use were compiled with some form of encryption enabled, and that encryption is particular to the version of Vivado used.

Where appropriate I reference code snippets or full modules drawn from outside code-bases. One major code-base was the QUT EGH449 Advanced Electronics code-base.

CDC and Gray Code tutorials directly reference open papers by Cliff Cummings, and some of the coded modules are taken directly from these openly available papers. I make no claim to their authorship, and will seek only to explain them in my own words partly to help teach myself the material more deeply and that others might benefit from this activity.

### Covering and Not Covering

Covering: example designs of common types of modules, how they work, test-benching them, running them in hardware, exploring how the synth-tool interprets the Hardware Description

Also Covering: CDC in both test-bench and HW harness, timing exceptions in the XDC file, some SystemVerilog constructs (such as interfaces), and tools/tips/techniques for accellerating the process of writing and/or developing HDL designs using VHDL or Verilog/SystemVerilog.

In the fashion of NandLand examples with contain a Verilog version and a VHDL version.
