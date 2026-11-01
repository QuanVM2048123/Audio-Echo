import struct
import wave


def hex_to_wav(txt_path, wav_path, sample_rate=48000):
    samples = []

    # Read the hex text file line by line
    with open(txt_path, "r") as txt_file:
        for line in txt_file:
            clean_line = line.strip()
            if not clean_line:
                continue  # Skip empty lines

            # Convert hex string to integer
            val = int(clean_line, 16)

            # Convert unsigned 16-bit to signed 16-bit (two's complement conversion)
            if val > 0x7FFF:
                val -= 0x10000

            samples.append(val)

    # Pack the signed integers into little-endian 16-bit binary data
    # '<' means little-endian, 'h' means signed 16-bit short integer
    binary_data = struct.pack(f"<{len(samples)}h", *samples)

    # Write the binary data and WAV header to the output file
    with wave.open(wav_path, "wb") as wav_file:
        # Set parameters: (nchannels, sampwidth, framerate, nframes, comptype, compname)
        # 1 channel (mono), 2 bytes per sample (16-bit), 48000Hz sample rate
        wav_file.setparams((1, 2, sample_rate, len(samples), "NONE", "not compressed"))
        wav_file.writeframes(binary_data)


# Example usage:
hex_to_wav("expected.hex", "expected.wav")
