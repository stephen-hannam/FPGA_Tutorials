`ifndef _utils_vh
`define _utils_vh

`define M(x) ($clog2(x)-1)

`define REGSTY 	(* ram_style = "registers" *)
`define DISSTY 	(* ram_style = "distributed" *)

// if one can't use $clog2 for some implausible reason
`define CLOG2(x) \
   ((x <= 2**1) ? 1 : \
   (x <= 2**2) ? 2 : \
   (x <= 2**3) ? 3 : \
   (x <= 2**4) ? 4 : \
   (x <= 2**5) ? 5 : \
   (x <= 2**6) ? 6 : \
   (x <= 2**7) ? 7 : \
   (x <= 2**8) ? 8 : \
   (x <= 2**9) ? 9 : \
   (x <= 2**10) ? 10 : \
   (x <= 2**11) ? 11 : \
   (x <= 2**12) ? 12 : \
   (x <= 2**13) ? 13 : \
   (x <= 2**14) ? 14 : \
   (x <= 2**15) ? 15 : \
   (x <= 2**16) ? 16 : \
   (x <= 2**17) ? 17 : \
   (x <= 2**18) ? 18 : \
   (x <= 2**19) ? 19 : \
   (x <= 2**20) ? 20 : \
   (x <= 2**21) ? 21 : \
   (x <= 2**22) ? 22 : \
   (x <= 2**23) ? 23 : \
   (x <= 2**24) ? 24 : \
   (x <= 2**25) ? 25 : \
   (x <= 2**26) ? 26 : \
   (x <= 2**27) ? 27 : \
   (x <= 2**28) ? 28 : \
   (x <= 2**29) ? 29 : \
   (x <= 2**30) ? 30 : \
   (x <= 2**31) ? 31 : \
   (x <= 2**32) ? 32 : \
   -1)

// macro string concatenation for constructing paths
`define MAKE_PATH(x,y) {`"x`",`"y`"}

`endif
