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
use ieee.math_real.all;
-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FIFO_win is
  generic (
            FWFT        : boolean; -- First Word Fall Through
            FIFO_LENGTH : natural;
            DATA_DEPTH  : natural
          );
  Port    (
            clk_in     : in  std_logic;
            read_en    : in  std_logic;
            write_en   : in  std_logic;
            data_in    : in  std_logic_vector (DATA_DEPTH - 1 downto 0);
            data_out   : out std_logic_vector (DATA_DEPTH - 1 downto 0);
            empty_flag : out std_logic;
            full_flag  : out std_logic
          );
end FIFO_win;

architecture Behavioral of FIFO_win is
  -- Create constant for pointers
  constant IDX_LENGTH : natural := natural(ceil(log2(real(FIFO_LENGTH))));

  -- Instatiate a RAM module
  type FIFO_RAM is array (FIFO_LENGTH - 1 downto 0) of STD_LOGIC_VECTOR (DATA_DEPTH - 1 downto 0);
  signal FIFO_data                 : FIFO_RAM := (others => (others => '0'));
  attribute RAM_style              : string;
  attribute RAM_style of FIFO_data : signal is "block";

  -- Create pointers to internally track position of data read in and written out
  signal read_idx, write_idx : unsigned (IDX_LENGTH - 1 downto 0) := (others => '0');
  signal data_out_r          : std_logic_vector(DATA_DEPTH - 1 downto 0) := (others => '0');
  -- Internal signals
  signal full  : STD_LOGIC := '0';
  signal empty : STD_LOGIC := '1';

begin

  full_flag <= full;
  empty_flag <= empty;

  data_out <= data_out_r;

  FIFO_write : process(clk_in)
  begin
    if rising_edge(clk_in) then
      if (write_en = '1') AND ((full = '0') OR (read_en = '1')) then
        -- write data
        FIFO_data(to_integer(write_idx)) <= data_in;
        -- increment/loop write index
        if write_idx = FIFO_LENGTH - 1 then
          write_idx <= (others => '0');
        else
          write_idx <= write_idx + 1;
        end if;
      end if;
    end if;
  end process FIFO_write;

  nonFWFT_gen : if not FWFT generate
    FIFO_read : process(clk_in)
    begin
      if rising_edge(clk_in) then
        if (read_en = '1') AND ((empty = '0') OR (write_en = '1')) then
          -- read data
          data_out_r <= FIFO_data(to_integer(read_idx));
          -- increment/loop read index
          if read_idx = FIFO_LENGTH - 1 then
            read_idx <= (others => '0');
          else
            read_idx <= read_idx + 1;
          end if;
        end if;
      end if;
    end process FIFO_read;
  end generate nonFWFT_gen;

  FWFT_gen: if FWFT generate
    FIFO_read : process(clk_in)
    begin
      if rising_edge(clk_in) then
        if (read_en = '1') AND ((empty = '0') OR (write_en = '1')) then
          -- increment/loop read index
          if read_idx = FIFO_LENGTH - 1 then
            read_idx <= (others => '0');
          else
            read_idx <= read_idx + 1;
          end if;
        end if;
      end if;
    end process FIFO_read;
    data_out_r <= FIFO_data(to_integer(read_idx));
  end generate FWFT_gen;

  FIFO_flag : process(clk_in)
  begin
    if rising_edge(clk_in) then
      if (read_en = '1') AND (write_en = '0') then
        full <= '0';
        if (read_idx = FIFO_LENGTH - 1) AND (write_idx = 0) then
          empty <= '1';
        elsif (read_idx + 1 = write_idx) then
          empty <= '1';
        end if;
      elsif (write_en = '1') AND (read_en = '0') then
        empty <= '0';
        if (write_idx = FIFO_LENGTH - 1) AND (read_idx = 0) then
          full <= '1';
        elsif (write_idx + 1 = read_idx) then
          full <= '1';
        end if;
      end if;
    end if;
  end process FIFO_flag;

end Behavioral;
