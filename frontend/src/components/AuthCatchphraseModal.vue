<template>
  <div v-if="auth.showVocalModal" class="cubist-modal-bg catchphrase-modal-overlay">
    <div class="cubist-modal catchphrase-modal-content">
      <h2 class="cubist-title">Catchphrase Registration</h2>
      <div class="catchphrase-words">
        <b>Your catchphrase:</b>
        <span v-for="(word, idx) in auth.catchphraseWords" :key="idx" class="catchphrase-word">{{ word }}</span>
      </div>
      <div v-for="(rec, idx) in auth.catchphraseRecordings" :key="idx" class="catchphrase-recording-row">
        <span>Recording {{ idx + 1 }}</span>
        <audio v-if="rec.dataUrl" :src="rec.dataUrl" controls style="vertical-align:middle; margin:0 8px;" />
        <button @click="auth.deleteCatchphraseRecording(idx)" class="cubist-btn small-btn">Delete</button>
      </div>
      <div v-if="auth.catchphraseRecordings.length < 2" class="catchphrase-record-btns">
        <button @click="startRecording('normal')" class="cubist-btn" :disabled="auth.recording">
          Record (normal)
        </button>
        <button @click="startRecording('funny')" class="cubist-btn" :disabled="auth.recording">
          Record (funny/other style)
        </button>
        <div v-if="auth.recording" class="catchphrase-recording-indicator">
          <span class="recording-dot"></span>
          Recording... {{ auth.recordCountdown }}s left
        </div>
      </div>
      <div v-if="auth.catchphraseRecordings.length === 2">
        <button @click="verifyVoice" class="cubist-btn">Verify Voice</button>
      </div>
      <button @click="onCancel" class="cubist-btn">Cancel</button>
      <div v-if="auth.status && auth.showVocalModal" class="cubist-status" :style="{color: auth.statusColor}">{{ auth.status }}</div>
    </div>
  </div>
</template>
<script setup>
import { useAuthStore } from '../stores/auth';
const auth = useAuthStore();

function startRecording(style) {
  auth.startCatchphraseRecording(style);
}

function verifyVoice() {
  auth.submitVocal();
}

function onCancel() {
  auth.closeVocalModal();
}
</script>
<style scoped>
.cubist-modal-bg.catchphrase-modal-overlay {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(30,30,30,0.25);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
}
.cubist-modal.catchphrase-modal-content {
  background: #fff;
  border: 4px solid #111;
  border-radius: 18px 0 18px 0;
  width: 400px;
  max-width: 98vw;
  padding: 32px 24px 24px 24px;
  display: flex;
  flex-direction: column;
  align-items: center;
  box-shadow: 8px 8px 0 #bbb, 0 0 0 8px #fff inset;
}
.catchphrase-words {
  margin-bottom: 18px;
  font-size: 1.1em;
  text-align: center;
}
.catchphrase-word {
  display: inline-block;
  background: #e3f2fd;
  color: #111;
  border-radius: 6px;
  padding: 2px 10px;
  margin: 0 3px;
  font-weight: bold;
  font-size: 1.1em;
}
.catchphrase-recording-row {
  margin-bottom: 10px;
  display: flex;
  align-items: center;
  gap: 8px;
}
.catchphrase-record-btns {
  display: flex;
  gap: 10px;
  margin-bottom: 10px;
  flex-wrap: wrap;
  justify-content: center;
}
.cubist-btn.small-btn {
  padding: 2px 10px;
  font-size: 0.95em;
  margin-left: 6px;
  margin-top: 0;
  width: auto;
  min-width: 0;
}
.catchphrase-recording-indicator {
  color: #e53935;
  font-weight: bold;
  margin-top: 8px;
  text-align: center;
}
.recording-dot {
  display: inline-block;
  width: 10px;
  height: 10px;
  background: #e53935;
  border-radius: 50%;
  margin-right: 6px;
  vertical-align: middle;
}
.cubist-title {
  font-size: 1.5em;
  font-weight: bold;
  margin-bottom: 18px;
  text-align: center;
}
.cubist-status {
  margin-top: 12px;
  min-height: 24px;
  text-align: center;
}
@media (max-width: 600px) {
  .cubist-modal.catchphrase-modal-content {
    width: 98vw;
    max-width: 98vw;
    padding: 12px 4px 12px 4px;
  }
}
</style>
