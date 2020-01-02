library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debounce is
	Port (
	clk   : in  STD_LOGIC;
	reset : in  STD_LOGIC;
	sw    : in  STD_LOGIC;
	db    : out STD_LOGIC);
end debounce;

architecture Behavioral of debounce is

	-- free running counter will count to "11111111111111111111" (2^20 - 1)
	-- tick will be '1' when the count goes to 0
	-- 2^20 * 1/100MHz = 10.5ms
	constant N : integer := 20;
	signal count, count_next : unsigned (N-1 downto 0);
	signal tick : std_logic;
	type state_type is (zero, wait_11, wait_12, wait_13, one, wait_01, wait_02, wait_03);
	signal curr_state, next_state : state_type;

begin
	------------------------------------------------------
	-- counter to generate a tick every 10.5ms
	------------------------------------------------------
	counter : process(clk) begin
		if rising_edge(clk) then
			count <= count_next;
		end if;
	end process counter;

	count_next <= count + 1;
	-- output tick
	tick <= '1' when count = 0 else '0';
	------------------------------------------------------
	-- FSM
	------------------------------------------------------
	-- state register
	state_register : process (clk,reset) begin
		if reset = '0' then
			curr_state <= zero;
		elsif rising_edge(clk) then
			curr_state <= next_state;
		end if;
	end process state_register;
	-- next state/output logic
	next_state_logic : process (curr_state, sw, tick) begin
		next_state <= curr_state;
		db <= '0';
		case curr_state is
			when zero =>
				if sw = '1' then
					next_state <= wait_11;
				end if;
			when wait_11 =>
				if sw = '0' then
					next_state <= zero;
				else -- if sw = '1'
					if tick = '1' then
						next_state <= wait_12;
					end if;
				end if;
			when wait_12 =>
				if sw = '0' then
					next_state <= zero;
				else -- if sw = '1'
					if tick = '1' then
						next_state <= wait_13;
					end if;
				end if;
			when wait_13 =>
				if sw = '0' then
					next_state <= zero;
				else -- if sw = '1'
					if tick = '1' then
						next_state <= one;
					end if;
				end if;
			when one =>
				db <= '1';
				if sw = '0' then
					next_state <= wait_01;
				end if;
			when wait_01 =>
				if sw = '0' then
					next_state <= wait_02;
				else -- if sw = '1'
					if tick = '1' then
						db <= '1';
						next_state <= one;
					end if;
				end if;
			when wait_02 =>
				if sw = '0' then
					next_state <= wait_03;
				else -- if sw = '1'
					if tick = '1' then
						db <= '1';
						next_state <= one;
					end if;
				end if;
			when wait_03 =>
				if sw = '0' then
					next_state <= zero;
				else -- if sw = '1'
					if tick = '1' then
						db <= '1';
						next_state <= one;
					end if;
				end if;
		end case;
	end process next_state_logic;

end Behavioral;
