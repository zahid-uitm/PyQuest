import math
import struct
import wave
import os

OUT_DIR = r"c:\Users\zahid\Documents\py-quest\assets\audio"
os.makedirs(OUT_DIR, exist_ok=True)
SAMPLE_RATE = 44100

def write_wav(filename, samples):
    filepath = os.path.join(OUT_DIR, filename)
    with wave.open(filepath, "w") as wav:
        wav.setnchannels(1)  # Mono
        wav.setsampwidth(2)  # 16-bit
        wav.setframerate(SAMPLE_RATE)
        packed = bytearray()
        for s in samples:
            val = max(-1.0, min(1.0, s))
            int_val = int(val * 32767.0)
            packed.extend(struct.pack("<h", int_val))
        wav.writeframes(packed)
    print(f"Generated: {filename} ({len(samples)} samples, {len(samples)/SAMPLE_RATE:.2f}s)")

def gen_badge_unlock_fanfare():
    duration = 1.9
    n_samples = int(duration * SAMPLE_RATE)
    samples = [0.0] * n_samples
    
    # Arpeggio notes: [time, freq, volume, decay_rate]
    # Victorious ascending fanfare: C5 (523), E5 (659), G5 (784), B5 (988), C6 (1046) + E6 (1318)
    notes = [
        (0.00, 523.25, 0.40, 5.0),   # C5
        (0.08, 659.25, 0.45, 4.5),   # E5
        (0.16, 783.99, 0.50, 4.0),   # G5
        (0.24, 987.77, 0.60, 3.5),   # B5
        (0.32, 1046.50, 0.75, 2.5),  # C6 (Peak)
        (0.32, 1318.51, 0.50, 2.8),  # E6 (Harmonic shine)
        (0.32, 1567.98, 0.40, 3.0),  # G6 (High chime)
    ]
    
    # 1. Add Bell Arpeggio
    for start_t, freq, amp, decay in notes:
        start_idx = int(start_t * SAMPLE_RATE)
        for i in range(start_idx, n_samples):
            t_rel = (i - start_idx) / SAMPLE_RATE
            env = math.exp(-t_rel * decay)
            # Chime with slight natural harmonic overtones
            s = math.sin(2.0 * math.pi * freq * t_rel)
            s += 0.35 * math.sin(2.0 * math.pi * (freq * 2.008) * t_rel)
            s += 0.15 * math.sin(2.0 * math.pi * (freq * 3.015) * t_rel)
            s += 0.08 * math.sin(2.0 * math.pi * (freq * 4.02) * t_rel)
            samples[i] += s * amp * env

    # 2. Add Warm Golden Fanfare Pad Swell on the peak (t >= 0.32)
    swell_start = int(0.30 * SAMPLE_RATE)
    for i in range(swell_start, n_samples):
        t_rel = (i - swell_start) / SAMPLE_RATE
        # Swell envelope: rises quickly to 0.15s, then decays smoothly
        if t_rel < 0.15:
            pad_env = (t_rel / 0.15) ** 1.5
        else:
            pad_env = math.exp(-(t_rel - 0.15) * 2.2)
            
        # Rich C major brass/organ chord: C3 (130.8), G3 (196.0), C4 (261.6), E4 (329.6)
        c3 = math.sin(2.0 * math.pi * 130.81 * t_rel)
        g3 = math.sin(2.0 * math.pi * 196.00 * t_rel)
        c4 = math.sin(2.0 * math.pi * 261.63 * t_rel)
        e4 = math.sin(2.0 * math.pi * 329.63 * t_rel)
        # Detuned shimmer chorus
        chorus = math.sin(2.0 * math.pi * 262.3 * t_rel) * 0.5
        
        pad_sample = (c3 * 0.35 + g3 * 0.3 + c4 * 0.4 + e4 * 0.35 + chorus * 0.2) * 0.38 * pad_env
        samples[i] += pad_sample

    # 3. Add High Crystalline Star Sparkles (twinkling pings around 0.45s - 1.2s)
    sparkles = [
        (0.40, 2093.0, 0.25),  # C7
        (0.48, 2637.0, 0.22),  # E7
        (0.56, 3136.0, 0.25),  # G7
        (0.66, 3951.0, 0.20),  # B7
        (0.78, 4186.0, 0.22),  # C8
        (0.92, 3136.0, 0.18),  # G7
        (1.08, 2637.0, 0.15),  # E7
    ]
    for sp_t, sp_freq, sp_amp in sparkles:
        sp_start = int(sp_t * SAMPLE_RATE)
        for i in range(sp_start, n_samples):
            t_rel = (i - sp_start) / SAMPLE_RATE
            env = math.exp(-t_rel * 9.0)
            s = math.sin(2.0 * math.pi * sp_freq * t_rel)
            samples[i] += s * sp_amp * env

    # Normalize samples to avoid clipping
    max_val = max(abs(s) for s in samples)
    if max_val > 0.0:
        samples = [s / max_val * 0.92 for s in samples]

    write_wav("sfx_badge_unlock.wav", samples)

gen_badge_unlock_fanfare()
