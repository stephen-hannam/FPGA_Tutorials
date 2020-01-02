------------------------------------------------------------------------------------------------
-- Copyright 2019 Stephen Ross Hannam

-- Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.ALL;
use IEEE.NUMERIC_STD.ALL;

package gen_win_types is
    constant BUS_WIDTH : positive := 3;
    constant BRAM_WIDTH : positive := 36;
    constant SUBPORTS_PER_FIFO : positive := BRAM_WIDTH/BUS_WIDTH; -- shouldn't need ceil actually
    type fifo_multi_bus is array(natural range 0 to SUBPORTS_PER_FIFO - 1) of std_logic_vector(BUS_WIDTH - 1 downto 0);
    type multi_fifo_multi_bus is array(natural range <>) of fifo_multi_bus;
end package;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.math_real.ALL;
use IEEE.NUMERIC_STD.ALL;

package morph_filter is
    constant MAX_TRIG_SUM : natural := 1023;
    constant MAX_SUM : natural := 127;
    subtype DETECT_TYPE is std_logic;
    type array_of_bits is array(natural range <>) of std_logic;
    type array_of_indices is array(natural range <>) of natural;
    type array_of_sums is array(natural range <>) of natural range 0 to MAX_SUM;
    function oct_cell_lengths(win_len : positive; n : natural) return natural;
    function oct_detection_regions(win_len : positive; n : natural; mid_ring : boolean) return array_of_indices;
    function fat_oct_cell_lengths(win_len : positive; n : natural) return natural;
    function fat_oct_detection_regions(win_len : positive; n : natural; mid_ring : boolean) return array_of_indices;
    function make_multiple_of(num : natural; divisor : natural; golo : boolean) return natural;
    function sort_arr(d_in : array_of_indices) return array_of_indices;
    function calc_trig_sum(win_len : natural) return positive;
    function calc_fat_trig_sum(win_len : natural) return positive;
    function gen_oct_annulus(win_len : positive; n : natural; mid_ring : boolean; fat : boolean) return array_of_indices;
    function gen_trig_sum(win_len : natural; fat : boolean) return natural;
    function calc_actual_win_len(des_win_len : natural; fat : boolean) return natural;
end package;

