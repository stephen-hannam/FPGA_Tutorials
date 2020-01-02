library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity generic_window_tb is
--  Port ( );
end generic_window_tb;

architecture Behavioral of generic_window_tb is

  constant IMAGE_WIDTH  : positive := 640;
  constant IMAGE_HEIGHT : positive := 480;
  constant ROW_MSB      : natural  := natural(ceil(real(log2(real(IMAGE_HEIGHT)))))-1;
  constant COL_MSB      : natural  := natural(ceil(real(log2(real(IMAGE_WIDTH)))))-1;
  constant BITS_PER_PIX : positive := 1;
  constant BITS_CNTL    : positive := 2;
  constant BUS_WIDTH    : positive := BITS_PER_PIX + BITS_CNTL;
  constant BRAM_WIDTH   : positive := 36;
  constant ROW_TYPE     : string   := "shreg_only";
  constant WIN_LEN      : positive := 87;

  component generic_window
    Generic (
              WIN_LEN      : positive := WIN_LEN;
              IMAGE_WIDTH  : positive := IMAGE_WIDTH;
              IMAGE_HEIGHT : positive := IMAGE_HEIGHT;
              BUS_WIDTH    : positive := BUS_WIDTH;
              BRAM_WIDTH   : positive := BRAM_WIDTH; -- whole number multiple of BUS_WIDTH
              ROW_TYPE     : string   := ROW_TYPE;
              ROW_MSB      : natural  := ROW_MSB;
              COL_MSB      : natural  := COL_MSB
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
  end component generic_window;

  signal rst_good                : std_logic := '0';
  signal clk, rst_n, screen_done : std_logic := '0';
  signal data_in, data_out       : std_logic_vector(BUS_WIDTH - 1 downto 0) := (others => '0');

  signal x : unsigned(COL_MSB downto 0) := (others => '0');
  signal y : unsigned(ROW_MSB downto 0) := (others => '0');

  constant NUM_PIX    : natural                                     := IMAGE_WIDTH * IMAGE_HEIGHT;
  signal pixel        : std_logic_vector(BITS_PER_PIX - 1 downto 0) := (others => '0');
  signal control_sigs : std_logic_vector(BITS_CNTL - 1 downto 0)    := (others => '0');
  signal pixel_count  : unsigned(ROW_MSB + COL_MSB + 1 downto 0)    := (others => '0');
  signal row_count    : unsigned(8 downto 0)                        := (others => '0');

  constant clk_half : time := 5ns;
  constant clk_t    : time := 2*clk_half; -- 100MHz

begin

  clk     <= not clk after clk_half;

  cntl_bits : for i in BUS_WIDTH - 1 downto BUS_WIDTH - BITS_CNTL generate
    data_in(i) <= control_sigs(i - (BUS_WIDTH - BITS_CNTL));
  end generate;

  pixel_bits : for i in BUS_WIDTH - BITS_CNTL - 1 downto 0 generate
    data_in(i)  <= pixel(i);
  end generate;

  DUT : generic_window
    port map (
               clk          => clk,
               rst_n        => rst_n,
               data_in      => data_in,
               data_out     => data_out,
               screen_done  => screen_done,
               x            => x,
               y            => y
             );

  process
  begin
    --pixel_count  <= (others => '0');
    --pixel        <= (others => '0');
    --control_sigs <= (others => '0');
    rst_good     <= '0';
    rst_n        <= '1'; wait for 5*clk_t;
    rst_n        <= '0'; wait for 5*clk_t;
    rst_n        <= '1'; wait for 5*clk_t;
    rst_good     <= '1';
    wait until (pixel_count = NUM_PIX + WIN_LEN**2 + 1);
    report "end of simulation"
    severity FAILURE;
  end process;

-- screen control sigs:
  -- 00 = inactive/blanking
  -- 11 = active screen
  -- 10 = start new screen
  -- 01 = end current screen
  process(clk)
    variable row_cnt : integer := 0;
  begin
    if (rst_n = '0' or rst_good = '0') then
      pixel         <= (others => '0');
      control_sigs  <= (others => '0');
      pixel_count   <= (others => '0');
      row_count     <= (others => '0');
    elsif (rising_edge(clk) and rst_good = '1') then
      if (pixel_count < NUM_PIX) then
        pixel_count <= pixel_count + 1;
      end if;

      if (pixel_count = 0) then
        control_sigs  <= "10";
      elsif (pixel_count < NUM_PIX - 1) then
        control_sigs  <= "11";
        if ((pixel_count mod 10) = 0) then
          pixel <= (others => '1');
        else
          pixel <= (others => '0');
        end if;
        if ((pixel_count mod IMAGE_HEIGHT) = 0 and pixel_count /= 0) then
          report "row " & integer'image(row_cnt) & " done"
          severity NOTE;
          row_count <= row_count + 1;
          row_cnt   := to_integer(row_count);
        end if;
      elsif (pixel_count = NUM_PIX - 1) then
        pixel <= (others => '0');
      elsif (pixel_count = NUM_PIX + WIN_LEN**2) then
        control_sigs  <= "01";
      end if;
    end if;
  end process;

end Behavioral;
