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

# Utility synthesizers
def synth_sine(freq, t, phase=0.0):
    return math.sin(2.0 * math.pi * freq * t + phase)

def synth_triangle(freq, t):
    p = (t * freq) % 1.0
    return 4.0 * abs(p - 0.5) - 1.0

def synth_square(freq, t, duty=0.5):
    p = (t * freq) % 1.0
    return 1.0 if p < duty else -1.0

import random
rng = random.Random(42)

def gen_spell_cast():
    # Rising magical energy whoosh + high sparkle shimmer (0.42s)
    duration = 0.42
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Pitch sweeps up from 220 to 880 Hz
        env = math.sin(math.pi * (t / duration)) ** 1.2
        f = 220.0 + 660.0 * (t / duration) ** 1.8
        # Layer 1: Sine sweep
        s1 = synth_sine(f, t)
        # Layer 2: Detuned triangle
        s2 = synth_triangle(f * 1.01, t) * 0.5
        # Layer 3: High sparkle shimmer
        s3 = synth_sine(f * 2.0, t) * (0.3 if t > 0.15 else 0.0)
        # Layer 4: Soft airy noise
        noise = (rng.random() * 2.0 - 1.0) * (0.15 * env)
        sample = (s1 * 0.5 + s2 * 0.3 + s3 * 0.2 + noise) * env * 0.95
        samples.append(sample)
    return samples

def gen_boss_hit():
    # Heavy punchy bass impact (descending pitch 160 -> 40 Hz) + noise crunch + crystal ring (0.55s)
    duration = 0.55
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Bass impact envelope
        env_impact = math.exp(-t * 9.0)
        f_bass = 160.0 * math.exp(-t * 14.0) + 40.0
        s_bass = synth_sine(f_bass, t) * env_impact
        # Noise crunch (starts strong, fades quickly in 0.12s)
        env_noise = math.exp(-t * 22.0)
        noise = (rng.random() * 2.0 - 1.0) * env_noise * 0.85
        # Resonant crystal ring (440Hz and 660Hz)
        env_ring = math.exp(-t * 4.5)
        s_ring = (synth_sine(440.0, t) * 0.4 + synth_sine(659.25, t) * 0.3) * env_ring
        # Combine
        sample = (s_bass * 0.6 + noise * 0.45 + s_ring * 0.35) * 0.92
        samples.append(sample)
    return samples

def gen_player_hurt():
    # Shield crack / dark zap (0.4s)
    duration = 0.4
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 8.0)
        # Fast pitch down 340 -> 75 Hz
        f = 340.0 * math.exp(-t * 12.0) + 75.0
        # Distorted square wave with noise
        sq = synth_square(f, t, duty=0.35) * 0.5
        noise = (rng.random() * 2.0 - 1.0) * math.exp(-t * 18.0) * 0.5
        # Dissonant clang (185Hz and 255Hz)
        clang = (synth_sine(185.0, t) + synth_sine(255.0, t)) * 0.35 * env
        sample = (sq * 0.4 + noise * 0.35 + clang * 0.4) * env * 0.9
        samples.append(sample)
    return samples

def gen_error():
    # Gentle low-mid 2-tone negative buzz/thud (Eb3 -> C3, 0.32s)
    duration = 0.32
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        if t < 0.16:
            sub_t = t
            f = 155.56 # Eb3
            env = math.exp(-sub_t * 9.0)
        else:
            sub_t = t - 0.16
            f = 130.81 # C3
            env = math.exp(-sub_t * 7.5)
        s = synth_triangle(f, t) * 0.7 + synth_sine(f * 2.0, t) * 0.3
        sample = s * env * 0.8
        samples.append(sample)
    return samples