package body morph_filter is -- for octagonal annulus

    function calc_trig_sum(win_len : natural) return positive is
    begin
        return (4*(2*win_len/3 - 1));
    end function;

    function sort_arr(d_in : array_of_indices) return array_of_indices is
    variable temp : natural := 0;
    variable out_arr : array_of_indices(d_in'range) := d_in;
    variable num : natural := out_arr'length;
    begin
        sort_loop0 : for i in 0 to num - 1 loop
            sort_loop1 : for j in 0 to (num - i - 2) loop
                if (out_arr(j) > out_arr(j + 1)) then
                    temp := out_arr(j);
                    out_arr(j) := out_arr(j + 1);
                    out_arr(j + 1) := temp;
                end if;
            end loop sort_loop1;
        end loop sort_loop0;
        return out_arr;
    end function;

    function make_multiple_of(num : natural; divisor : natural; golo : boolean) return natural is
    begin
        if (golo) then
            return natural(real(divisor)*floor(real(num)/real(divisor)));
        else -- go hi
            return natural(real(divisor)*ceil(real(num)/real(divisor)));
        end if;

    end function;

    function oct_cell_lengths(win_len : positive; n : integer) return natural is
    begin
        if (n = 0 or n = win_len - 1) then
            return natural(floor(real(win_len)/real(3)));
        else
            return 2;
        end if;
    end function;

    function oct_detection_regions(win_len : positive; n : natural; mid_ring : boolean) return array_of_indices is
    variable construct_line : natural := win_len - make_multiple_of(natural(floor(real(win_len)/real(2))), 3, true);
    variable offset : natural := make_multiple_of(natural(floor(real(construct_line)/real(2))), 3, false);
    variable mid_win_len : natural := win_len - 2*offset;
    variable oct_cell_length : natural := oct_cell_lengths(win_len, n);
    variable oct_cell_mid_length : natural := oct_cell_lengths(mid_win_len, n - offset);
    variable temp_idxs : array_of_indices(0 to oct_cell_length - 1);
    variable temp_idxs_mid : array_of_indices(0 to oct_cell_mid_length - 1);
    variable temp_idxs_both : array_of_indices(0 to oct_cell_length + oct_cell_mid_length - 1);
    variable mid_n : integer := n - offset;

    begin
        if (n = 0 or n = win_len - 1) then -- top and bottom rows of annulus
            write_indices0 : for i in 0 to oct_cell_length - 1 loop
                temp_idxs(i) := natural(floor(real(win_len)/real(3))) + i;
            end loop write_indices0;
        elsif (n < (natural(floor(real(win_len)/real(3))))) then -- single pixel wide diag sides at top half
            temp_idxs := ((natural(floor(real(win_len)/real(3)))) - n, 2*natural(floor(real(win_len)/real(3))) + n - 1);
        elsif (n >= 2*natural(floor(real(win_len)/real(3)))) then  -- single pixel wide diag sides at bottom half
            temp_idxs := (n - 2*natural(floor(real(win_len)/real(3))) + 1, win_len - n + 2*natural(floor(real(win_len)/real(3))) - 2);
        else -- vertical sides of annulus
            temp_idxs := (0, win_len - 1);
        end if;

        if (mid_ring) then
            if (n < offset or n > win_len - 1 - offset) then
                return sort_arr(temp_idxs);
            elsif (n = offset or n = win_len - 1 - offset) then -- top and bottom rows of annulus
                write_indices1 : for i in 0 to oct_cell_mid_length - 1 loop
                    temp_idxs_mid(i) := natural(floor(real(mid_win_len)/real(3))) + i + offset;
                end loop write_indices1;
            elsif (n < offset + (natural(floor(real(mid_win_len)/real(3)))) and n > offset) then -- single pixel wide diag sides at top half
                temp_idxs_mid := (offset + (natural(floor(real(mid_win_len)/real(3)))) - mid_n, offset + 2*natural(floor(real(mid_win_len)/real(3))) + mid_n - 1);
            elsif (n >= offset + 2*natural(floor(real(mid_win_len)/real(3))) and (n < win_len - 1 - offset)) then  -- single pixel wide diag sides at bottom half
                temp_idxs_mid := (offset + mid_n - 2*natural(floor(real(mid_win_len)/real(3))) + 1, offset + mid_win_len - mid_n + 2*natural(floor(real(mid_win_len)/real(3))) - 2);
            else -- vertical sides of annulus
                temp_idxs_mid := (offset, win_len - 1 - offset);
            end if;
            temp_idxs_both := (temp_idxs & temp_idxs_mid);
            return sort_arr(temp_idxs_both);
        end if;

        return sort_arr(temp_idxs);

    end function;

    function calc_fat_trig_sum(win_len : natural) return positive is
    begin
        return (3*win_len);
    end function;

    function fat_oct_cell_lengths(win_len : positive; n : integer) return natural is
    begin
        if (n = 0 or n = win_len - 1) then
            return natural(floor(real(win_len)/real(2)));
        else
            return 2;
        end if;
    end function;

    function fat_oct_detection_regions(win_len : positive; n : natural; mid_ring : boolean) return array_of_indices is
    variable construct_line : natural := win_len - make_multiple_of(natural(floor(real(win_len)/real(2))), 4, true);
    variable offset : natural := make_multiple_of(natural(floor(real(construct_line)/real(2))), 4, false);
    variable mid_win_len : natural := win_len - 2*offset;
    variable oct_cell_length : natural := fat_oct_cell_lengths(win_len, n);
    variable oct_cell_mid_length : natural := fat_oct_cell_lengths(mid_win_len, n - offset);
    variable temp_idxs : array_of_indices(0 to oct_cell_length - 1);
    variable temp_idxs_mid : array_of_indices(0 to oct_cell_mid_length - 1);
    variable temp_idxs_both : array_of_indices(0 to oct_cell_length + oct_cell_mid_length - 1);
    variable mid_n : integer := n - offset;

    begin
        if (n = 0 or n = win_len - 1) then -- top and bottom rows of annulus
            write_indices0 : for i in 0 to oct_cell_length - 1 loop
                temp_idxs(i) := natural(floor(real(win_len)/real(4))) + i;
            end loop write_indices0;
        elsif (n < (natural(floor(real(win_len)/real(4))))) then -- single pixel wide diag sides at top half
            temp_idxs := ((natural(floor(real(win_len)/real(4)))) - n, 3*natural(floor(real(win_len)/real(4))) + n - 1);
        elsif (n >= 3*natural(floor(real(win_len)/real(4)))) then  -- single pixel wide diag sides at bottom half
            temp_idxs := (n - 3*natural(floor(real(win_len)/real(4))) + 1, win_len - n + 3*natural(floor(real(win_len)/real(4))) - 2);
        else -- vertical sides of annulus
            temp_idxs := (0, win_len - 1);
        end if;

        if (mid_ring) then
            if (n < offset or n > win_len - 1 - offset) then
                return sort_arr(temp_idxs);
            elsif (n = offset or n = win_len - 1 - offset) then -- top and bottom rows of annulus
                write_indices1 : for i in 0 to oct_cell_mid_length - 1 loop
                    temp_idxs_mid(i) := natural(floor(real(mid_win_len)/real(4))) + i + offset;
                end loop write_indices1;
            elsif (n < offset + (natural(floor(real(mid_win_len)/real(4)))) and n > offset) then -- single pixel wide diag sides at top half
                temp_idxs_mid := (offset + (natural(floor(real(mid_win_len)/real(4)))) - mid_n, offset + 3*natural(floor(real(mid_win_len)/real(4))) + mid_n - 1);
            elsif (n >= offset + 3*natural(floor(real(mid_win_len)/real(4))) and (n < win_len - 1 - offset)) then  -- single pixel wide diag sides at bottom half
                temp_idxs_mid := (offset + mid_n - 3*natural(floor(real(mid_win_len)/real(4))) + 1, offset + mid_win_len - mid_n + 3*natural(floor(real(mid_win_len)/real(4))) - 2);
            else -- vertical sides of annulus
                temp_idxs_mid := (offset, win_len - 1 - offset);
            end if;
            temp_idxs_both := (temp_idxs & temp_idxs_mid);
            return sort_arr(temp_idxs_both);
        end if;

        return sort_arr(temp_idxs);

    end function;

    function gen_oct_annulus(win_len : positive; n : natural; mid_ring : boolean; fat : boolean) return array_of_indices is
    begin
        if (fat) then
            return fat_oct_detection_regions(win_len, n, mid_ring);
        else
            return oct_detection_regions(win_len, n, mid_ring);
        end if;
    end function;

    function gen_trig_sum(win_len : natural; fat : boolean) return natural is
    begin
        if (fat) then
            return calc_fat_trig_sum(win_len);
        else
            return calc_trig_sum(win_len);
        end if;
    end function;

    function calc_actual_win_len(des_win_len : natural; fat : boolean) return natural is
    begin
         if (fat) then
            return make_multiple_of(des_win_len, 4, true);
         else
            return make_multiple_of(des_win_len, 3, true);
         end if;
    end function;

end package body;
