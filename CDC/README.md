NB: we will limit ourselves to purely synchronous CDC, and not cover asynchronous CDC where one clock domain is the 'outside world'; such as must be considered in UART designs.

In all examples, there are three 3 source clock domains from which debounced async ext input will be taken and crossed into a single destination domain.

The three source domains will be 36MHz, 70MHz and 100MHz, and the destination domain will be 50MHz.

There are three (broadly speaking) options for MUXing the sources into the destination domains dynamically or during circuit operation.

Options:
1. three separate CDC instances
2. 1 CDC instances with 3 clks MUXd in -- **LUT on the Clock Tree**
3. as 2, but with PLL on clk line output from MUX **p302 UG906 - opt-design may optimize away the LUT somehow, guard against this**


### Modules included in HWUT

1. typische: typical general for multi-bit paths
2. flag sync type module
3. Dynamic Shift Register experiment whereby different taps may be selected thru switches and outputs on dest. domain compared to known inputs on src domain
	-- see p. 86 of UG901
4. Gray Code counter controlled async fifos
5. ...

### Design Scope

At the highest level consists of:

1. Conceptual data-path and/or RTL diagrams
2. Verilog and VHDL implementations
3. TCL compiler directives
4. Setting of Xilinx-specific (and possibly Series 7 specific) attributes
5. ... ? ILA cores
6. Relating of timing, etc reports from the synth tool, and explicit command to generate certain reports if required

### Exploration of Timing

**Chapter 5 of ug906 could be used as the foundational basis for any lesson here.**

Useful Xilinx Training video/playlist:

1. `multicycle_paths`: https://www.youtube.com/watch?v=zqGI7Vmrwr8&list=PL35626FEF3D5CB8F2&index=32&spfreload=10
2. `false_paths`: https://www.youtube.com/watch?v=Z7VCWCmmrU0&list=PL35626FEF3D5CB8F2&index=35&spfreload=10
3. `report_cdc`: https://www.youtube.com/watch?v=7YqMUjiMmLQ&list=PL35626FEF3D5CB8F2&index=114&spfreload=10

Reports desired (see ug906 Ch 2):

1. Timing Exceptions Coverage
2. Schematic CDC Topologies (start p. 90 ug906), specifically interested in:
	1. Multi-Bit Synchronizer
	2. Multi-Clock Fanin (<- desirable)
	3. ...
3. Bus Skew

Use OLED to show counters or bus signals (strobed in) of both clock domains

Use BTNs to increment counter in one clock domain, and then increment downstream counter in second clock domain

Use SWs or UART to set bus signals in one domain which are then passed into another domain.

Or use SWs to select a particular module tied into the harness

Additionally, use mixed languages in internal modules? VHDL and (System)Verilog?

**Mixed Language (Verilog & VHDL)**

[URL] https://www.xilinx.com/support/answers/47454.html

Also, include a video exploring how edge-triggered DFFs work, showing example in LogiSim

In fact, I could do an entire async fifo or flag sync module in LogiSim

Table: cases of CDC

Dim-1 headings: single bit, multi-bit
Dim-2 headings: strobing, latching, streaming
Dim-3 headings: master-slave control, hand-shake, data

**strobe (or pulse) type signals**

Must use a Toggle Synchronizer

**Need to verify the following notions below:**

1. in a simple synchronizing chain, the second DFF is there to simply prevent a meta-stable state from propagating into the design. This can be a propagation in an electrical sense and/or in a logical sense. Either way, the synchronizing chain does not guarantee that the synchronized bit is correct, only that it is stable.


**Cool outside refs**

[Descr] incl. ref to meta-stability aware simulator at end, and incl. several types of CDC incl with feedback
[URL] https://www.techdesignforums.com/practice/technique/verifying-clock-domain-crossings-when-using-fast-to-slow-clocks/
