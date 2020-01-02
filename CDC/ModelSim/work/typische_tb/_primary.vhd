library verilog;
use verilog.vl_types.all;
entity typische_tb is
    generic(
        MW              : integer := 8;
        NUM_RX_WORDS    : integer := 4;
        NUM_TX_WORDS    : integer := 4;
        DATA_FILE       : vl_logic_vector(111 downto 0) := (Hi0, Hi0, Hi1, Hi0, Hi1, Hi1, Hi1, Hi0, Hi0, Hi0, Hi1, Hi0, Hi1, Hi1, Hi1, Hi1, Hi0, Hi1, Hi1, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi1, Hi0, Hi1, Hi0, Hi1, Hi1, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi1, Hi1, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi0, Hi1, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi1, Hi0, Hi1, Hi0, Hi1, Hi1, Hi0, Hi0, Hi1, Hi0, Hi1, Hi0, Hi1, Hi1, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi0, Hi1, Hi0, Hi1, Hi1, Hi1, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi1, Hi1, Hi1, Hi0, Hi1, Hi0, Hi0);
        CMP_FILE        : vl_logic_vector(143 downto 0) := (Hi0, Hi0, Hi1, Hi0, Hi1, Hi1, Hi1, Hi0, Hi0, Hi0, Hi1, Hi0, Hi1, Hi1, Hi1, Hi1, Hi0, Hi1, Hi1, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi1, Hi0, Hi1, Hi0, Hi1, Hi1, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi1, Hi1, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi0, Hi1, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi1, Hi0, Hi1, Hi0, Hi1, Hi1, Hi0, Hi0, Hi1, Hi0, Hi1, Hi0, Hi1, Hi1, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi1, Hi0, Hi1, Hi1, Hi1, Hi1, Hi1, Hi0, Hi1, Hi1, Hi0, Hi0, Hi0, Hi1, Hi1, Hi0, Hi1, Hi1, Hi0, Hi1, Hi1, Hi0, Hi1, Hi0, Hi1, Hi1, Hi1, Hi0, Hi0, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi1, Hi1, Hi1, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi1, Hi0, Hi0, Hi0, Hi1, Hi1, Hi0, Hi0, Hi0, Hi0, Hi1, Hi0, Hi1, Hi1, Hi1, Hi0, Hi1, Hi0, Hi0);
        END_CYCLES      : integer := 5;
        T               : integer := 5;
        T_TB            : real    := 0.001000;
        C_A             : integer := 2103;
        C_B             : integer := 1103
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of MW : constant is 1;
    attribute mti_svvh_generic_type of NUM_RX_WORDS : constant is 1;
    attribute mti_svvh_generic_type of NUM_TX_WORDS : constant is 1;
    attribute mti_svvh_generic_type of DATA_FILE : constant is 1;
    attribute mti_svvh_generic_type of CMP_FILE : constant is 1;
    attribute mti_svvh_generic_type of END_CYCLES : constant is 1;
    attribute mti_svvh_generic_type of T : constant is 1;
    attribute mti_svvh_generic_type of T_TB : constant is 1;
    attribute mti_svvh_generic_type of C_A : constant is 1;
    attribute mti_svvh_generic_type of C_B : constant is 1;
end typische_tb;
