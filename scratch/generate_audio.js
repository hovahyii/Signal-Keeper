const fs = require('fs');
const path = require('path');

const audioDir = path.join(__dirname, '..', 'audio');
if (!fs.existsSync(audioDir)) {
  fs.mkdirSync(audioDir, { recursive: true });
}

function writeWav(filename, samples, sampleRate = 44100, numChannels = 2) {
  const byteRate = sampleRate * numChannels * 2;
  const blockAlign = numChannels * 2;
  const dataSize = samples.length * 2;
  const buffer = Buffer.alloc(44 + dataSize);

  // RIFF header
  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write('WAVE', 8);

  // fmt subchunk
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16); // Subchunk1Size
  buffer.writeUInt16LE(1, 20); // PCM
  buffer.writeUInt16LE(numChannels, 22);
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(byteRate, 28);
  buffer.writeUInt16LE(blockAlign, 32);
  buffer.writeUInt16LE(16, 34); // BitsPerSample

  // data subchunk
  buffer.write('data', 36);
  buffer.writeUInt32LE(dataSize, 40);

  for (let i = 0; i < samples.length; i++) {
    let s = Math.max(-1, Math.min(1, samples[i]));
    let intVal = s < 0 ? s * 32768 : s * 32767;
    buffer.writeInt16LE(Math.floor(intVal), 44 + i * 2);
  }

  fs.writeFileSync(filename, buffer);
  console.log(`Wrote ${filename} (${(dataSize / 1024).toFixed(1)} KB)`);
}

// 1. Synthesize Looping Ambient Cyber Background Music
function generateBgm() {
  const sampleRate = 44100;
  const bpm = 100;
  const beatSec = 60 / bpm;
  const bars = 8;
  const beatsPerBar = 4;
  const totalDuration = bars * beatsPerBar * beatSec; // ~19.2s
  const totalSamples = Math.floor(totalDuration * sampleRate);
  const stereoSamples = new Float32Array(totalSamples * 2);

  // Chords: Dm9, Bbmaj7, C9, Am7
  const chords = [
    [146.83, 220.00, 261.63, 329.63], // D3, A3, C4, E4
    [116.54, 174.61, 220.00, 293.66], // Bb2, F3, A3, D4
    [130.81, 196.00, 246.94, 293.66], // C3, G3, B3, D4
    [110.00, 164.81, 220.00, 261.63]  // A2, E3, A3, C4
  ];

  // Arp notes
  const arpScale = [220.0, 261.63, 293.66, 329.63, 392.0, 440.0, 523.25];

  for (let i = 0; i < totalSamples; i++) {
    const t = i / sampleRate;
    const barProgress = (t % totalDuration) / totalDuration;
    const chordIndex = Math.floor(barProgress * 4);
    const chord = chords[chordIndex];

    let left = 0;
    let right = 0;

    // A. Warm Pad (soft saw/sine blend with chorusing)
    for (let f = 0; f < chord.length; f++) {
      const freq = chord[f];
      const detuneL = 0.998;
      const detuneR = 1.002;
      const env = 0.5 + 0.5 * Math.sin(t * Math.PI * 2 / (totalDuration / 4));
      
      const vL = (Math.sin(2 * Math.PI * freq * detuneL * t) * 0.6 + 
                  (Math.asin(Math.sin(2 * Math.PI * freq * detuneL * t)) / (Math.PI/2)) * 0.4);
      const vR = (Math.sin(2 * Math.PI * freq * detuneR * t) * 0.6 + 
                  (Math.asin(Math.sin(2 * Math.PI * freq * detuneR * t)) / (Math.PI/2)) * 0.4);

      left += vL * 0.05 * env;
      right += vR * 0.05 * env;
    }

    // B. Pulsing Sub-bass
    const rootFreq = chord[0] * 0.5;
    const sub = Math.sin(2 * Math.PI * rootFreq * t);
    left += sub * 0.12;
    right += sub * 0.12;

    // C. 16th-note Electronic Data Stream / Pluck Arpeggio
    const sixteenth = (t / (beatSec / 4));
    const step = Math.floor(sixteenth);
    const frac = sixteenth - step;
    const arpFreq = arpScale[(step * 3 + chordIndex) % arpScale.length];
    const pluckEnv = Math.exp(-frac * 9.0);
    const pluck = Math.sin(2 * Math.PI * arpFreq * t) * pluckEnv;
    const pan = 0.5 + 0.4 * Math.sin(step * 0.7);

    left += pluck * 0.06 * pan;
    right += pluck * 0.06 * (1.0 - pan);

    // D. Soft high ambient drone shimmer
    const shimmer = Math.sin(2 * Math.PI * 880.0 * t) * 0.015 * (0.5 + 0.5 * Math.sin(t * 1.5));
    left += shimmer;
    right += shimmer;

    // Smooth loop boundary crossfade (50ms)
    const fadeSamples = Math.floor(sampleRate * 0.05);
    let masterEnv = 1.0;
    if (i < fadeSamples) masterEnv = i / fadeSamples;
    if (i > totalSamples - fadeSamples) masterEnv = (totalSamples - i) / fadeSamples;

    stereoSamples[i * 2] = left * masterEnv;
    stereoSamples[i * 2 + 1] = right * masterEnv;
  }

  writeWav(path.join(audioDir, 'bgm_ambient.wav'), stereoSamples, sampleRate, 2);
}

// 2. Synthesize Relay Rotate Click SFX
function generateRotateSfx() {
  const sampleRate = 44100;
  const duration = 0.07;
  const samples = Math.floor(sampleRate * duration);
  const data = new Float32Array(samples * 2);

  for (let i = 0; i < samples; i++) {
    const t = i / sampleRate;
    const env = Math.exp(-t * 60.0);
    const click = Math.sin(2 * Math.PI * (1200 - t * 8000) * t);
    const noise = (Math.random() * 2 - 1) * 0.3;
    const val = (click * 0.7 + noise * 0.3) * env * 0.4;
    data[i * 2] = val;
    data[i * 2 + 1] = val;
  }
  writeWav(path.join(audioDir, 'sfx_rotate.wav'), data, sampleRate, 2);
}

// 3. Synthesize Puzzle Solved Harmony Chime
function generateSolveSfx() {
  const sampleRate = 44100;
  const duration = 1.2;
  const samples = Math.floor(sampleRate * duration);
  const data = new Float32Array(samples * 2);

  const notes = [440.0, 554.37, 659.25, 880.0, 1108.73]; // A major cyber chord
  for (let i = 0; i < samples; i++) {
    const t = i / sampleRate;
    let s = 0;
    for (let n = 0; n < notes.length; n++) {
      const noteDelay = n * 0.08;
      if (t >= noteDelay) {
        const localT = t - noteDelay;
        const env = Math.exp(-localT * 3.5);
        s += Math.sin(2 * Math.PI * notes[n] * localT) * env * 0.15;
        // octave overtone
        s += Math.sin(2 * Math.PI * notes[n] * 2 * localT) * env * 0.05;
      }
    }
    data[i * 2] = s;
    data[i * 2 + 1] = s;
  }
  writeWav(path.join(audioDir, 'sfx_solved.wav'), data, sampleRate, 2);
}

generateBgm();
generateRotateSfx();
generateSolveSfx();
console.log('Audio generation complete!');
