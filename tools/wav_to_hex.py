import struct
import wave


def wav_to_hex(wav_path, txt_path):
    # Open the WAV file for reading
    with wave.open(wav_path, "rb") as wav_file:
        # Verify the audio format metadata
        n_channels = wav_file.getnchannels()
        sampwidth = wav_file.getsampwidth()

        if n_channels != 1:
            raise ValueError(f"Expected mono file, got {n_channels} channels")
        if sampwidth != 2:
            raise ValueError(
                f"Expected 16-bit (2 bytes) file, got {sampwidth * 8}-bit"
            )

        # Read all audio frames from the file
        n_frames = wav_file.getnframes()
        frames = wav_file.readframes(n_frames)

    # Determine total 16-bit samples
    num_samples = len(frames) // 2

    # Unpack the binary data into a tuple of integers
    # '<' means little-endian (standard for WAV)
    # 'h' means signed 16-bit short integer
    samples = struct.unpack(f"<{num_samples}h", frames)

    # Write the hex values to the output text file
    with open(txt_path, "w") as txt_file:
        for sample in samples:
            # Mask with 0xFFFF to handle negative values and format as a 4-character hex string
            hex_val = f"{sample & 0xFFFF:04X}"
            txt_file.write(f"{hex_val}\n")


# Example usage:
wav_to_hex("16_48k_mono_test.wav", "input.hex")