def gen_boss_defeat():
    # Epic boss shatter + celestial dissipation swell (1.25s)
    duration = 1.25
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # 1. Explosive shatter crack (first 0.2s)
        crack_env = math.exp(-t * 12.0)
        crack_noise = (rng.random() * 2.0 - 1.0) * crack_env * 0.7
        sub = synth_sine(65.0 * math.exp(-t * 8.0) + 35.0, t) * crack_env * 0.6
        # 2. Crystalline arpeggiated cascade: C5(0.08), G5(0.2), C6(0.35), E6(0.5)
        tones = [
            (523.25, 0.08, 0.6),
            (783.99, 0.20, 0.55),
            (1046.50, 0.32, 0.5),
            (1318.51, 0.45, 0.45)
        ]
        chimes = 0.0
        for freq, start_t, ampl in tones:
            if t >= start_t:
                dt = t - start_t
                c_env = math.exp(-dt * 3.5)
                chimes += synth_sine(freq, dt) * c_env * ampl
        # 3. Celestial dissipation choir/reverb tail
        tail_env = (math.sin(math.pi * (t / duration)) ** 1.5) if t > 0.3 else 0.0
        choir = (synth_sine(523.25, t) + synth_sine(659.25, t) + synth_sine(783.99, t)) * 0.15 * tail_env
        sample = (crack_noise + sub + chimes + choir) * 0.85
        samples.append(sample)
    return samples

def gen_shrine_awaken():
    # Resonant holy major triad chime: C5 + E5 + G5 + C6 (1.1s)
    duration = 1.1
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    freqs = [523.25, 659.25, 783.99, 1046.50, 1567.98]
    weights = [0.35, 0.30, 0.25, 0.20, 0.10]
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.exp(-t * 2.8)
        # Slow bloom swell at very beginning (0.04s)
        attack = min(1.0, t / 0.04)
        chord = 0.0
        for f, w in zip(freqs, weights):
            # Subtle vibrato on overtones
            vib = math.sin(2.0 * math.pi * 5.0 * t) * 1.5
            chord += synth_sine(f + vib, t) * w
            chord += synth_triangle(f, t) * (w * 0.25)
        sample = chord * env * attack * 0.95
        samples.append(sample)
    return samples

def gen_chest_open():
    # Latch click (0.0 - 0.12s) + ascending golden sparkle arpeggio (E5, G#5, B5, E6) (0.75s)
    duration = 0.75
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    arp_notes = [
        (659.25, 0.10), # E5
        (830.61, 0.22), # G#5
        (987.77, 0.34), # B5
        (1318.51, 0.46) # E6
    ]
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Latch click / heavy wood thud
        latch = 0.0
        if t < 0.12:
            latch_env = math.exp(-t * 35.0)
            latch = (synth_sine(140.0, t) * 0.6 + (rng.random() * 2.0 - 1.0) * 0.4) * latch_env
        # Sparkle arpeggios
        sparkle = 0.0
        for freq, start_t in arp_notes:
            if t >= start_t:
                dt = t - start_t
                s_env = math.exp(-dt * 6.0)
                sparkle += synth_sine(freq, dt) * s_env * 0.32
                sparkle += synth_sine(freq * 2.0, dt) * s_env * 0.12
        sample = (latch * 0.75 + sparkle) * 0.92
        samples.append(sample)
    return samples

def gen_bridge_extend():
    # Energy hum rising (110 -> 220Hz) + heavy locking stone mechanism (0.78s)
    duration = 0.78
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Rising energy hum (0.0 to 0.55s)
        if t < 0.55:
            env_hum = math.sin(math.pi * (t / 0.55)) ** 0.8
            f_hum = 110.0 + 110.0 * (t / 0.55)
            hum = synth_triangle(f_hum, t) * 0.45 + synth_sine(f_hum * 2.0, t) * 0.2
            hum += (rng.random() * 2.0 - 1.0) * 0.08
            s_hum = hum * env_hum
        else:
            s_hum = 0.0
        # Stone locking clunk (0.50 to 0.78s)
        s_clunk = 0.0
        if t >= 0.50:
            dt = t - 0.50
            env_clunk = math.exp(-dt * 15.0)
            s_clunk = (synth_sine(85.0, dt) * 0.6 + synth_triangle(130.0, dt) * 0.3 + (rng.random()*2-1)*0.35) * env_clunk
        sample = (s_hum + s_clunk) * 0.9
        samples.append(sample)
    return samples

