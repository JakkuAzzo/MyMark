import { defineStore } from 'pinia';
import { ref } from 'vue';

export const useAuthStore = defineStore('auth', () => {
  // User/session state
  const user = ref(null);
  const loggedIn = ref(false);
  const status = ref('');
  const statusColor = ref('#e53935');
  // Registration state
  const tab = ref('login');
  const registerUsername = ref('');
  const idImage = ref(null);
  const faceImage = ref(null);
  const faceMatch = ref(null);
  const idError = ref('');
  // Catchphrase state
  const catchphraseWords = ref([]);
  const catchphraseBackup = ref('');
  const catchphraseRecordings = ref([]);
  const recording = ref(false);
  const recordCountdown = ref(3);
  // Webcam modal state
  const showWebcamModal = ref(false);
  const registerStep = ref('');
  const showVocalModal = ref(false);
  // Age/ID detection
  const ageDetected = ref(false);
  const detectedAge = ref(null);
  const idDetected = ref(false);

  // Add any actions/methods as needed

  return {
    user, loggedIn, status, statusColor, tab, registerUsername, idImage, faceImage, faceMatch, idError,
    catchphraseWords, catchphraseBackup, catchphraseRecordings, recording, recordCountdown,
    showWebcamModal, registerStep, showVocalModal, ageDetected, detectedAge, idDetected
  };
});
