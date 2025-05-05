import { defineStore } from 'pinia';
import { ref } from 'vue';

export const useAuthStore = defineStore('auth', () => {
  // State
  const user = ref(null);
  const loggedIn = ref(false);
  const status = ref('');
  const statusColor = ref('#e53935');
  const tab = ref('login');
  const registerUsername = ref('');
  const idImage = ref(null);
  const faceImage = ref(null);
  const faceMatch = ref(null);
  const idError = ref('');
  const catchphraseWords = ref([]);
  const catchphraseBackup = ref('');
  const catchphraseRecordings = ref([]);
  const recording = ref(false);
  const recordCountdown = ref(3);
  const showWebcamModal = ref(false);
  const registerStep = ref('id'); // 'id', 'face', 'catchphrase', 'submit'
  const showVocalModal = ref(false);
  const ageDetected = ref(false);
  const detectedAge = ref(null);
  const idDetected = ref(false);
  const activePage = ref('auth');
  const showWebcamPrompt = ref(false);
  const loginUsername = ref('');

  // --- Methods expected by UI ---
  function openWebcamModal(step) {
    showWebcamModal.value = true;
    registerStep.value = step;
    showWebcamPrompt.value = false;
  }
  function closeWebcamModal() {
    showWebcamModal.value = false;
    registerStep.value = '';
  }
  function openVocalRegister() {
    showVocalModal.value = true;
    catchphraseRecordings.value = [];
    recording.value = false;
    recordCountdown.value = 3;
    status.value = '';
  }
  function closeVocalModal() {
    showVocalModal.value = false;
    catchphraseRecordings.value = [];
    recording.value = false;
    recordCountdown.value = 3;
    status.value = '';
  }
  function generateCatchphraseWords() {
    // Example: generate 4 random words
    const words = [];
    const wordList = [
      'apple','banana','cat','dog','echo','fox','grape','hat','ice','jazz','kite','lemon','moon','nest','owl','pear','quiz','rose','star','tree','urn','vase','wolf','xray','yarn','zebra'
    ];
    for (let i = 0; i < 4; i++) {
      words.push(wordList[Math.floor(Math.random() * wordList.length)]);
    }
    catchphraseWords.value = words;
    catchphraseBackup.value = words.join(' ');
  }
  function startCatchphraseRecording(style) {
    recording.value = true;
    recordCountdown.value = 3;
  }
  function deleteCatchphraseRecording(idx) {
    catchphraseRecordings.value.splice(idx, 1);
  }
  async function submitVocal() {
    // Real API call for catchphrase registration
    if (catchphraseRecordings.value.length !== 2 || !registerUsername.value) {
      status.value = 'Please record your catchphrase twice.';
      statusColor.value = '#e53935';
      return;
    }
    status.value = 'Submitting catchphrase...';
    statusColor.value = '#111';
    try {
      const res = await fetch('/api/vocal_register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          username: registerUsername.value,
          audio1: catchphraseRecordings.value[0].split(',')[1],
          audio2: catchphraseRecordings.value[1].split(',')[1],
          catchphrase: catchphraseWords.value.join(' ')
        })
      });
      const data = await res.json();
      if (data.status === 'success') {
        status.value = 'Catchphrase registered!';
        statusColor.value = '#43a047';
        showVocalModal.value = false;
      } else {
        status.value = data.message || 'Catchphrase registration failed.';
        statusColor.value = '#e53935';
      }
    } catch (e) {
      status.value = 'Network error.';
      statusColor.value = '#e53935';
    }
  }
  async function captureImage() {
    // This is a stub; actual webcam capture is handled in the component
    showWebcamModal.value = false;
    status.value = 'Image captured.';
    statusColor.value = '#43a047';
  }
  async function submitFaceRegister() {
    // Real API call for registration
    if (!registerUsername.value || !idImage.value || !faceImage.value) {
      status.value = 'Please provide all required images and username.';
      statusColor.value = '#e53935';
      return;
    }
    status.value = 'Registering...';
    statusColor.value = '#111';
    try {
      const res = await fetch('/api/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          username: registerUsername.value,
          id_image: idImage.value,
          face_image: faceImage.value,
          catchphrase_embedding: null // Optionally add catchphrase embedding
        })
      });
      const data = await res.json();
      if (data.status === 'success') {
        status.value = 'Registration successful!';
        statusColor.value = '#43a047';
        loggedIn.value = true;
        user.value = { username: registerUsername.value };
      } else {
        status.value = data.message || 'Registration failed.';
        statusColor.value = '#e53935';
      }
    } catch (e) {
      status.value = 'Network error.';
      statusColor.value = '#e53935';
    }
  }
  async function submitLogin(faceImageData) {
    // Real API call for login
    if (!loginUsername.value || !faceImageData) {
      status.value = 'Please provide username and face image.';
      statusColor.value = '#e53935';
      return;
    }
    status.value = 'Logging in...';
    statusColor.value = '#111';
    try {
      const res = await fetch('/api/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          username: loginUsername.value,
          face_image: faceImageData
        })
      });
      const data = await res.json();
      if (data.status === 'success') {
        status.value = 'Login successful!';
        statusColor.value = '#43a047';
        loggedIn.value = true;
        user.value = { username: loginUsername.value };
      } else {
        status.value = data.message || 'Login failed.';
        statusColor.value = '#e53935';
      }
    } catch (e) {
      status.value = 'Network error.';
      statusColor.value = '#e53935';
    }
  }
  async function submitCatchphraseLogin(audio1, audio2) {
    // Real API call for catchphrase login
    if (!loginUsername.value || !audio1 || !audio2) {
      status.value = 'Please provide username and two recordings.';
      statusColor.value = '#e53935';
      return;
    }
    status.value = 'Logging in with catchphrase...';
    statusColor.value = '#111';
    try {
      const res = await fetch('/api/vocal_login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        credentials: 'include',
        body: JSON.stringify({
          username: loginUsername.value,
          audio1: audio1.split(',')[1],
          audio2: audio2.split(',')[1]
        })
      });
      const data = await res.json();
      if (data.status === 'success') {
        status.value = 'Catchphrase login successful!';
        statusColor.value = '#43a047';
        loggedIn.value = true;
        user.value = { username: loginUsername.value };
      } else {
        status.value = data.message || 'Catchphrase login failed.';
        statusColor.value = '#e53935';
      }
    } catch (e) {
      status.value = 'Network error.';
      statusColor.value = '#e53935';
    }
  }
  async function logout() {
    try {
      await fetch('/api/logout', { method: 'POST', credentials: 'include' });
    } catch {}
    loggedIn.value = false;
    user.value = null;
    status.value = 'Logged out.';
    statusColor.value = '#e53935';
  }
  function closeInfo() {
    activePage.value = 'auth';
  }

  // Registration step management
  function setRegisterStep(step) {
    registerStep.value = step;
  }
  function resetRegistration() {
    registerStep.value = 'id';
    idImage.value = null;
    faceImage.value = null;
    faceMatch.value = null;
    idError.value = '';
    status.value = '';
    statusColor.value = '#e53935';
    catchphraseWords.value = [];
    catchphraseRecordings.value = [];
  }

  return {
    // State
    user, loggedIn, status, statusColor, tab, registerUsername, idImage, faceImage, faceMatch, idError,
    catchphraseWords, catchphraseBackup, catchphraseRecordings, recording, recordCountdown,
    showWebcamModal, registerStep, showVocalModal, ageDetected, detectedAge, idDetected,
    activePage, showWebcamPrompt, loginUsername,
    // Methods
    openWebcamModal, closeWebcamModal, openVocalRegister, closeVocalModal,
    generateCatchphraseWords, startCatchphraseRecording, deleteCatchphraseRecording, submitVocal,
    captureImage, submitFaceRegister, submitLogin, submitCatchphraseLogin, logout, closeInfo,
    setRegisterStep, resetRegistration
  };
});