def gen_teleport():
    # Phasing cosmic warp whoosh: fast frequency sweep 150 -> 1200 -> 280 Hz (0.52s)
    duration = 0.52
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        env = math.sin(math.pi * (t / duration)) ** 1.1
        # Parabolic frequency arch
        arch = math.sin(math.pi * (t / duration))
        f = 180.0 + 1050.0 * arch
        # Phase modulated stereo/chorus effect
        phase_mod = math.sin(2.0 * math.pi * 8.0 * t) * 0.5
        w1 = synth_sine(f, t, phase_mod)
        w2 = synth_triangle(f * 0.99, t) * 0.4
        noise = (rng.random() * 2.0 - 1.0) * 0.15 * env
        sample = (w1 * 0.55 + w2 * 0.3 + noise) * env * 0.92
        samples.append(sample)
    return samples

def gen_relic_pickup():
    # Crisp bubble pop (pitch sweep 420 -> 1150Hz in 0.04s) + double crystal chime (A5, E6) (0.42s)
    duration = 0.42
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        # Pop transient (0.0 to 0.06s)
        pop = 0.0
        if t < 0.06:
            f_pop = 420.0 + 730.0 * (t / 0.06)
            pop_env = math.sin(math.pi * (t / 0.06))
            pop = synth_sine(f_pop, t) * pop_env * 0.65
        # Dual bell chimes: A5(880Hz) and E6(1318.5Hz)
        dt = max(0.0, t - 0.03)
        bell_env = math.exp(-dt * 9.0) if t >= 0.03 else 0.0
        b1 = synth_sine(880.0, dt) * 0.45 * bell_env
        b2 = synth_sine(1318.51, dt) * 0.35 * bell_env
        b3 = synth_sine(1760.0, dt) * 0.15 * bell_env
        sample = (pop + b1 + b2 + b3) * 0.9
        samples.append(sample)
    return samples

def gen_npc_chat():
    # Warm 2-tone melodic chirp / paper scroll rustle (G4 392Hz -> C5 523Hz) (0.24s)
    duration = 0.24
    n_samples = int(duration * SAMPLE_RATE)
    samples = []
    for i in range(n_samples):
        t = i / SAMPLE_RATE
        if t < 0.11:
            dt = t
            f = 392.0 # G4
            env = math.exp(-dt * 14.0) * min(1.0, dt / 0.01)
        else:
            dt = t - 0.11
            f = 523.25 # C5
            env = math.exp(-dt * 12.0) * min(1.0, dt / 0.01)
        tone = synth_triangle(f, dt) * 0.65 + synth_sine(f * 2.0, dt) * 0.25
        paper_rustle = (rng.random() * 2.0 - 1.0) * 0.08 * env
        sample = (tone + paper_rustle) * env * 0.88
        samples.append(sample)
    return samples

def main():
    print("=== Synthesizing PyQuest Core RPG Sound Effects ===")
    
    # 1. Combat & Code Execution
    write_wav("sfx_spell_cast.wav", gen_spell_cast())
    write_wav("sfx_boss_hit.wav", gen_boss_hit())
    write_wav("sfx_player_hurt.wav", gen_player_hurt())
    write_wav("sfx_error.wav", gen_error())
    write_wav("sfx_boss_defeat.wav", gen_boss_defeat())
    
    # 2. World Exploration & Shrines
    write_wav("sfx_shrine_awaken.wav", gen_shrine_awaken())
    write_wav("sfx_chest_open.wav", gen_chest_open())
    write_wav("sfx_bridge_extend.wav", gen_bridge_extend())
    write_wav("sfx_teleport.wav", gen_teleport())
    write_wav("sfx_relic_pickup.wav", gen_relic_pickup())
    write_wav("sfx_npc_chat.wav", gen_npc_chat())
    
    print("=== All 11 Core Sound Effects Successfully Generated! ===")

if __name__ == "__main__":
    main()
