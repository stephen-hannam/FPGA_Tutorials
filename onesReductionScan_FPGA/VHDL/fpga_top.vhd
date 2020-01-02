----------------------------------------------------------------------------------
-- fpga_top VHDL
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use work.helper_funcs.all;

entity fpga_top is
	generic (
		G_IN_SIM	  : INTEGER := 0
	);

	port (
			clk_pad   : IN   STD_LOGIC; -- 100Mhz clock
			rst_n     : IN   STD_LOGIC; -- "reset" button input (negative logic)
		--PMOD OLED
			pmod_cs   : OUT  STD_LOGIC;
			pmod_mosi : OUT  STD_LOGIC;
			pmod_sclk : OUT  STD_LOGIC;
			pmod_dc   : OUT  STD_LOGIC;
			pmod_res  : OUT  STD_LOGIC;
			pmod_vbat : OUT  STD_LOGIC;
			pmod_vdd  : OUT  STD_LOGIC;
		--Switches
			btn       : IN   STD_LOGIC_VECTOR(03 downto 00);	-- 4 BUTTONs on FPGA board
			switch    : IN   STD_LOGIC_VECTOR(03 downto 00);	-- 4 SWITCHs on FPGA board
		--LEDs
			led       : OUT	 STD_LOGIC_VECTOR(03 downto 00);	-- 4 LEDs on FPGA board
			led_r     : OUT	 STD_LOGIC_VECTOR(03 downto 00);	-- 4 LEDs on FPGA board -- RED
			led_g     : OUT	 STD_LOGIC_VECTOR(03 downto 00);	-- 4 LEDs on FPGA board -- GREEN
			led_b     : OUT	 STD_LOGIC_VECTOR(03 downto 00)	  -- 4 LEDs on FPGA board -- BLUE
	);
end fpga_top;

architecture RTL of fpga_top is

	component clk_wiz_0
	port
	(
		-- Clock in ports
		clk_in1	: in     STD_LOGIC;
		-- Clock out ports
		clk_100	: out    STD_LOGIC;
		clk_36 	: out    STD_LOGIC
	);
	end component;

  constant NUM_SW  : natural := 4;
  constant NUM_SWW : natural := positive(floor(log2(real(NUM_SW)))); -- 2

  constant A : natural := (NUM_SWW+1)*(NUM_SW+1)*NUM_SWW - 1; -- 3*5*2-1 = 29
  constant B : natural := A - NUM_SWW;                        --           27
  constant C : natural := B - 1;                              --           26
  constant D : natural := C - (NUM_SWW+1)*NUM_SW + 1;         -- 26-12+1 = 15
  constant E : natural := D - 1;                              --           14
  constant F : natural := E - NUM_SWW;                        --           12
  constant G : natural := F - 1;                              --           11
  constant H : natural := G - (NUM_SWW+1)*NUM_SW + 1;         -- 11-12+1 = 0

  subtype RES_IDX is natural range 0 to A;
  type ABC is array (0 to 7) of RES_IDX;
  constant RES_IDXS : ABC := (A,B,C,D,E,F,G,H);

  -- mixed language: verilog priority encoder src
  component arith_reduce_ones_veri
    generic
    (
      INPUT_WIDTH : integer
    );
    port
    (
    -- x : inout std_logic;
      arr_in      : in  std_logic_vector(NUM_SW-1 downto 0);
      cnt_out     : out std_logic_vector(NUM_SWW downto 0);
      cum_cnt_out : out std_logic_vector((NUM_SWW+1)*NUM_SW - 1 downto 0)
    );
  end component;

	--OLED
	type states_oled is ( Idle, SetupScreen, SendReq, WaitRsp, WRITE_SAMPLE);

	signal state_oled      : states_oled;
	signal state_oled_next : states_oled;

	constant OledSetupArray : ArrayOledSetup(0 to 16) := human2ArrOled(
     (
        (6,0,'s'),(7,0,'u'),(8,0,'m'),(10,0,'c'),(11,0,'u'),(12,0,'m'),(13,0,'s'),(14,0,'u'),(15,0,'m'),
        (0,1,'V'),(1,1,'H'),(2,1,'D'),(3,1,'L'),
    	  (0,2,'v'),(1,2,'e'),(2,2,'r'),(3,2,'i'),
     ));

	signal oled_count    : integer;
	signal oled_req      : std_logic;
	signal oled_req_addr : std_logic_vector(07 downto 00);
	signal oled_req_data : std_logic_vector(07 downto 00);
	signal oled_rsp      : std_logic;

  signal clk_100M : std_logic := '0';
  signal clk_36M  : std_logic := '0';
  signal nrst_n   : std_logic := '0';

  signal dsw      : std_logic_vector(NUM_SW-1 downto 0) := (others => '0');
  signal dsw_prev : std_logic_vector(NUM_SW-1 downto 0) := (others => '0');
  signal results  : std_logic_vector(A downto 0) := (others => '0');

begin

	--led(0) <= ;
	--led(1) <= ;
	--led(2) <= ;
	--led(3) <= ;

	--led_r <= ;
	--led_g <= ;
	--led_b <= ;

PM_PLL : clk_wiz_0
	port map (
	-- Clock in ports
		clk_in1 			=> clk_pad,
	-- Clock out ports
		clk_100  			=> clk_100M
	);

