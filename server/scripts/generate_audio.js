// Generate simple WAV audio files for white noise player
// Run: node scripts/generate_audio.js
const fs = require('fs');
const path = require('path');

function createWav(samples, sampleRate = 22050) {
  const numChannels = 1;
  const bitsPerSample = 16;
  const byteRate = sampleRate * numChannels * bitsPerSample / 8;
  const blockAlign = numChannels * bitsPerSample / 8;
  const dataSize = samples.length * blockAlign;
  const buffer = Buffer.alloc(44 + dataSize);

  buffer.write('RIFF', 0);
  buffer.writeUInt32LE(36 + dataSize, 4);
  buffer.write('WAVE', 8);
  buffer.write('fmt ', 12);
  buffer.writeUInt32LE(16, 16);
  buffer.writeUInt16LE(1, 20);
  buffer.writeUInt16LE(numChannels, 22);
  buffer.writeUInt32LE(sampleRate, 24);
  buffer.writeUInt32LE(byteRate, 28);
  buffer.writeUInt16LE(blockAlign, 32);
  buffer.writeUInt16LE(bitsPerSample, 34);
  buffer.write('data', 36);
  buffer.writeUInt32LE(dataSize, 40);

  for (let i = 0; i < samples.length; i++) {
    const s = Math.max(-1, Math.min(1, samples[i]));
    buffer.writeInt16LE(Math.round(s * 32767), 44 + i * 2);
  }
  return buffer;
}

const duration = 30;
const sr = 22050;
const totalSamples = sr * duration;
const outDir = path.join(__dirname, '..', 'public', 'audio');
fs.mkdirSync(outDir, { recursive: true });

// ── Rain: filtered white noise ──
{
  const samples = new Float32Array(totalSamples);
  let prev = 0, prev2 = 0;
  for (let i = 0; i < totalSamples; i++) {
    const noise = Math.random() * 2 - 1;
    // Simple 2-pole low-pass filter
    const filtered = 0.05 * noise + 0.9 * prev + 0.05 * prev2;
    prev2 = prev;
    prev = filtered;
    samples[i] = filtered * 0.35;
  }
  fs.writeFileSync(path.join(outDir, 'rain.wav'), createWav(samples, sr));
  console.log('Generated rain.wav');
}

// ── Campfire: sparse crackles over soft noise ──
{
  const samples = new Float32Array(totalSamples);
  let prev = 0;
  for (let i = 0; i < totalSamples; i++) {
    let val = (Math.random() * 2 - 1) * 0.04;
    // Random crackle events
    if (Math.random() < 0.008) {
      const crackleLen = 10 + Math.floor(Math.random() * 40);
      for (let j = 0; j < crackleLen && i + j < totalSamples; j++) {
        const env = 1 - j / crackleLen;
        samples[i + j] += (Math.random() * 2 - 1) * 0.5 * env;
      }
    }
    prev = 0.97 * prev + 0.03 * val;
    samples[i] += prev;
  }
  // Normalize
  let max = 0;
  for (let i = 0; i < totalSamples; i++) max = Math.max(max, Math.abs(samples[i]));
  if (max > 0) for (let i = 0; i < totalSamples; i++) samples[i] /= max * 1.5;
  fs.writeFileSync(path.join(outDir, 'campfire.wav'), createWav(samples, sr));
  console.log('Generated campfire.wav');
}

// ── Ocean: slow amplitude modulation ──
{
  const samples = new Float32Array(totalSamples);
  let prev = 0;
  for (let i = 0; i < totalSamples; i++) {
    const t = i / sr;
    const wave = Math.sin(t * 0.08) * 0.6 + Math.sin(t * 0.13) * 0.3 + Math.sin(t * 0.21) * 0.1;
    const envelope = 0.3 + 0.7 * ((wave + 1) / 2);
    const noise = Math.random() * 2 - 1;
    prev = 0.98 * prev + 0.02 * noise;
    samples[i] = prev * envelope * 0.3;
  }
  fs.writeFileSync(path.join(outDir, 'ocean.wav'), createWav(samples, sr));
  console.log('Generated ocean.wav');
}

// ── Forest: sparse bird chirps with ambient noise ──
{
  const samples = new Float32Array(totalSamples);
  let prev = 0;
  for (let i = 0; i < totalSamples; i++) {
    let val = (Math.random() * 2 - 1) * 0.015;
    // Bird chirp events
    if (Math.random() < 0.003) {
      const chirpFreq = 800 + Math.random() * 1200;
      const chirpLen = 15 + Math.floor(Math.random() * 25);
      for (let j = 0; j < chirpLen && i + j < totalSamples; j++) {
        const t2 = j / sr;
        const env = Math.sin(j / chirpLen * Math.PI);
        const freqMod = chirpFreq + Math.sin(t2 * 40) * 300;
        samples[i + j] += Math.sin(2 * Math.PI * freqMod * t2) * 0.25 * env;
      }
    }
    prev = 0.97 * prev + 0.03 * val;
    samples[i] += prev;
  }
  let max = 0;
  for (let i = 0; i < totalSamples; i++) max = Math.max(max, Math.abs(samples[i]));
  if (max > 0) for (let i = 0; i < totalSamples; i++) samples[i] /= max * 2;
  fs.writeFileSync(path.join(outDir, 'forest.wav'), createWav(samples, sr));
  console.log('Generated forest.wav');
}

// ── Wind Chime: random bell tones ──
{
  const samples = new Float32Array(totalSamples);
  const frequencies = [523, 659, 784, 880, 1047, 1175, 1319, 1568];
  for (let i = 0; i < totalSamples; i++) {
    let val = 0;
    if (Math.random() < 0.015) {
      const freq = frequencies[Math.floor(Math.random() * frequencies.length)];
      const ringLen = 100 + Math.floor(Math.random() * 200);
      for (let j = 0; j < ringLen && i + j < totalSamples; j++) {
        const t2 = j / sr;
        const env = Math.exp(-t2 * 8);
        const tremolo = 1 + 0.15 * Math.sin(t2 * 5.5);
        samples[i + j] += Math.sin(2 * Math.PI * freq * t2) * 0.3 * env * tremolo;
      }
    }
    samples[i] += val;
  }
  let max = 0;
  for (let i = 0; i < totalSamples; i++) max = Math.max(max, Math.abs(samples[i]));
  if (max > 0) for (let i = 0; i < totalSamples; i++) samples[i] /= max * 2;
  fs.writeFileSync(path.join(outDir, 'chime.wav'), createWav(samples, sr));
  console.log('Generated chime.wav');
}

// ── Heartbeat: low-frequency pulses ──
{
  const samples = new Float32Array(totalSamples);
  const bpm = 60;
  const beatInterval = sr * 60 / bpm;
  for (let i = 0; i < totalSamples; i++) {
    const posInBeat = (i % Math.round(beatInterval)) / beatInterval;
    // Double beat (lub-dub)
    let envelope = 0;
    if (posInBeat < 0.03) envelope = Math.sin(posInBeat / 0.03 * Math.PI);
    else if (posInBeat > 0.06 && posInBeat < 0.09) envelope = Math.sin((posInBeat - 0.06) / 0.03 * Math.PI) * 0.7;
    const tone = Math.sin(2 * Math.PI * 50 * i / sr) * 0.6 + Math.sin(2 * Math.PI * 80 * i / sr) * 0.4;
    samples[i] = tone * envelope * 0.3;
  }
  fs.writeFileSync(path.join(outDir, 'heartbeat.wav'), createWav(samples, sr));
  console.log('Generated heartbeat.wav');
}

console.log('All audio files generated in', outDir);
