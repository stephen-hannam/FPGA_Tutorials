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

  -- mixed language: verilog priority encoder src
  component pri_enc
    generic
    (
      WIDTH : integer
    );
    port
    (
    -- x : inout std_logic;
      i : in  std_logic_vector(WIDTH-1 downto 0);
      c : in  std_logic_vector(WIDTH-1 downto 0);
      o : out std_logic_vector(WIDTH-1 downto 0)
    );
  end component;

	--OLED
	type states_oled is ( Idle, SetupScreen, SendReq, WaitRsp, WRITE_SAMPLE_1, WRITE_SAMPLE_2, WRITE_SAMPLE_3 );

	signal state_oled      : states_oled;
	signal state_oled_next : states_oled;

	constant OledSetupArray : ArrayOledSetup(0 to 17) := human2ArrOled(
     ((0,0,'V'),(1,0,'H'),(2,0,'D'),(3,0,'L'),(4,0,':'),(5,0,' '),
    	(0,1,'v'),(1,1,'e'),(2,1,'r'),(3,1,'i'),(4,1,':'),(5,1,' '),
    	(0,2,'n'),(1,2,'a'),(2,2,'i'),(3,2,'v'),(4,2,'e'),(5,2,' ')));

  signal clk_100M : std_logic := '0';
  signal clk_36M  : std_logic := '0';
  signal nrst_n   : std_logic := '0';

  constant proc_type : std_logic  := '0';  -- 0 = clk'd, 1 = combinational
  constant NUM_SW    : positive := 4;
  constant NUM_SWW   : positive := positive(ceil(log2(real(NUM_SW))));

  signal dsw              : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
  signal msb_sw           : STD_LOGIC_VECTOR(NUM_SWW downto 0) := (others => '0');
  signal msb_sw_prev      : STD_LOGIC_VECTOR(NUM_SWW downto 0) := (others => '0');
  signal sw_veri          : STD_LOGIC_VECTOR(NUM_SW-1 downto 0) := (others => '0');
  signal msb_sw_veri      : STD_LOGIC_VECTOR(NUM_SWW downto 0) := (others => '0');
  signal msb_sw_veri_prev : STD_LOGIC_VECTOR(NUM_SWW downto 0) := (others => '0');
  signal msb_sw_naive      : STD_LOGIC_VECTOR(NUM_SWW downto 0) := (others => '0');
  signal msb_sw_naive_prev : STD_LOGIC_VECTOR(NUM_SWW downto 0) := (others => '0');
	signal oled_count       : INTEGER;
	signal oled_req         : STD_LOGIC;
	signal oled_req_addr    : STD_LOGIC_VECTOR(07 downto 00);
	signal oled_req_data    : STD_LOGIC_VECTOR(07 downto 00);
	signal oled_rsp         : STD_LOGIC;

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
-- naive but valid implementation
--
--#################################################################################################
naive : process(clk_100M)
begin
  if (rising_edge(clk_100M)) then
    if (dsw(3) = '1') then
      msb_sw_naive <= std_logic_vector(to_UNSIGNED(4,msb_sw_naive'length));
    elsif (dsw(2) = '1') then
      msb_sw_naive <= std_logic_vector(to_UNSIGNED(3,msb_sw_naive'length));
    elsif (dsw(1) = '1') then
      msb_sw_naive <= std_logic_vector(to_UNSIGNED(2,msb_sw_naive'length));
    elsif (dsw(0) = '1') then
      msb_sw_naive <= std_logic_vector(to_UNSIGNED(1,msb_sw_naive'length));
    else
      msb_sw_naive <= (others => '0');
    end if;
  end if;
end process;
--#################################################################################################
--
-- optionally clocked or combinational priority encoder (TRUE encoder) implemented in VHDL
--
--#################################################################################################
PRI_ENC_vhdl : entity work.priorityEncoder
  generic map(
    proc_type => proc_type,
    NUM_SW    => NUM_SW,
    NUM_SWW   => NUM_SWW
  )
  port map(
    clk    => clk_100M,
    switch => dsw,
    msb_sw => msb_sw
  );

--#################################################################################################
--
-- combinational priority encoder (actually a priority FILTER, not a TRUE encoder) implemented in verilog
--
--#################################################################################################
PRI_ENC_veri : pri_enc
  generic map(
    WIDTH => NUM_SW
  )
  port map(
    i => (others => '1'),
    c => dsw,
    o => sw_veri
  );
msb_veri_encode : process(clk_100M)
  begin
    if (rising_edge(clk_100M)) then
      msb_sw_veri <= (others => '0');   -- NB: w/o this, latch occurs, shows previous value instead of 0
      for i in natural range 0 to 3 loop
        if (sw_veri(i) = '1') then
          msb_sw_veri <= std_logic_vector(to_UNSIGNED(i+1,msb_sw_veri'length));
        end if;
      end loop;
    end if;
  end process;

--#################################################################################################
--
-- HWUT outputs
--
--#################################################################################################
--#################################################################################################
--
-- LEDs
--
--#################################################################################################
msb_led : process(clk_100M)
  begin
    if (rising_edge(clk_100M)) then
      for i in natural range 1 to 4 loop
        led(i-1)  <= '0';
        if (msb_sw = std_logic_vector(to_UNSIGNED(i,msb_sw'length))) then
          led(i-1)  <= '1';
        end if;
      end loop;
    end if;
  end process;
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

	begin
		if ( rst_n = '0' ) then

			state_oled       <= SetupScreen;
			state_oled_next  <= SetupScreen;
			oled_count       <= 0;
      msb_sw_prev      <= (others => '0');
      msb_sw_veri_prev <= (others => '0');
      msb_sw_naive_prev <= (others => '0');
			oled_req         <= '0';
			oled_req_addr    <= (others=>'0');
			oled_req_data    <= (others=>'0');

		elsif rising_edge( clk_100M ) then

			case state_oled is
				WHEN SetupScreen =>

					oled_req_addr(07 downto 04) <= STD_LOGIC_VECTOR( to_UNSIGNED( OledSetupArray(oled_count).pos_x ,4 ) );
					oled_req_addr(03 downto 00) <= STD_LOGIC_VECTOR( to_UNSIGNED( OledSetupArray(oled_count).pos_y ,4 ) );
					oled_req_data               <= OledSetupArray(oled_count).char;
					state_oled                  <= SendReq;

					if ( oled_count = OledSetupArray'HIGH ) then
						state_oled_next  <= IDLE;
            msb_sw_prev      <= (others => '0');
            msb_sw_veri_prev <= (others => '0');
					else
						state_oled_next  <= SetupScreen;
						oled_count       <= oled_count + 1;
					end if;

				WHEN IDLE =>

					if (msb_sw /= msb_sw_prev) then
						state_oled       <= WRITE_SAMPLE_1;
						state_oled_next  <= IDLE;
            msb_sw_prev      <= msb_sw;
						--oled_count       <= 0;
          elsif (msb_sw_veri /= msb_sw_veri_prev) then
						state_oled       <= WRITE_SAMPLE_2;
						state_oled_next  <= IDLE;
            msb_sw_veri_prev <= msb_sw_veri;
						--oled_count       <= 0;
    		  elsif (msb_sw_naive /= msb_sw_naive_prev) then
						state_oled       <= WRITE_SAMPLE_3;
						state_oled_next  <= IDLE;
            msb_sw_naive_prev <= msb_sw_naive;
						--oled_count       <= 0;
					end if;

				WHEN WRITE_SAMPLE_1 =>
        --#################################################################################################
        --
        -- from clocked priority encoder implemented in VHDL
        --
        --#################################################################################################

					hex_digit	:= std_logic_vector(to_unsigned(to_integer(unsigned(msb_sw)),hex_digit'length));

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

				WHEN WRITE_SAMPLE_2 =>
        --#################################################################################################
        --
        -- from combinational priority encoder implemented in verilog
        --
        --#################################################################################################

					hex_digit	:= std_logic_vector(to_unsigned(to_integer(unsigned(msb_sw_veri)),hex_digit'length));

					oled_req_addr(07 downto 04)	<= "1000";		--(8,1)
					oled_req_addr(03 downto 00)	<= "0001";

        -- below conversion of A or above hex to decimal not needed in priority encoder example, but is being retained for ease of adaptation of code
					if ( hex_digit <= "1001" ) then
						oled_req_data	<= "0011" & hex_digit;		--hex_digit + 0x30 which is an 0
					else
						hex_digit	:= STD_LOGIC_VECTOR( UNSIGNED(hex_digit) - to_UNSIGNED(9,4) );
						oled_req_data	<= "0100" & hex_digit;		--hex_digit-10 + 0x41 which is an A
					end if;

					state_oled					<= SendReq;
					state_oled_next			<= IDLE;

				WHEN WRITE_SAMPLE_3 =>
        --#################################################################################################
        --
        -- from naive (non-generic) implementation
        --
        --#################################################################################################

					hex_digit	:= std_logic_vector(to_unsigned(to_integer(unsigned(msb_sw_naive)),hex_digit'length));

					oled_req_addr(07 downto 04)	<= "1000";		--(8,2)
					oled_req_addr(03 downto 00)	<= "0010";

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
