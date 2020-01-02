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
		clk_36 	: out    STD_LOGIC
		clk_50 	: out    STD_LOGIC
		clk_70 	: out    STD_LOGIC
		clk_100	: out    STD_LOGIC;
	);
	end component;

  -- domain states: control selector on MUX
  type states_domain is (D36M, D70M, D100M);
  signal state_domain : states_domain := D36M;

	-- OLED
	signal oled_count    : INTEGER;
	signal oled_req      : STD_LOGIC;
	signal oled_req_addr : STD_LOGIC_VECTOR(07 downto 00);
	signal oled_req_data : STD_LOGIC_VECTOR(07 downto 00);
	signal oled_rsp      : STD_LOGIC;

	type states_oled is (Idle, SetupScreen, SendReq, WaitRsp, WRITE_SAMPLE);

	signal state_oled      : states_oled;
	signal state_oled_next : states_oled;

	constant OledSetupArray : ArrayOledSetup(0 to ) := human2ArrOled(
    ((),(),
     (),(),
     (),(),
     (),())
	);

  -- test units
  signal clk_100M : std_logic := '0';
  signal clk_70M  : std_logic := '0';
  signal clk_50M  : std_logic := '0';
  signal clk_36M  : std_logic := '0';
  signal nrst_n   : std_logic := '0';

  constant WIDTH  : positive := 4;
  --constant NUM_SWW   : positive := positive(floor(log2(real(NUM_SW))));

  signal dsw       : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
  signal dbtn      : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
  signal dbtn_prev : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
  signal dbtn_fe   : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
  signal cross     : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
  signal crossed   : STD_LOGIC := '0';

  signal sw_50M       : STD_LOGIC_VECTOR(WIDTH-1 downto 0) := (others => '0');
  signal sw_50M_prev  : STD_LOGIC_VECTOR(WIDTH-1 downto 0) := (others => '0');
  signal dsw_36M      : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
  signal dsw_70M      : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
  signal dsw_100M     : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
  signal dsw_36M_50M  : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
  signal dsw_70M_50M  : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
  signal dsw_100M_50M : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');

begin

	--led_r <= ;
	--led_g <= ;
	--led_b <= ;

PM_PLL : clk_wiz_0
	port map(
	-- Clock in ports
		clk_in1 	=> clk_pad,
	-- Clock out ports
		clk_36   	=> clk_36M,
		clk_50   	=> clk_50M,
		clk_70   	=> clk_70M,
		clk_100  	=> clk_100M
	);

--#################################################################################################
--
-- input to HWUT modules -- debounced switches
--
--#################################################################################################
deb_sw_36M : for i in natural range 0 to 3 generate
  begin
    deb_i : entity work.debounce
    port map(
      clk   => clk_36M,
      reset => rst_n,
      sw    => switch(i),
      db    => dsw_36M(i)
    );
  end generate;
deb_sw_70M : for i in natural range 0 to 3 generate
  begin
    deb_i : entity work.debounce
    port map(
      clk   => clk_70M,
      reset => rst_n,
      sw    => switch(i),
      db    => dsw_70M(i)
    );
  end generate;
deb_sw_100M : for i in natural range 0 to 3 generate
  begin
    deb_i : entity work.debounce
    port map(
      clk   => clk_100M,
      reset => rst_n,
      sw    => switch(i),
      db    => dsw_100M(i)
    );
  end generate;

--#################################################################################################
--
-- test modules - PLO = Primary Learning Objective
--
--#################################################################################################
falling_edge_flags : for i in natural range 0 to 3 generate -- PLO: VHDL for generate
  begin
    dbtn_fe(i)  <= (dbtn(i) = '0') and (dbtn_prev(i) = '1');
  end generate;
switch_domains : process(clk_50M,reset)
  begin
    if (reset = '0') then
      state_domain  <= D36M;
      led           <= (others => '0');
    elsif (rising_edge(clk_50M) and dbtn_fe(3) = '1') then
      case (state_domain) is
        when D36M  =>
          state_domain <= D70M;
          led          <= (0 => '1', others => '0'); -- PLO: VHDL aggregates
        when D70M  =>
          state_domain <= D100M;
          led          <= (1 => '1', others => '0'); -- PLO: VHDL aggregates
        when D100M =>
          state_domain <= D36M;
          led          <= (2 => '1', others => '0'); -- PLO: VHDL aggregates
      end case;
    end if;
  end process;
--#################################################################################################
--
-- 50M
--
--#################################################################################################
deb_btn_50M : entity work.debounce
  port map(
    clk   => clk_50M,
    reset => rst_n,
    sw    => btn(3),
    db    => dbtn(3)
  );
falling_edge_dbtn_50M : process(clk_50M,reset)
  begin
    if (reset = '0') then
      dbtn_prev(3)  <= '0';
    elsif (rising_edge(clk_50M)) then
      dbtn_prev(3)  <= dbtn(3);
    end if;
  end process;
--#################################################################################################
--
-- 36M
--
--#################################################################################################
deb_btn_36M : entity work.debounce
  port map(
    clk   => clk_36M,
    reset => rst_n,
    sw    => btn(0),
    db    => dbtn(0)
  );
falling_edge_dbtn_36M : process(clk_36M,reset)
  begin
    if (reset = '0') then
      dbtn_prev(0)  <= '0';
    elsif (rising_edge(clk_36M)) then
      dbtn_prev(0)  <= dbtn(0);
    end if;
  end process;
