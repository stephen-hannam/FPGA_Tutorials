------------------------------------------------------------------------------------------------
-- Copyright 2019 Stephen Ross Hannam

-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.ALL;
use work.gen_win_types.all;
use work.morph_filter.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity generic_window is
  Generic (
            WIN_LEN      : positive;
            IMAGE_WIDTH  : positive;
            IMAGE_HEIGHT : positive;
            BUS_WIDTH    : positive := 3;
            BRAM_WIDTH   : positive := 36; -- whole number multiple of BUS_WIDTH
            ROW_TYPE     : string   := "shreg_only";
            ROW_MSB      : natural;
            COL_MSB      : natural
          );
  Port    (
            clk         : in  std_logic;
            rst_n       : in  std_logic;
            data_in     : in  std_logic_vector (BUS_WIDTH - 1 downto 0);
            data_out    : out std_logic_vector (BUS_WIDTH - 1 downto 0);
            screen_done : out std_logic;
            x           : out unsigned(COL_MSB downto 0);
            y           : out unsigned(ROW_MSB downto 0)
          );
end generic_window;

architecture Behavioral of generic_window is

  constant SUBPORTS_PER_FIFO : positive := BRAM_WIDTH/BUS_WIDTH; -- this must be a whole number
  constant NUM_FIFOS         : positive := positive(ceil(real(WIN_LEN)/real(SUBPORTS_PER_FIFO)));
  constant NUM_FIFOS_WHOLE   : natural  := natural(floor(real(WIN_LEN)/real(SUBPORTS_PER_FIFO)));
  constant LEFTOVER_PORTS    : natural  := WIN_LEN - NUM_FIFOS_WHOLE*SUBPORTS_PER_FIFO;
  constant CENTER            : natural  := natural(floor(real(WIN_LEN)/real(2)));
  constant ROW_MIN           : unsigned(ROW_MSB downto 0) := to_unsigned(WIN_LEN - 1, ROW_MSB+1);
  constant ROW_MAX           : unsigned(ROW_MSB downto 0) := to_unsigned(IMAGE_HEIGHT - 1, ROW_MSB+1);
  constant COL_MIN           : unsigned(COL_MSB downto 0) := to_unsigned(WIN_LEN - 1, COL_MSB+1);
  constant COL_MAX           : unsigned(COL_MSB downto 0) := to_unsigned(IMAGE_WIDTH - 1, COL_MSB+1);

  component FIFO_win
    generic (
              FWFT        : boolean := true; -- First Word Fall Thru
              FIFO_LENGTH : natural := IMAGE_WIDTH - WIN_LEN;
              DATA_DEPTH  : natural := BRAM_WIDTH
            );
    Port    (
              clk_in      : in  std_logic;
              read_en     : in  std_logic;
              write_en    : in  std_logic;
              data_in     : in  std_logic_vector (DATA_DEPTH - 1 downto 0);
              data_out    : out std_logic_vector (DATA_DEPTH - 1 downto 0);
              empty_flag  : out std_logic;
              full_flag   : out std_logic
            );
  end component FIFO_win;

  component generic_rows
    Generic (
              ROW_TYPE  : string   := ROW_TYPE;
              WIN_LEN   : positive := WIN_LEN;
              BUS_WIDTH : positive := BUS_WIDTH
            );
    Port    (
              clk       : in  std_logic;
              data_in   : in  std_logic_vector (BUS_WIDTH - 1 downto 0);
              wr_en     : in  std_logic;
              fill_en   : in  std_logic;
              data_out  : out std_logic_vector (BUS_WIDTH - 1 downto 0)
            );
  end component generic_rows;

  type fifo_multi_bus is array(natural range 0 to SUBPORTS_PER_FIFO - 1) of std_logic_vector(BUS_WIDTH - 1 downto 0);
  type multi_fifo_multi_bus is array(natural range <>) of fifo_multi_bus;

  signal data_out_w, data_in_w, data_out_g : std_logic_vector(BUS_WIDTH - 1 downto 0) := (others => '0');

  signal wr_en : std_logic;

  signal fifo_in_n, fifo_out_n : multi_fifo_multi_bus(0 to NUM_FIFOS - 1) := (others => (others => (others => '0')));

  type count_states is (WAITING, NEW_SCR, ACTIVE, END_SCR);
  signal count_state : count_states := WAITING;
  signal col_count   : unsigned(9 downto 0) := (others => '0');
  signal row_count   : unsigned(9 downto 0) := (others => '0');

