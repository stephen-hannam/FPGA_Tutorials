library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.helper_funcs.all;

entity arith_reduce_ones_vhdl is
  generic(
    INPUT_WIDTH : natural := 4,
    INPUT_MSB   : natural := 3,
    CNT_MSB     : natural := 2,
    CUM_CNT_MSB : natural := (2+1)*4-1
  );
  port(
    arr_in      : in  std_logic_vector(INPUT_MSB downto 0);
    cnt_out     : out std_logic_vector(CNT_MSB downto 0);
    cum_cnt_out : out std_logic_vector(CUM_CNT_MSB downto 0)
  );
end arith_reduce_ones;

architecture BEH of arith_reduce_ones is
  constant CUM_UPP : natural := CNT_MSB + 1;
begin
  scan_reduce : process(arr_in)
    -- PLO: variables and use in loops + multi-driven nets
    variable v_cnt : unsigned(CNT_MSB downto 0) := (others => '0');
  begin
    cnt_out     <= std_logic_vector(v_cnt);
    cum_cnt_out <= (others => '0');
    for i in natural range 0 to INPUT_MSB loop
      v_cnt := v_cnt + arr_in(i);
      -- cnt_out  <= cnt_out + arr_in(i); -- why won't this work?
      if arr_in(i) = '1' then
        if i = 0 then
          cum_cnt_out(0 to CUM_UPP) <= (CUM_UPP => '1', others => '0');
        elsif then
          cum_cnt_out(i*CUM_UPP to (i+1)*CUM_UPP) <= cum_cnt_out((i-1)*CUM_UPP to i*CUM_UPP) + 1;
        end if;
      end if;
    end loop;

  end process;
end BEH;
