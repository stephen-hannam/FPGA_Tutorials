library verilog;
use verilog.vl_types.all;
entity typische_mcp_mgc is
    generic(
        WIDTH           : integer := 8
    );
    port(
        clk_a           : in     vl_logic;
        rst_n_a         : in     vl_logic;
        clk_b           : in     vl_logic;
        cntl_a          : in     vl_logic;
        data_a          : in     vl_logic_vector;
        cntl_b          : out    vl_logic;
        data_b          : out    vl_logic_vector
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of WIDTH : constant is 1;
end typische_mcp_mgc;