--#################################################################################################
--
-- input to HWUT modules -- debounced switches
--
--#################################################################################################
deb_sw : for i in natural range 0 to 3 generate
  begin
    deb_i : entity work.debounce
    port map(
      clk   => clk_100M,
      reset => rst_n,
      sw    => switch(i),
      db    => dsw(i)
    );
  end generate;

--#################################################################################################
--
-- HWUT modules
--
--#################################################################################################
--#################################################################################################
--
--
--
--#################################################################################################
REDUCE_ONES_vhdl : entity work.arith_reduce_ones_vhdl
  generic map(
    INPUT_WIDTH => NUM_SW,
    INPUT_MSB   => NUM_SW-1,
    CNT_MSB     => NUM_SWW,
    CUM_CNT_MSB => (NUM_SWW+1)*NUM_SW-1
  )
  port map(
    arr_in      => dsw,
    cnt_out     => results(A downto B),
    cum_cnt_out => results(C downto D)
  );
--#################################################################################################
--
--
--
--#################################################################################################
REDUCE_ONES_veri : arith_reduce_ones_veri
  generic map(
    INPUT_WIDTH => NUM_SW
  )
  port map(
    arr_in      => dsw,
    cnt_out     => results(E downto F),
    cum_cnt_out => results(G downto H)
  );
--#################################################################################################
--
-- HWUT outputs
--
--#################################################################################################
--#################################################################################################
--
-- OLED
--
--#################################################################################################
nrst_n  <= not rst_n;
PM_OLED : entity work.PmodOLEDCtrl
	generic map (
		G_IN_SIM	=> G_IN_SIM
	)
	port map(
		CLK  => clk_100M,
		RST  => nrst_n,
		CS   => pmod_cs,
		SDIN => pmod_mosi,
		SCLK => pmod_sclk,
		DC   => pmod_dc,
		RES  => pmod_res,
		VBAT => pmod_vbat,
		VDD  => pmod_vdd,

		req      => oled_req,
		req_addr => oled_req_addr,
		req_data => oled_req_data,
		rsp      => oled_rsp
	);

p_setup_oled : process ( clk_100M, rst_n )

		variable hex_digit	: STD_LOGIC_VECTOR(03 downto 00);
    variable cnt_digit  : std_logic_vector(4 downto 0);

	begin
		if ( rst_n = '0' ) then

			state_oled      <= SetupScreen;
			state_oled_next <= SetupScreen;
			oled_count      <= 0;
      dsw_prev        <= (others => '0');
			oled_req        <= '0';
			oled_req_addr   <= (others=>'0');
			oled_req_data   <= (others=>'0');

		elsif rising_edge( clk_100M ) then

			case state_oled is
				WHEN SetupScreen =>

					oled_req_addr(07 downto 04) <= STD_LOGIC_VECTOR( to_UNSIGNED( OledSetupArray(oled_count).pos_x ,4 ) );
					oled_req_addr(03 downto 00) <= STD_LOGIC_VECTOR( to_UNSIGNED( OledSetupArray(oled_count).pos_y ,4 ) );
					oled_req_data               <= OledSetupArray(oled_count).char;
					state_oled                  <= SendReq;

					if ( oled_count = OledSetupArray'HIGH ) then
						state_oled_next <= IDLE;
            dsw_prev        <= (others => '0');
					else
						state_oled_next <= SetupScreen;
						oled_count      <= oled_count + 1;
					end if;

				WHEN IDLE =>

					if (dsw_prev /= dsw) then
						state_oled       <= WRITE_SAMPLE;
						state_oled_next  <= IDLE;
            dsw_prev         <= dsw;
						oled_count       <= 0;
					end if;

				WHEN WRITE_SAMPLE =>
        --#################################################################################################
        --
        -- from clocked priority encoder implemented in VHDL
        --
        --#################################################################################################

          if oled_count >  then
            oled_count <= oled_count + 3;
            cnt_digit := results(to_integer(to_unsigned(oled_count,cnt_digit'length)) downto to_integer(to_unsigned(oled_count-2,cnt_digit'length)));
            hex_digit	:= std_logic_vector(to_unsigned(to_integer(unsigned(cnt_digit)),hex_digit'length));
          else then
            oled_count <= (others => '0');
            state      <= IDLE;
          end if;

					oled_req_addr(07 downto 04)	<= "1000";		--(8,0)
					oled_req_addr(03 downto 00)	<= "0000";

        -- below conversion of A or above hex to decimal not needed in priority encoder example, but is being retained for ease of adaptation of code
					if ( hex_digit <= "1001" ) then
						oled_req_data	<= "0011" & hex_digit;		--hex_digit + 0x30 which is an 0
					else
						hex_digit	:= STD_LOGIC_VECTOR( UNSIGNED(hex_digit) - to_UNSIGNED(9,4) );
						oled_req_data	<= "0100" & hex_digit;		--hex_digit-10 + 0x41 which is an A
					end if;

					state_oled					<= SendReq;
					state_oled_next			<= IDLE;

				WHEN SendReq =>
					oled_req   <= '1';
					state_oled <= WaitRsp;

				WHEN WaitRsp =>
					if ( oled_rsp = '1' ) then
						oled_req   <= '0';
						state_oled <= state_oled_next;
					end if;
			end case;
		end if;

	end process;

end RTL;
