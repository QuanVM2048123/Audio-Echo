#!/usr/bin/env python3
"""
Golden (reference) model for the Digital Echo Effect - DGT302 project.

Equation:   y[n] = saturate( x[n] + alpha * x[n - D] )

    x[n]   : current input sample   (16-bit signed, two's complement)
    y[n]   : current output sample  (16-bit signed, two's complement)
    alpha  : gain = 0.5
    D      : delay in samples
    saturate: clamp the result to the 16-bit range [-32768, 32767]

Input  file : text file, one 16-bit hex sample per line (e.g. 5555, B272, 26BF)
Output file : expected.hex, same format (4 uppercase hex digits per line)

How to run:
    python echo_golden_model.py                    (uses input.hex, D = 4)
    python echo_golden_model.py my_audio.hex 100   (input file = my_audio.hex, D = 100)
"""

import sys

# ----------------------------------------------------------------------
# Settings (change these to match your RTL)
# ----------------------------------------------------------------------
INPUT_FILE = "input.hex"       # default input file
OUTPUT_FILE = "expected.hex"   # output file that your testbench compares against
DELAY_D = 4                    # default delay D, in samples

# Limits of a 16-bit signed number
MAX_VAL = 32767     # 0x7FFF  (largest positive value)
MIN_VAL = -32768    # 0x8000  (most negative value)


# ----------------------------------------------------------------------
# Helper functions
# ----------------------------------------------------------------------
def hex_to_signed(hex_text):
    """Convert a hex string such as 'B272' into a signed integer.

    A 16-bit hex number from 0x0000 to 0xFFFF is "unsigned".
    In two's complement, anything from 0x8000 upward is negative,
    so we subtract 65536 (0x10000) to get the real signed value.
        Example: 0xB272 = 45682  ->  45682 - 65536 = -19854
    """
    value = int(hex_text, 16)
    if value >= 0x8000:
        value = value - 0x10000
    return value


def signed_to_hex(value):
    """Convert a signed integer (-32768..32767) into a 4-digit hex string.

    '& 0xFFFF' keeps only the lowest 16 bits, which turns a negative
    number into its two's complement form.
        Example: -19854 -> 'B272'
    """
    return format(value & 0xFFFF, "04X")


def saturate(value):
    """Clamp a value so it fits in 16-bit signed range.

    Without saturation, a result such as 40000 would "wrap around" and
    become a negative number (an ugly click in the audio). Saturation
    simply holds the output at the maximum or minimum instead.
    """
    if value > MAX_VAL:
        return MAX_VAL
    if value < MIN_VAL:
        return MIN_VAL
    return value


def apply_gain_half(value):
    """Multiply by alpha = 0.5.

    In hardware, x * 0.5 is just a 1-bit arithmetic right shift (x >>> 1).
    Python's '>>' on integers is also an arithmetic shift, so it behaves
    exactly like Verilog's '>>>' on a signed value: it rounds DOWN
    (toward minus infinity).
        Example:  5 >> 1 =  2     and    -5 >> 1 = -3

    IMPORTANT: your RTL must do the same (use '>>>' on a signed signal),
    otherwise the results can differ by 1 LSB on negative odd samples.
    """
    return value >> 1


# ----------------------------------------------------------------------
# The echo effect itself
# ----------------------------------------------------------------------
def echo(samples, delay):
    """Apply the echo to a list of signed samples and return the output list."""
    output = []

    for n in range(len(samples)):
        current = samples[n]                  # x[n]

        # x[n - D]: the sample from D steps ago.
        # Before D samples have arrived there is no past sample yet,
        # so the delay line is empty (all zeros), just like a reset register chain.
        if n - delay >= 0:
            delayed = samples[n - delay]
        else:
            delayed = 0

        # y[n] = saturate( x[n] + 0.5 * x[n - D] )
        result = current + apply_gain_half(delayed)
        output.append(saturate(result))

    return output


# ----------------------------------------------------------------------
# File reading / writing
# ----------------------------------------------------------------------
def read_samples(filename):
    """Read a hex text file (one sample per line) into a list of signed ints."""
    samples = []
    with open(filename, "r") as f:
        for line_number, line in enumerate(f, start=1):
            text = line.strip()          # remove spaces and the newline
            if text == "":               # ignore blank lines
                continue
            try:
                samples.append(hex_to_signed(text))
            except ValueError:
                sys.exit(f"Error: line {line_number} of {filename} is not valid hex: '{text}'")
    return samples


def write_samples(filename, samples):
    """Write signed samples to a text file as 4-digit hex, one per line."""
    with open(filename, "w") as f:
        for s in samples:
            f.write(signed_to_hex(s) + "\n")


# ----------------------------------------------------------------------
# Main program
# ----------------------------------------------------------------------
def main():
    # Optional command-line arguments: input file name, then delay D
    input_file = sys.argv[1] if len(sys.argv) > 1 else INPUT_FILE
    delay = int(sys.argv[2]) if len(sys.argv) > 2 else DELAY_D

    if delay < 0:
        sys.exit("Error: the delay D must be 0 or larger.")

    x = read_samples(input_file)      # read input samples
    y = echo(x, delay)                # run the echo model
    write_samples(OUTPUT_FILE, y)     # save the expected result

    print(f"Read {len(x)} samples from {input_file}, D = {delay}")
    print(f"Wrote {len(y)} samples to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
