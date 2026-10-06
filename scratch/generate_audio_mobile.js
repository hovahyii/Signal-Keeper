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

  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write('WAVE', 8);

  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20); // PCM
  buffer.writeUInt16LE(numChannels, 22);
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(byteRate, 28);
  buffer.writeUInt16LE(blockAlign, 32);
  buffer.writeUInt16LE(16, 34);

  buffer.write('data', 36);
  buffer.writeUInt32LE(dataSize, 40);

  // Find max amplitude to normalize
  let peak = 0;
  for (let i = 0; i < samples.length; i++) {
    const a = Math.abs(samples[i]);
    if (a > peak) peak = a;
  }
  const gain = peak > 0 ? 0.95 / peak : 1.0;

  for (let i = 0; i < samples.length; i++) {
    let s = Math.max(-1, Math.min(1, samples[i] * gain));
    let intVal = s < 0 ? s * 32768 : s * 32767;
    buffer.writeInt16LE(Math.floor(intVal), 44 + i * 2);
  }

  fs.writeFileSync(filename, buffer);
  console.log(`Wrote ${filename} (${(dataSize / 1024).toFixed(1)} KB), peak normalized with gain: ${gain.toFixed(2)}`);
}

function generateMobileBgm() {
  const sampleRate = 44100;
  const bpm = 118; // Energetic, driving tempo
  const beatSec = 60 / bpm;
  const bars = 8; // 8 bar loop = 32 beats = ~16.27 seconds
  const totalDuration = bars * 4 * beatSec;
  const totalSamples = Math.floor(totalDuration * sampleRate);
  const stereoSamples = new Float32Array(totalSamples * 2);

  // Chords: Dm, F, C, Gm (4 bars x 2 repeats)
  // Voiced in 250Hz - 900Hz range for mobile speaker punch
  const chordProg = [
    [293.66, 349.23, 440.00, 587.33], // D4, F4, A4, D5 (Dm)
    [349.23, 440.00, 523.25, 698.46], // F4, A4, C5, F5 (F)
    [261.63, 329.63, 392.00, 523.25], // C4, E4, G4, C5 (C)
    [392.00, 466.16, 587.33, 783.99], // G4, Bb4, D5, G5 (Gm)
  ];

  // Arp pattern pitches (Pentatonic D-minor: D4, F4, G4, A4, C5, D5, F5, A5)
  const arpNotes = [293.66, 349.23, 392.00, 440.00, 523.25, 587.33, 698.46, 880.00];
  const arpPattern = [0, 2, 4, 7, 5, 3, 2, 4, 1, 3, 5, 6, 4, 2, 3, 5];

  for (let i = 0; i < totalSamples; i++) {
    const t = i / sampleRate;
    const barProgress = (t / (totalDuration / 2)) % 1.0;
    const chordIndex = Math.floor(barProgress * 4) % 4;
    const chord = chordProg[chordIndex];

    let left = 0;
    let right = 0;

    // 1. Driving Arpeggiated Synth Lead (16th notes: ~8 notes per second)
    const sixteenth = t / (beatSec / 4);
    const step = Math.floor(sixteenth);
    const frac = sixteenth - step;
    const noteIdx = arpPattern[step % arpPattern.length];
    const freq = arpNotes[noteIdx];

    // Sharp pluck envelope
    const env = Math.exp(-frac * 7.5);
    // Square + Saw synth wave with bite (rich in odd & even harmonics)
    const phase = 2 * Math.PI * freq * t;
    const wave = (Math.sin(phase) * 0.5 + Math.sin(phase * 2) * 0.25 + Math.sin(phase * 3) * 0.15) * env;
    const pan = 0.5 + 0.3 * Math.sin(step * 1.3);
    left += wave * 0.45 * pan;
    right += wave * 0.45 * (1.0 - pan);

    // 2. Audible Mid-Range Bassline (8th note groove, 146Hz - 220Hz with 2nd & 3rd harmonics for phone speakers)
    const eighth = t / (beatSec / 2);
    const eighthStep = Math.floor(eighth);
    const eighthFrac = eighth - eighthStep;
    const bassRoot = chord[0] * 0.5; // D3 (146Hz), F3 (174Hz), C3 (130Hz), G3 (196Hz)
    const bassEnv = Math.exp(-eighthFrac * 4.0);
    // Harmonics make the bass clearly audible on mobile phone speakers
    const bPhase = 2 * Math.PI * bassRoot * t;
    const bass = (Math.sin(bPhase) * 0.4 + Math.sin(bPhase * 2) * 0.4 + Math.sin(bPhase * 3) * 0.2) * bassEnv;
    left += bass * 0.35;
    right += bass * 0.35;

    // 3. Cyberpunk Warm Pad chords (slow breathing volume)
    const chordEnv = 0.5 + 0.4 * Math.sin((t / beatSec) * Math.PI);
    for (let c = 0; c < chord.length; c++) {
      const cFreq = chord[c];
      const pL = 2 * Math.PI * (cFreq * 0.998) * t;
      const pR = 2 * Math.PI * (cFreq * 1.002) * t;
      left += Math.sin(pL) * 0.08 * chordEnv;
      right += Math.sin(pR) * 0.08 * chordEnv;
    }

    // 4. Electronic Hi-Hat & Percussion click on 16th notes (tick tick tick tick)
    if (frac < 0.1) {
      const clickEnv = Math.exp(-frac * 60.0);
      const noise = (Math.random() * 2 - 1) * clickEnv;
      const isBeat = (step % 4 === 2); // Accent on offbeats
      const clickVol = isBeat ? 0.25 : 0.12;
      left += noise * clickVol;
      right += noise * clickVol;
    }

    // 5. Kick click (punchy mid-frequency pop on every beat)
    const beatFrac = (t / beatSec) - Math.floor(t / beatSec);
    if (beatFrac < 0.08) {
      const kickFreq = 160.0 * Math.exp(-beatFrac * 35.0); // pitch drop from 160Hz
      const kickEnv = Math.exp(-beatFrac * 25.0);
      const kick = Math.sin(2 * Math.PI * kickFreq * t) * kickEnv * 0.4;
      left += kick;
      right += kick;
    }

    // Seamless loop crossfade on edges (first/last 20ms)
    const fadeSamples = Math.floor(sampleRate * 0.02);
    let masterEnv = 1.0;
    if (i < fadeSamples) masterEnv = i / fadeSamples;
    if (i > totalSamples - fadeSamples) masterEnv = (totalSamples - i) / fadeSamples;

    stereoSamples[i * 2] = left * masterEnv;
    stereoSamples[i * 2 + 1] = right * masterEnv;
  }

  writeWav(path.join(audioDir, 'bgm_ambient.wav'), stereoSamples, sampleRate, 2);
}

generateMobileBgm();
