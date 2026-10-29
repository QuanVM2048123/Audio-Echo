#!/usr/bin/env python3
"""
Golden model for the Digital Echo Effect.

Equation:   y[n] = saturate( x[n] + alpha * x[n - D] )

    x[n]  : current input sample   (16-bit signed, two's complement)
    y[n]  : current output sample  (16-bit signed, two's complement)
    alpha : gain = 0.5
    D     : delay in samples
    saturate: clamp the result to the 16-bit range [-32768, 32767]

Input  file: text file, one 16-bit hex sample per line (e.g. 5555, B272, 26BF)
Output file: expected.hex, same format
"""

import sys

# ----------------------------------------------------------------------
# Settings
# ----------------------------------------------------------------------
INPUT_FILE = "input.hex"       # input file
OUTPUT_FILE = "expected.hex"   # output file
DELAY = 4800                   # delay D, in samples

# Limits of a 16-bit signed number
MAX_VAL = 32767     # 0x7FFF  (largest positive value)
MIN_VAL = -32768    # 0x8000  (most negative value)


# ----------------------------------------------------------------------
# Helper functions
# ----------------------------------------------------------------------
def hex_to_signed(hex_text):
    """Convert a hex string such as 'B272' into a signed integer."""
    value = int(hex_text, 16)
    if value >= 0x8000:
        value = value - 0x10000
    return value


def signed_to_hex(value):
    """Convert a signed integer (-32768..32767) into a 4-digit hex string."""
    return format(value & 0xFFFF, "04X")


def saturate(value):
    """Limit a value so it fits in 16-bit signed range."""
    if value > MAX_VAL:
        return MAX_VAL
    if value < MIN_VAL:
        return MIN_VAL
    return value


def apply_gain_half(value):
    """Multiply by alpha = 0.5."""
    return value >> 1


# ----------------------------------------------------------------------
# Echo effect
# ----------------------------------------------------------------------
def echo(samples, delay):
    """Apply the echo to a list of signed samples and return the output list."""
    output = []

    for n in range(len(samples)):
        current = samples[n]
        if n - delay >= 0:
            delayed = samples[n - delay]
        else:
            delayed = 0

        # y[n] = saturate( x[n] + 0.5 * x[n - D] )
        result = current + apply_gain_half(delayed)
        output.append(saturate(result))

    return output


# ----------------------------------------------------------------------
# File reading/writing
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
    delay = int(sys.argv[2]) if len(sys.argv) > 2 else DELAY

    if delay < 0:
        sys.exit("Error: the delay D must be 0 or larger.")

    sample_in = read_samples(input_file)      # read input samples
    sample_out = echo(sample_in, delay)       # run the echo model
    write_samples(OUTPUT_FILE, sample_out)    # save the expected result

    print(f"Read {len(sample_in)} samples from {input_file}, D = {delay}")
    print(f"Wrote {len(sample_out)} samples to {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
