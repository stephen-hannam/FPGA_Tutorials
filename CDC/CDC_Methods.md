# CDC Methods

Progress through basic but less reliable, to more complex and reliable methods. Reliability is either a measure of how generalizable a method is (ie, only good for a certain ratio of clock speeds and/or direction of cross-over - slow > fast, fast > slow), or of how stable it is (ie, MTBF, etc).

## Single-bit Sync

## Multi-Cycle Bus Data-Path

## Multi-Cycle Bus Data-Path with Sync'd Control Flag

An issue arises when relying solely on controlling the data-path crossing via sync chaining a single flag. The depth of the sync chain determines whether spurious multiple sampling of the data-line occurs or not.

The chief concern is that there is nothing inherent to the logic handling the crossing that could reliably guarantee that the two adjacent control pulses/levels are referring to separate data-word crossings. Even if two clock frequencies were very close to being a whole number ratio of each other, this does not directly address the matter. One may rely on these control bits to be valid (ie, exist only once for that data-word it is accompanying) 999 times in a 1000, but three (3) serious concerns exist:

1. this may not be satisfactory, and ppm of relative clock skew combined with various corners may mean the hardware cannot actually achieve the required valid-rate, and worse, if unanticipated, and therefore lacking correct XDC contraints, one may think this valid-rate is being achieved when it is not because the tools would not be able to warn you
2. this is an inflexible design, that may not easily adapt to many ranges of clock ratios
3. this is a more fragile design, whereby if we keep the crossing logic and basic hardware specifications equal, the valid-rate may be more highly sensitive to variations in place-and-route and opt-design, etc than alternative methods

If you can be absolutely certain of the ratios of the two clock domains and satisfy yourself of several other conditions, then it can be safely used. These conditions are:

1. Complete coverage at an acceptable level of simulation (RTL, post-synth, post-impl or HW harness) of all possible control combinations across a full LCM (Lowest Common Multiple) number of clock cycles reveals correct crossing every time.
2. Jitter, clock-skew nor any other worst-case corners are likely to take the system to states whereby the previous coverage assured in condition 1 above would be invalidated.
3. Data-path skew internal to bus will not invalidate what was validated during testing in condition 1.

Condition 3 also relates back to Concern 3 from above.

Given all this, a better option may be the use of Gray (Code) Counters. The next section will cover the simplest use in the form of minimal gray counters.

## Multi-Cycle Bus Data-Path with Minimal Gray Counters

## Async FIFO Pipeline