begin

  data_in_w  <= data_in;
  data_out_g <= data_out_w when wr_en = '1' else (others => '0'); -- gating the output
  data_out   <= data_out_g;

  wr_en <= data_in(2) or data_in(1);

  process(clk)

    procedure step_coords is
    begin
      if (col_count < COL_MAX) then
        col_count <= col_count + 1;
      else
        col_count <= (others => '0');
        if (row_count < ROW_MAX) then
          row_count <= row_count + 1;
        else
          row_count <= (others => '0');
        end if;
      end if;
    end procedure;


  begin
    if (rst_n = '0') then

      count_state <= WAITING;

    elsif (rising_edge(clk)) then

      screen_done <= '0'; -- strobe
      x           <= (others => '0'); -- strobe
      y           <= (others => '0'); -- strobe

      if (wr_en = '1') then
        case (count_state) is
          when WAITING =>
            row_count <= (others => '0');
            col_count <= (others => '0');
            if (data_in_w(2 downto 1) = "10") then
              count_state <= NEW_SCR;
            end if;
          when NEW_SCR =>
            if (data_out_g(2 downto 1) = "11") then
              count_state <= ACTIVE;
              step_coords;
            end if;
          when ACTIVE =>
            if (data_in_w(2 downto 1) = "01") then
              count_state <= END_SCR;
            elsif (data_in_w(2 downto 1) = "11") then
              step_coords;
            end if;
          when END_SCR =>
            screen_done <= '1';
            count_state <= WAITING;
        end case;
      end if;
    end if;
  end process;

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- SUBPORTS underfill A SINGLE COMPOSITE FIFO PORT (WIN_LEN < BRAM_WIDTH/BUS_WIDTH)
-----------------------------------------------------------------------------------------------------------------------------------------------------

  One_fifo : if (WIN_LEN < BRAM_WIDTH/BUS_WIDTH) generate
    signal fifo_bus_i, fifo_bus_o : std_logic_vector(BRAM_WIDTH - 1 downto 0);
    constant n : natural := 0;
    begin
    Assign_whole_fifo_bus : for f in WIN_LEN downto 1 generate
      fifo_bus_i(f*BUS_WIDTH - 1 downto (f - 1)*BUS_WIDTH) <= fifo_in_n(n)(f - 1);
      fifo_out_n(n)(f - 1)                                 <= fifo_bus_o(f*BUS_WIDTH - 1 downto (f - 1)*BUS_WIDTH);
    end generate Assign_whole_fifo_bus;
    FIFOx : FIFO_win Port map (
                                clk_in     => clk,
                                read_en    => wr_en,
                                write_en   => wr_en,
                                data_in    => fifo_bus_i,
                                data_out   => fifo_bus_o,
                                empty_flag => open,
                                full_flag  => open
                              );

    Gen_per_fifo_bus : for i in 0 to WIN_LEN - 1 generate -- address the subport on the fifo
      Gen_00 : if (i = 0) generate
      begin
      rowx : generic_rows port map (
                                     clk       => clk,
                                     data_in   => data_in_w,
                                     wr_en     => wr_en,
                                     fill_en   => '0',
                                     data_out  => fifo_in_n(n)(i)
                                   );

      end generate Gen_00;
      Gen_within_same_fifo : if ((i > 0) and (i < WIN_LEN - 1)) generate
      begin
      rowx : generic_rows port map (
                                     clk       => clk,
                                     data_in   => fifo_out_n(n)(i - 1),
                                     wr_en     => wr_en,
                                     fill_en   => '0',
                                     data_out  => fifo_in_n(n)(i)
                                   );

      end generate Gen_within_same_fifo;
      Gen_end : if (i = WIN_LEN - 1) generate
      begin
      rowx : generic_rows port map (
                                     clk       => clk,
                                     data_in   => fifo_out_n(n)(i - 1),
                                     wr_en     => wr_en,
                                     fill_en   => '0',
                                     data_out  => data_out_w
                                   );
      end generate Gen_end;
    end generate Gen_per_fifo_bus;
  end generate One_fifo;

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- SUBPORTS fill ALL COMPOSITE FIFO PORTS with NO REMAINDERS (NUM_FIFOS = NUM_FIFOS_WHOLE)
-----------------------------------------------------------------------------------------------------------------------------------------------------

  No_part_fifos : if (NUM_FIFOS = NUM_FIFOS_WHOLE and not(WIN_LEN < BRAM_WIDTH/BUS_WIDTH)) generate
    Gen_fifos : for n in 0 to NUM_FIFOS - 1 generate
      signal fifo_bus_i, fifo_bus_o : std_logic_vector(BRAM_WIDTH - 1 downto 0);
      begin
      Assign_whole_fifo_bus : for f in SUBPORTS_PER_FIFO downto 1 generate
        fifo_bus_i(f*BUS_WIDTH - 1 downto (f - 1)*BUS_WIDTH) <= fifo_in_n(n)(f - 1);
        fifo_out_n(n)(f - 1)                                 <= fifo_bus_o(f*BUS_WIDTH - 1 downto (f - 1)*BUS_WIDTH);
      end generate Assign_whole_fifo_bus;
      FIFOx : FIFO_win Port map (
                                  clk_in     => clk,
                                  read_en    => wr_en,
                                  write_en   => wr_en,
                                  data_in    => fifo_bus_i,
                                  data_out   => fifo_bus_o,
                                  empty_flag => open,
                                  full_flag  => open
                                );
    end generate Gen_fifos;
    Gen_blocks : for j in 0 to NUM_FIFOS - 1 generate -- address the fifo
      Gen_per_fifo_bus : for i in 0 to SUBPORTS_PER_FIFO - 1 generate -- address the subport on the fifo
        Gen_00 : if ((i = 0) and (j = 0)) generate
        begin
        rowx : generic_rows port map (
                                       clk       => clk,
                                       data_in   => data_in_w,
                                       wr_en     => wr_en,
                                       fill_en   => '0',
                                       data_out  => fifo_in_n(j)(i)
                                     );
        end generate Gen_00;
        Gen_within_same_fifo : if (i > 0 and not((j = NUM_FIFOS - 1) and (i = SUBPORTS_PER_FIFO - 1))) generate
        begin
        rowx : generic_rows port map (
                                       clk       => clk,
                                       data_in   => fifo_out_n(j)(i - 1),
                                       wr_en     => wr_en,
                                       fill_en   => '0',
                                       data_out  => fifo_in_n(j)(i)
                                     );
        end generate Gen_within_same_fifo;
        Gen_across_fifos : if ((i = 0) and (j > 0) and not((j = NUM_FIFOS - 1) and (i = SUBPORTS_PER_FIFO - 1))) generate
        begin
        rowx : generic_rows port map (
                                       clk       => clk,
                                       data_in   => fifo_out_n(j - 1)(SUBPORTS_PER_FIFO - 1),
                                       wr_en     => wr_en,
                                       fill_en   => '0',
                                       data_out  => fifo_in_n(j)(i)
                                     );
        end generate Gen_across_fifos;
        Gen_end : if ((j = NUM_FIFOS - 1) and (i = SUBPORTS_PER_FIFO - 1)) generate
        begin
        rowx : generic_rows port map (
                                       clk       => clk,
                                       data_in   => fifo_out_n(j)(i - 1),
                                       wr_en     => wr_en,
                                       fill_en   => '0',
                                       data_out  => data_out_w
                                     );
        end generate Gen_end;
      end generate Gen_per_fifo_bus;
    end generate Gen_blocks;
  end generate No_part_fifos;

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- SUBPORTS fill COMPOSITE FIFO PORTS with SOME REMAINDERS to PARTIALLY FILL the LAST FIFO (NUM_FIFOS > NUM_FIFOS_WHOLE)
-----------------------------------------------------------------------------------------------------------------------------------------------------

  Part_fifos_exist : if ((NUM_FIFOS > NUM_FIFOS_WHOLE) and not(WIN_LEN < BRAM_WIDTH/BUS_WIDTH)) generate
    Gen_fifos : for n in 0 to NUM_FIFOS - 1 generate
      Whole_fifos : if (n < NUM_FIFOS - 1) generate
        signal fifo_bus_i, fifo_bus_o : std_logic_vector(BRAM_WIDTH - 1 downto 0);
        begin
        Assign_whole_fifo_bus : for f in SUBPORTS_PER_FIFO downto 1 generate
          fifo_bus_i(f*BUS_WIDTH - 1 downto (f - 1)*BUS_WIDTH) <= fifo_in_n(n)(f - 1);
          fifo_out_n(n)(f - 1)                                 <= fifo_bus_o(f*BUS_WIDTH - 1 downto (f - 1)*BUS_WIDTH);
        end generate Assign_whole_fifo_bus;
        FIFOx : FIFO_win Port map (
                                    clk_in     => clk,
                                    read_en    => wr_en,
                                    write_en   => wr_en,
                                    data_in    => fifo_bus_i,
                                    data_out   => fifo_bus_o,
                                    empty_flag => open,
                                    full_flag  => open
                                  );
      end generate Whole_fifos;
      Remainder_fifo : if (n = NUM_FIFOS - 1) generate
        signal fifo_bus_i, fifo_bus_o : std_logic_vector(BRAM_WIDTH - 1 downto 0);
        begin
        Assign_remainder_fifo_bus : for f in LEFTOVER_PORTS downto 1 generate
          fifo_bus_i(f*BUS_WIDTH - 1 downto (f - 1)*BUS_WIDTH) <= fifo_in_n(n)(f - 1);
          fifo_out_n(n)(f - 1)                                 <= fifo_bus_o(f*BUS_WIDTH - 1 downto (f - 1)*BUS_WIDTH);
        end generate Assign_remainder_fifo_bus;
        FIFOx : FIFO_win Port map (
                                    clk_in     => clk,
                                    read_en    => wr_en,
                                    write_en   => wr_en,
                                    data_in    => fifo_bus_i,
                                    data_out   => fifo_bus_o,
                                    empty_flag => open,
                                    full_flag  => open
                                  );
      end generate Remainder_fifo;
    end generate Gen_fifos;
    Gen_blocks_whole_fifos : for j in 0 to NUM_FIFOS - 2 generate
      Gen_per_fifo_bus : for i in 0 to SUBPORTS_PER_FIFO - 1 generate
        Gen_00 : if ((i = 0) and (j = 0)) generate
        begin
        rowx : generic_rows port map (
                                       clk       => clk,
                                       data_in   => data_in_w,
                                       wr_en     => wr_en,
                                       fill_en   => '0',
                                       data_out  => fifo_in_n(j)(i)
                                     );
        end generate Gen_00;
        Gen_within_same_fifo : if ((i > 0) and not((j = NUM_FIFOS - 2) and (i = SUBPORTS_PER_FIFO - 1))) generate
        begin
        rowx : generic_rows port map (
                                       clk       => clk,
                                       data_in   => fifo_out_n(j)(i - 1),
                                       wr_en     => wr_en,
                                       fill_en   => '0',
                                       data_out  => fifo_in_n(j)(i)
                                     );
        end generate Gen_within_same_fifo;
        Gen_across_fifos : if ((i = 0) and (j > 0) and not((j = NUM_FIFOS - 2) and (i = SUBPORTS_PER_FIFO - 1))) generate
        begin
        rowx : generic_rows port map (
                                       clk       => clk,
                                       data_in   => fifo_out_n(j - 1)(SUBPORTS_PER_FIFO - 1),
                                       wr_en     => wr_en,
                                       fill_en   => '0',
                                       data_out  => fifo_in_n(j)(i)
                                     );
        end generate Gen_across_fifos;
        Gen_whole_fifos_end : if ((j = NUM_FIFOS - 2) and (i = SUBPORTS_PER_FIFO - 1)) generate
        begin
        rowx : generic_rows port map (
                                       clk       => clk,
                                       data_in   => fifo_out_n(j)(i - 1),
                                       wr_en     => wr_en,
                                       fill_en   => '0',
                                       data_out  => fifo_in_n(j)(i)
                                     );
        end generate Gen_whole_fifos_end;
      end generate Gen_per_fifo_bus;
    end generate Gen_blocks_whole_fifos;
    Gen_for_remaining_fifo : for i in 0 to LEFTOVER_PORTS - 1 generate
    constant k : positive := NUM_FIFOS - 1;
    begin
      Gen_across_fifos : if (i = 0) generate
      begin
      rowx : generic_rows port map (
                                     clk       => clk,
                                     data_in   => fifo_out_n(k - 1)(SUBPORTS_PER_FIFO - 1),
                                     wr_en     => wr_en,
                                     fill_en   => '0',
                                     data_out  => fifo_in_n(k)(i)
                                   );
      end generate Gen_across_fifos;
      Gen_within_same_fifo : if ((i > 0) and (i < LEFTOVER_PORTS - 1)) generate
      begin
      rowx : generic_rows port map (
                                     clk       => clk,
                                     data_in   => fifo_out_n(k)(i - 1),
                                     wr_en     => wr_en,
                                     fill_en   => '0',
                                     data_out  => fifo_in_n(k)(i)
                                   );
      end generate Gen_within_same_fifo;
      Gen_end : if (i = LEFTOVER_PORTS - 1) generate
      begin
      rowx : generic_rows port map (
                                     clk       => clk,
                                     data_in   => fifo_out_n(k)(i - 1),
                                     wr_en     => wr_en,
                                     fill_en   => '0',
                                     data_out  => data_out_w
                                   );
      end generate Gen_end;
    end generate Gen_for_remaining_fifo;
  end generate Part_fifos_exist;
end Behavioral;
