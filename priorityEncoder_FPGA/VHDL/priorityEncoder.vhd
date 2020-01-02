-- core priority encoder code taken from StackOverflow user Brian Drummond (without permission): https://stackoverflow.com/questions/14113125/short-way-to-write-vhdl-priority-encoder
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.ALL; -- NB: not synth-able

entity priorityEncoder is
  generic (
    proc_type : std_logic := '0';  -- 0 = clk'd, 1 = combinational
    NUM_SW    : positive  := 4;
    NUM_SWW   : positive  := 2 --positive(ceil(log2(real(NUM_SW))))
  );
  port(
    clk    : IN  STD_LOGIC;
    switch : IN  STD_LOGIC_VECTOR(NUM_SW-1 downto 0);
    msb_sw : OUT STD_LOGIC_VECTOR(NUM_SWW downto 0)
  );
end priorityEncoder;

architecture RTL of priorityEncoder is

  subtype Switches is integer range 1 to NUM_SW;

begin
  combinational : if proc_type = '1' generate
  begin
    shifting : process(switch)
    begin
      for i in Switches loop
        if switch(i-1) = '1' then
          msb_sw  <= std_logic_vector(to_unsigned(i, msb_sw'length));
        else
          msb_sw  <= (others => '0');
        end if;
      end loop;
    end process;
  end generate;

  clocked : if proc_type = '0' generate
  begin
    shifting : process(clk)
    begin
    	if (rising_edge(clk)) then
    	   msb_sw  <= (others => '0');    	   
         for i in Switches loop
           if switch(i-1) = '1' then
             msb_sw  <= std_logic_vector(to_unsigned(i, msb_sw'length));                              
           end if;
         end loop;
    	end if;
    end process;
  end generate;
end RTL;
