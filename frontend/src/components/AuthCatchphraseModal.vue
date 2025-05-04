<template>
  <div v-if="auth.showVocalModal" class="modal cubist-modal-bg">
    <div class="modal-content cubist-modal">
      <div v-if="!auth.catchphraseWords.length">
        <button @click="auth.generateCatchphraseWords()" class="cubist-btn">Generate Random Catchphrase</button>
      </div>
      <div v-else>
        <p>
          <b>Your catchphrase:</b>
          <span style="font-family:monospace;">{{ auth.catchphraseWords.join(' ') }}</span>
          <br>
          <small>Record this phrase twice, in two different styles. Keep it safe as a backup password.</small>
        </p>
        <div v-for="(rec, idx) in auth.catchphraseRecordings" :key="idx" style="margin-bottom:8px;">
          <audio :src="rec.url" controls style="margin-top:8px;"></audio>
          <button @click="auth.deleteCatchphraseRecording(idx)" class="cubist-btn" style="margin-left:8px;">Delete</button>
          <span v-if="rec.style">({{ rec.style }})</span>
        </div>
        <div v-if="auth.catchphraseRecordings.length < 2">
          <button @click="auth.startCatchphraseRecording('normal')" class="cubist-btn" :disabled="auth.recording">
            Record (normal)
          </button>
          <button @click="auth.startCatchphraseRecording('funny')" class="cubist-btn" :disabled="auth.recording">
            Record (funny/other style)
          </button>
          <div v-if="auth.recording" class="catchphrase-recording-indicator">
            <span class="recording-dot"></span>
            Recording... {{ auth.recordCountdown }}s left
          </div>
        </div>
        <button v-if="auth.catchphraseRecordings.length === 2" @click="auth.submitVocal()" class="cubist-btn">Submit</button>
      </div>
      <button @click="auth.closeVocalModal()" class="cubist-btn">Cancel</button>
      <div v-if="auth.status && auth.showVocalModal" class="cubist-status" :style="{color: auth.statusColor}">{{ auth.status }}</div>
    </div>
  </div>
</template>
<script setup>
import { useAuthStore } from '../stores/auth';
const auth = useAuthStore();
</script>
<style scoped>
/* ...catchphrase modal-specific styles... */
</style>