--#################################################################################################
--
-- 70M
--
--#################################################################################################
deb_btn_70M : entity work.debounce
  port map(
    clk   => clk_70M,
    reset => rst_n,
    sw    => btn(1),
    db    => dbtn(1)
  );
falling_edge_dbtn_70M : process(clk_70M,reset)
  begin
    if (reset = '0') then
      dbtn_prev(1)  <= '0';
    elsif (rising_edge(clk_70M)) then
      dbtn_prev(1)  <= dbtn(1);
    end if;
  end process;
--#################################################################################################
--
-- 100M
--
--#################################################################################################
deb_btn_100M : entity work.debounce
  port map(
    clk   => clk_100M,
    reset => rst_n,
    sw    => btn(2),
    db    => dbtn(2)
  );
falling_edge_dbtn_100M : process(clk_100M,reset)
  begin
    if (reset = '0') then
      dbtn_prev(2)  <= '0';
    elsif (rising_edge(clk_100M)) then
      dbtn_prev(2)  <= dbtn(2);
    end if;
  end process;


--#################################################################################################
--
-- Option 1
--
--#################################################################################################
HWUT_36M : typische
  generic map(
    WIDTH => WIDTH
  )
  port map(
    clk_a   => clk_36M,
    rst_n_a => rst_n,
    clk_b   => clk_50M,
    cntl_a  => dbtn_fe(0),
    data_a  => dsw_36M,
    data_b  => dsw_36M_50M,
    cntl_b  => cross(0)
  );
HWUT_70M : typische
  generic map(
    WIDTH => WIDTH
  )
  port map(
    clk_a   => clk_70M,
    rst_n_a => rst_n,
    clk_b   => clk_50M,
    cntl_a  => dbtn_fe(1),
    data_a  => dsw_70M,
    data_b  => dsw_70M_50M,
    cntl_b  => cross(1)
  );
HWUT_100M : typische
  generic map(
    WIDTH => WIDTH
  )
  port map(
    clk_a   => clk_100M,
    rst_n_a => rst_n,
    clk_b   => clk_50M,
    cntl_a  => dbtn_fe(2),
    data_a  => dsw_100M,
    data_b  => dsw_100M_50M,
    cntl_b  => cross(2)
  );

  dsw <= dsw_100M_36M   when cross = "001" else
         dsw_100M_70M   when cross = "010" else
         dsw_100M_100M  when cross = "100" else
         (others => '0');

  crossed <=  '1'  when cross = "001" else
              '1'  when cross = "010" else
              '1'  when cross = "100" else
              '0';

--#################################################################################################
--
-- Option 2
--
--#################################################################################################
--#################################################################################################
--
-- Option 3
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
		G_IN_SIM			=> G_IN_SIM
	)
	port map(
		CLK => clk_50M,
		RST => nrst_n,

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

p_setup_oled : process ( clk_50M, rst_n )

		variable hex_digit	: STD_LOGIC_VECTOR(03 downto 00);

	begin
		if ( rst_n = '0' ) then

			state_oled      <= SetupScreen;
			state_oled_next <= SetupScreen;
			oled_count      <= 0;
      dsw_prev        <= (others => '0');
			oled_req        <= '0';
			oled_req_addr   <= (others=>'0');
			oled_req_data   <= (others=>'0');

		elsif rising_edge( clk_50M ) then

			case state_oled is
				WHEN SetupScreen =>

					oled_req_addr(07 downto 04) <= STD_LOGIC_VECTOR( to_UNSIGNED( OledSetupArray(oled_count).pos_x ,4 ) );
					oled_req_addr(03 downto 00) <= STD_LOGIC_VECTOR( to_UNSIGNED( OledSetupArray(oled_count).pos_y ,4 ) );
					oled_req_data               <= OledSetupArray(oled_count).char;
					state_oled                  <= SendReq;

					if ( oled_count = OledSetupArray'HIGH ) then
						state_oled_next	<= IDLE;
            sw_50M_prev   <= (others => '0');
					else
						state_oled_next <= SetupScreen;
						oled_count      <= oled_count + 1;
					end if;

				WHEN IDLE =>
          if (dsw /= dsw_prev) then
						state_oled      <= WRITE_SAMPLE;
						state_oled_next <= IDLE;
            dsw_prev        <= dsw;
						oled_count      <= 0;
					end if;

				WHEN WRITE_SAMPLE =>
        --#################################################################################################
        --
        -- OLED customized display outputs
        --
        --#################################################################################################

					oled_req_addr(07 downto 04)	<= "1000";		--(8,1)
					oled_req_addr(03 downto 00)	<= "0001";
					hex_digit	:= std_logic_vector(to_unsigned(to_integer(unsigned(dsw)),hex_digit'length));

					if ( hex_digit <= "1001" ) then
						oled_req_data	<= "0011" & hex_digit;		--hex_digit + 0x30 which is an 0
					else
						hex_digit	:= STD_LOGIC_VECTOR( UNSIGNED(hex_digit) - to_UNSIGNED(9,4) );
						oled_req_data	<= "0100" & hex_digit;		--hex_digit-10 + 0x41 which is an A
					end if;

					state_oled      <= SendReq;
					state_oled_next <= IDLE;

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
