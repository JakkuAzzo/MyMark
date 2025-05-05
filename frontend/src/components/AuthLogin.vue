<template>
  <div class="auth-form cubist-form">
    <input v-model="auth.loginUsername" placeholder="Username" class="cubist-input" />
    <button @click="auth.openWebcamModal('login')" class="cubist-btn face-btn">Face Login</button>
    <button @click="toggleCatchphraseLogin" class="cubist-btn vocal-btn">Catchphrase Login</button>
    <div v-if="catchphraseLogin">
      <p>Please record your catchphrase twice:</p>
      <button @click="recordCatchphrase" class="cubist-btn">
        Record ({{ catchphraseRecordCount }}/2)
      </button>
      <button v-if="recordings.length === 2" @click="playbackCatchphrase" class="cubist-btn">
        Playback
      </button>
      <button v-if="recordings.length === 2" @click="submitCatchphraseLogin" class="cubist-btn">
        Submit
      </button>
    </div>
    <p class="cubist-status" :style="{color: auth.statusColor}">{{ auth.status }}</p>
  </div>
</template>
<script setup>
import { ref } from 'vue';
import { useAuthStore } from '../stores/auth';
const auth = useAuthStore();
const catchphraseLogin = ref(false);
const catchphraseRecordCount = ref(0);
const recordings = ref([]);
function toggleCatchphraseLogin() {
  catchphraseLogin.value = !catchphraseLogin.value;
  if (catchphraseLogin.value) {
    recordings.value = [];
    catchphraseRecordCount.value = 0;
  }
}
async function recordCatchphrase() {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    const mediaRecorder = new MediaRecorder(stream);
    let chunks = [];
    mediaRecorder.ondataavailable = e => chunks.push(e.data);
    mediaRecorder.onstop = () => {
      const blob = new Blob(chunks, { type: 'audio/webm' });
      const reader = new FileReader();
      reader.onloadend = () => {
        recordings.value.push(reader.result);
        catchphraseRecordCount.value++;
      };
      reader.readAsDataURL(blob);
      stream.getTracks().forEach(track => track.stop());
    };
    mediaRecorder.start();
    setTimeout(() => { mediaRecorder.stop(); }, 3000);
  } catch (err) {}
}
function playbackCatchphrase() {
  if (recordings.value.length === 2) {
    const audio1 = new Audio(recordings.value[0]);
    const audio2 = new Audio(recordings.value[1]);
    audio1.play();
    audio1.onended = () => audio2.play();
  }
}
async function submitCatchphraseLogin() {
  if (recordings.value.length !== 2 || !auth.loginUsername) return;
  // Implement API call for catchphrase login if needed
  // On success:
  auth.loggedIn = true;
}
</script>
<style scoped>
/* ...login-specific styles... */
</style>
