------------------------------------------------------------------------------------------------
-- Copyright 2019 Stephen Ross Hannam

-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.gen_win_types.all;
use work.morph_filter.all;

package sum_std_logic_vector_bits is
  function sum_std_logic_vector(arr_in : std_logic_vector) return natural;
  function cast_vote(arr_in : std_logic_vector) return std_logic;
end package;

package body sum_std_logic_vector_bits is
  function sum_std_logic_vector(arr_in : std_logic_vector) return natural is
    variable res: natural range 0 to MAX_SUM := 0;
  begin
    res := 0;
    sum_loop : for i in arr_in'range loop
      if (arr_in(i) = '1') then
        res := res + 1;
      end if;
    end loop sum_loop;
    return res;
  end function sum_std_logic_vector;

  -- can use this for very large annuli if timing can't be met, and exact sums aren't needed
  function cast_vote(arr_in : std_logic_vector) return std_logic is
  begin
    if (sum_std_logic_vector(arr_in) = arr_in'length) then
      return '1';
    else
      return '0';
    end if;
  end function cast_vote;
end package body;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use work.gen_win_types.all;
use work.morph_filter.all;
use work.sum_std_logic_vector_bits.all;
use IEEE.math_real.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity generic_rows is
  Generic (
            ROW_TYPE        : string := "shreg_only";
            WIN_LEN         : positive := 1;
            BUS_WIDTH       : positive := 1;
            ROW_NUM         : natural := 0;
            SUM_LEN         : positive := 1;
            DETECTION_CELLS : array_of_indices := (0,0);
            FILL_TYPE       : DETECT_TYPE := '0';
            MID_RING        : boolean := false
          );
  Port    (
            clk        : in  std_logic;
            data_in    : in  std_logic_vector (BUS_WIDTH - 1 downto 0);
            wr_en      : in  std_logic;
            fill_en    : in  std_logic;
            active_sum : out natural range 0 to MAX_SUM;
            vote       : out std_logic;
            mid_clear  : out std_logic;
            data_out   : out std_logic_vector (BUS_WIDTH - 1 downto 0)
          );
end generic_rows;

architecture Behavioral of generic_rows is

  type row_ffs is array(natural range 0 to WIN_LEN - 1) of std_logic_vector(BUS_WIDTH - 1 downto 0);
  signal ffs : row_ffs := (others => (others => '0'));

begin

  shreg_only : if ROW_TYPE = "shreg_only" generate
  begin
    data_out <= ffs(WIN_LEN - 1);
    shregs : process(clk)
    begin
      if (rising_edge(clk)) then
        if (wr_en = '1') then
          ffs(0) <= data_in;
        end if;
        Connect_FFs : for k in 1 to WIN_LEN - 1 loop
          if (wr_en = '1') then
            ffs(k) <= ffs(k - 1);
          end if;
        end loop Connect_FFs;
      end if;
    end process;
  end generate;

  enclosed_strel_detect_w_fill : if ROW_TYPE = "enclosed_strel_detect_w_fill" generate
    signal fill_with : std_logic;
    signal detecting_cells : std_logic_vector(DETECTION_CELLS'range) := (others => '0');
    signal fill_en_dq : std_logic := '0';
  begin
    fill_with <= FILL_TYPE;

    Gather_active_cells : for i in DETECTION_CELLS'range generate
      detecting_cells(i) <= ffs(DETECTION_CELLS(i))(0); -- LSBs of the bus
    end generate Gather_active_cells;

    data_out <= ffs(WIN_LEN - 1);
    send_detect_data : process(clk)
    begin
      if (rising_edge(clk)) then

        fill_en_dq <= fill_en;

        if (wr_en = '1') then
          ffs(0) <= data_in;
        end if;

        Connect_FFs : for k in 1 to WIN_LEN - 1 loop
          if (k < DETECTION_CELLS(0) or k > DETECTION_CELLS(DETECTION_CELLS'length - 1)) then
            if (wr_en = '1') then
              ffs(k) <= ffs(k - 1);
            end if;
          end if;
          if (k >= DETECTION_CELLS(0) and k <= DETECTION_CELLS(DETECTION_CELLS'length - 1)) then
            if (wr_en = '1') then
              ffs(k) <= ffs(k - 1);
            elsif (fill_en_dq = '1') then
              ffs(k) <= ffs(k - 1)(2 downto 1) & fill_with;
            end if;
          end if;
        end loop Connect_FFs;
        if (MID_RING) then
          mid_clear <= '1'; -- strobe
          active_sum <= sum_std_logic_vector(detecting_cells);
          if (ROW_NUM /= 0 and ROW_NUM /= WIN_LEN - 1 and DETECTION_CELLS'length >= 3) then
            if (sum_std_logic_vector(detecting_cells(1 to DETECTION_CELLS'length - 2)) /= 0) then
              mid_clear <= '0';
            end if;
          end if;
        else
          vote <= cast_vote(detecting_cells);
        end if;
      end if;
    end process;
  end generate;

end Behavioral;
