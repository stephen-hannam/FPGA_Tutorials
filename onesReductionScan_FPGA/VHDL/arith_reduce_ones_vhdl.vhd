library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.helper_funcs.all;

entity arith_reduce_ones_vhdl is
  generic(
    INPUT_WIDTH : natural := 4;
    INPUT_MSB   : natural := 3;
    CNT_MSB     : natural := 2;
    CUM_CNT_MSB : natural := (2+1)*4-1
  );
  port(
    arr_in      : in  std_logic_vector(INPUT_MSB downto 0);
    cnt_out     : out std_logic_vector(CNT_MSB downto 0);
    cum_cnt_out : out std_logic_vector(CUM_CNT_MSB downto 0)
  );
end arith_reduce_ones_vhdl;

architecture BEH of arith_reduce_ones_vhdl is
  constant CUM_UPP : natural := CNT_MSB + 1;
begin
  scan_reduce : process(arr_in)
    -- PLO: variables and use in loops + multi-driven nets
    variable v_cnt      : unsigned(CNT_MSB downto 0)     := (others => '0');
    variable v_cum_sum  : unsigned(CUM_CNT_MSB downto 0) := (others => '0');
  begin
    cnt_out     <= std_logic_vector(v_cnt);
    cum_cnt_out <= std_logic_vector(v_cum_sum);
    v_cnt := (others => '0');
    for i in natural range INPUT_MSB downto 1 loop
      -- cnt_out  <= cnt_out + arr_in(i); -- why won't this work? ans: multi-driven
      if arr_in(i) = '1' then
        v_cnt := v_cnt + 1;
        v_cum_sum((i+1)*CUM_UPP-1 downto i*CUM_UPP) := v_cum_sum(i*CUM_UPP-1 downto (i-1)*CUM_UPP) + 1;
      else
        v_cum_sum((i+1)*CUM_UPP-1 downto i*CUM_UPP) := (others => '0');
      end if;
    end loop;

    if arr_in(0) = '1' then
      v_cnt := v_cnt + 1;
      v_cum_sum(CUM_UPP-1 downto 0) := (0 => '1', others => '0');
    else
      v_cum_sum(CUM_UPP-1 downto 0) := (others => '0');
    end if;

  end process;
end BEH;
