<template>
  <div>
    <!-- Removed local navbar. Only global navbar in App.vue should be shown. -->

    <div v-if="activePage==='info'" class="cubist-modal-bg">
      <div class="cubist-modal">
        <img src="/MyMark.svg" alt="MyMark Logo" class="logo info-logo" />
        <h2>About My Mark</h2>
        <div>
          <strong>My Mark</strong> is a privacy-first image watermarking and copyright protection platform.<br><br>
          <b>How it works:</b>
          <ul>
            <li>Register with your face or catchphrase and ID for secure, biometric authentication.</li>
            <li>Upload your images to embed invisible watermarks and register them on the blockchain.</li>
            <li>Scan for unauthorized use and prove ownership anytime.</li>
          </ul>
          <b>Why?</b><br>
          To empower creators and individuals to protect their digital identity and creative work in a decentralized, privacy-preserving way.
        </div>
        <button class="cubist-btn" @click="closeInfo">Close</button>
      </div>
    </div>

    <div v-if="!loggedIn && activePage==='auth'" class="auth-container cubist-card">
      <img src="/MyMark.svg" alt="MyMark Logo" class="logo" />
      <h2 class="cubist-title">Welcome to My Mark</h2>
      <div class="auth-tabs cubist-tabs">
        <button :class="['cubist-btn', tab==='login' && 'active']" @click="tab='login'">Login</button>
        <button :class="['cubist-btn', tab==='register' && 'active']" @click="tab='register'">Register</button>
      </div>
      <transition name="fade">
        <div v-if="tab==='login'" class="auth-form cubist-form">
          <button @click="openFaceLogin" class="cubist-btn face-btn">Face Login</button>
          <button @click="openVocalLogin" class="cubist-btn vocal-btn">Catchphrase Login</button>
        </div>
        <div v-else class="auth-form cubist-form">
          <input v-model="registerUsername" placeholder="Username" class="cubist-input" />
          <button @click="startRegisterID" class="cubist-btn face-btn">Register with ID & Face</button>
          <button @click="openVocalRegister" class="cubist-btn vocal-btn">Catchphrase Register</button>
        </div>
      </transition>
      <p class="status cubist-status">{{ status }}</p>
      <div v-if="showWebcamPrompt" class="webcam-prompt cubist-warning">
        <p>Please allow webcam and/or microphone access for face/catchphrase authentication.</p>
      </div>
      <!-- Webcam Modal for Login/Register -->
      <div v-if="showWebcamModal" class="modal cubist-modal-bg">
        <div class="modal-content cubist-modal">
          <video ref="video" autoplay playsinline width="320" height="240" style="display:block; background:#222;"></video>
          <canvas ref="canvas" width="320" height="240" style="display:none;"></canvas>
          <div v-if="registerStep === 'id'">
            <p>Show your identification document to the camera, then click Capture.</p>
          </div>
          <div v-else-if="registerStep === 'face'">
            <p>Now show your face to the camera, then click Capture.</p>
          </div>
          <div v-else>
            <p>Show your face to the camera, then click Capture.</p>
          </div>
          <button @click="captureImage" class="cubist-btn">Capture</button>
          <button @click="closeWebcamModal" class="cubist-btn">Cancel</button>
        </div>
      </div>
      <!-- Vocal Modal for Login/Register -->
      <div v-if="showVocalModal" class="modal cubist-modal-bg">
        <div class="modal-content cubist-modal">
          <div v-if="!recording">
            <p>Please record your catchphrase or type it below.</p>
            <button @click="startRecording" class="cubist-btn">Start Recording</button>
          </div>
          <div v-else>
            <p>Recording... <button @click="stopRecording" class="cubist-btn">Stop</button></p>
          </div>
          <textarea v-model="typedCatchphrase" placeholder="Or type your catchphrase here" class="cubist-input"></textarea>
          <button @click="submitVocal" class="cubist-btn">Submit</button>
          <button @click="closeVocalModal" class="cubist-btn">Cancel</button>
        </div>
      </div>
    </div>
    <div v-else-if="loggedIn">
      <div class="dashboard cubist-card">
        <img src="/MyMark.svg" alt="MyMark Logo" class="logo dashboard-logo" />
        <h2 class="cubist-title">Dashboard</h2>
        <div class="stats cubist-stats">
          <div><strong>Username:</strong> {{ user.username }}</div>
          <div><strong>Images:</strong> {{ user.images }}</div>
          <div><strong>Matches:</strong> {{ user.matches }}</div>
          <div><strong>Last Scan:</strong> {{ user.last_scan }}</div>
        </div>
        <div class="tips cubist-tips">
          <h4>Tips for Keeping Your Images Safe:</h4>
          <ul>
            <li>Don't share your original images online.</li>
            <li>Use watermarks to protect your images.</li>
            <li>Regularly check for unauthorized use of your images.</li>
            <li>Keep your credentials secure.</li>
          </ul>
        </div>
        <button @click="logout" class="cubist-btn logout-btn">Logout</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick, watch } from 'vue';

const status = ref('');
const tab = ref('login');
const loggedIn = ref(false);
const user = ref({});
const showWebcamPrompt = ref(false);
const showWebcamModal = ref(false);
const showVocalModal = ref(false);
const registerUsername = ref('');
const registerStep = ref(''); // '', 'id', 'face'
const idImage = ref(null);
const faceImage = ref(null);
const video = ref(null);
const canvas = ref(null);
let stream = null;

// Vocal (catchphrase) logic
const recording = ref(false);
const audioBlob = ref(null);
const typedCatchphrase = ref('');
let mediaRecorder = null;
let audioChunks = [];

async function fetchUser() {
  try {
    const res = await fetch('/api/user', { credentials: 'include' });
    if (!res.ok) {
      loggedIn.value = false;
      return;
    }
    const data = await res.json();
    if (data.status === 'success') {
      user.value = data;
      loggedIn.value = true;
    } else {
      loggedIn.value = false;
    }
  } catch {
    loggedIn.value = false;
  }
}

async function logout() {
  await fetch('/api/logout', { method: 'POST', credentials: 'include' });
  loggedIn.value = false;
  status.value = '';
  activePage.value = 'auth';
}

function openWebcamModal(step = '') {
  registerStep.value = step;
  showWebcamModal.value = true;
}

function closeWebcamModal() {
  showWebcamModal.value = false;
  stopWebcam();
}

function startWebcam() {
  if (navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
    navigator.mediaDevices.getUserMedia({ video: true })
      .then(async s => {
        stream = s;
        await nextTick();
        if (video.value) {
          video.value.srcObject = stream;
          video.value.play();
        }
        showWebcamPrompt.value = false;
      })
      .catch((err) => {
        if (err.name === 'NotAllowedError') {
          status.value = "Camera access denied. Please allow camera access in your browser settings and reload the page.";
        } else if (err.name === 'NotFoundError') {
          status.value = "No camera device found. Please connect a camera and try again.";
        } else {
          status.value = "Unable to access the webcam. Please check permissions, ensure you are using HTTPS, and that no other app is using the camera.";
        }
        showWebcamPrompt.value = true;
      });
  } else {
    status.value = "Camera feature unavailable. Make sure you are using a secure (https) connection with a connected webcam.";
    showWebcamPrompt.value = true;
  }
}

function stopWebcam() {
  if (stream) {
    stream.getTracks().forEach(track => track.stop());
    stream = null;
  }
}

watch(showWebcamModal, async (val) => {
  await nextTick();
  if (val) {
    startWebcam();
  } else {
    stopWebcam();
  }
});

function captureImage() {
  if (!video.value || !canvas.value) return;
  const ctx = canvas.value.getContext('2d');
  ctx.drawImage(video.value, 0, 0, canvas.value.width, canvas.value.height);
  const dataUrl = canvas.value.toDataURL('image/jpeg');
  if (tab.value === 'login') {
    closeWebcamModal();
    faceLoginWithImage(dataUrl);
  } else if (tab.value === 'register') {
    if (registerStep.value === 'id') {
      idImage.value = dataUrl;
      openWebcamModal('face');
    } else if (registerStep.value === 'face') {
      faceImage.value = dataUrl;
      closeWebcamModal();
      faceRegisterWithImages();
    }
  }
}

function openFaceLogin() {
  requestCameraPermission();
  openWebcamModal();
}

async function faceLoginWithImage(imageData) {
  status.value = 'Logging in with face...';
  try {
    const res = await fetch('/api/face_login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ face_image: imageData }),
      credentials: 'include'
    });
    const data = await res.json();
    status.value = data.message || 'Face login failed.';
    if (data.status === 'success') {
      await fetchUser();
    }
  } catch {
    status.value = 'Face login failed (network error).';
  }
}

function startRegisterID() {
  if (!registerUsername.value) {
    status.value = "Please enter a username.";
    return;
  }
  idImage.value = null;
  faceImage.value = null;
  openWebcamModal('id');
}

async function faceRegisterWithImages() {
  status.value = 'Registering with ID and face...';
  try {
    const res = await fetch('/api/face_register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: registerUsername.value,
        id_image: idImage.value,
        face_image: faceImage.value
      }),
      credentials: 'include'
    });
    const data = await res.json();
    status.value = data.message || 'Face registration failed.';
    if (data.status === 'success') {
      await fetchUser();
    }
  } catch {
    status.value = 'Face registration failed (network error).';
  }
}

// Vocal (catchphrase) modal logic
function openVocalLogin() {
  requestMicPermission();
  showVocalModal.value = true;
  typedCatchphrase.value = '';
  audioBlob.value = null;
}
function openVocalRegister() {
  requestMicPermission();
  showVocalModal.value = true;
  typedCatchphrase.value = '';
  audioBlob.value = null;
}
function closeVocalModal() {
  showVocalModal.value = false;
  stopRecording();
}

function startRecording() {
  if (typeof navigator !== "undefined" && navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
    navigator.mediaDevices.getUserMedia({ audio: true })
      .then(stream => {
        mediaRecorder = new window.MediaRecorder(stream);
        audioChunks = [];
        mediaRecorder.ondataavailable = e => audioChunks.push(e.data);
        mediaRecorder.onstop = () => {
          audioBlob.value = new Blob(audioChunks, { type: 'audio/webm' });
        };
        mediaRecorder.start();
        recording.value = true;
      })
      .catch(() => {
        status.value = "Could not access microphone. Please check permissions.";
      });
  } else {
    status.value = "Microphone not supported in this environment.";
  }
}

function stopRecording() {
  if (mediaRecorder && recording.value) {
    mediaRecorder.stop();
    recording.value = false;
  }
}

async function submitVocal() {
  status.value = 'Submitting catchphrase...';
  let audioBase64 = '';
  if (audioBlob.value) {
    const reader = new FileReader();
    reader.onloadend = async () => {
      audioBase64 = reader.result.split(',')[1];
      await sendVocal(audioBase64, typedCatchphrase.value);
    };
    reader.readAsDataURL(audioBlob.value);
  } else {
    await sendVocal('', typedCatchphrase.value);
  }
  closeVocalModal();
}

async function sendVocal(audio, text) {
  try {
    const endpoint = tab.value === 'login' ? '/api/vocal_login' : '/api/vocal_register';
    const body = tab.value === 'login'
      ? { audio, catchphrase: text }
      : { audio, catchphrase: text, username: registerUsername.value };
    const res = await fetch(endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      credentials: 'include'
    });
    const data = await res.json();
    status.value = data.message || 'Catchphrase auth failed.';
    if (data.status === 'success') {
      await fetchUser();
    }
  } catch {
    status.value = 'Catchphrase auth failed (network error).';
  }
}

const activePage = ref('auth');
const showInfo = ref(false);

function openInfo() {
  activePage.value = 'info';
}
function closeInfo() {
  activePage.value = 'auth';
}

// Add missing requestMediaPermissions function
function requestMediaPermissions() {
  if (typeof navigator !== "undefined" && navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
    navigator.mediaDevices.getUserMedia({ video: true, audio: true })
      .then(stream => {
        stream.getTracks().forEach(track => track.stop());
        showWebcamPrompt.value = false;
      })
      .catch(() => {
        showWebcamPrompt.value = true;
      });
  } else {
    showWebcamPrompt.value = true;
  }
}

// Request camera permission and show error if denied
function requestCameraPermission() {
  if (typeof navigator !== "undefined" && navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
    navigator.mediaDevices.getUserMedia({ video: true })
      .then(stream => {
        stream.getTracks().forEach(track => track.stop());
        showWebcamPrompt.value = false;
      })
      .catch(() => {
        status.value = "Camera permission denied. Please allow access to use face login/register.";
        showWebcamPrompt.value = true;
      });
  } else {
    status.value = "Camera not supported in this environment.";
    showWebcamPrompt.value = true;
  }
}

// Request microphone permission and show error if denied
function requestMicPermission() {
  if (typeof navigator !== "undefined" && navigator.mediaDevices && navigator.mediaDevices.getUserMedia) {
    navigator.mediaDevices.getUserMedia({ audio: true })
      .then(stream => {
        stream.getTracks().forEach(track => track.stop());
        showWebcamPrompt.value = false;
      })
      .catch(() => {
        status.value = "Microphone permission denied. Please allow access to use vocal login/register.";
        showWebcamPrompt.value = true;
      });
  } else {
    status.value = "Microphone not supported in this environment.";
    showWebcamPrompt.value = true;
  }
}

onMounted(() => {
  fetchUser();
  requestMediaPermissions();
});
</script>

<style scoped>
/* Cubist palette and geometric style */
body {
  background: #f5f5f5;
}
.cubist-btn {
  background: #e0e0e0;
  color: #111;
  border: 2px solid #111;
  border-radius: 0;
  font-weight: bold;
  font-family: 'Montserrat', 'Arial', sans-serif;
  padding: 10px 24px;
  margin: 0 4px;
  box-shadow: 2px 2px 0 #111, 4px 4px 0 #bbb;
  transition: background 0.2s, color 0.2s, box-shadow 0.2s;
  cursor: pointer;
  position: relative;
}
.cubist-btn.active, .cubist-btn:hover {
  background: #222;
  color: #fff;
  box-shadow: 2px 2px 0 #fff, 4px 4px 0 #222;
}
.cubist-username {
  color: #fff;
  background: #111;
  border: 2px solid #fff;
  padding: 8px 18px;
  font-weight: bold;
  border-radius: 0;
  margin-left: 16px;
  box-shadow: 2px 2px 0 #bbb;
}
.cubist-card {
  background: #fff;
  border: 4px solid #111;
  border-radius: 18px 0 18px 0;
  box-shadow: 8px 8px 0 #bbb, 0 0 0 8px #fff inset;
  padding: 40px 32px 32px 32px;
  margin: 40px auto;
  max-width: 420px;
  min-width: 320px;
  text-align: center;
}
.cubist-title {
  font-family: 'Montserrat', 'Arial', sans-serif;
  font-weight: 900;
  font-size: 2em;
  color: #111;
  margin-bottom: 18px;
  letter-spacing: 1px;
}
.cubist-tabs {
  display: flex;
  margin-bottom: 18px;
  gap: 0;
}
.cubist-tabs .cubist-btn {
  flex: 1;
  border-radius: 0;
  margin: 0;
  border-right: none;
}
.cubist-tabs .cubist-btn:last-child {
  border-right: 2px solid #111;
}
.cubist-form {
  display: flex;
  flex-direction: column;
  gap: 18px;
  margin-bottom: 16px;
}
.cubist-input {
  padding: 12px;
  border-radius: 0;
  border: 2px solid #111;
  font-size: 1.1em;
  background: #f5f5f5;
  color: #111;
  font-family: 'Montserrat', 'Arial', sans-serif;
}
.cubist-status {
  color: #e53935;
  font-weight: bold;
  min-height: 24px;
}
.cubist-warning {
  background: #fff3cd;
  color: #856404;
  border: 2px solid #111;
  border-radius: 8px 0 8px 0;
  padding: 16px;
  margin-top: 18px;
  font-weight: bold;
  box-shadow: 2px 2px 0 #bbb;
}
.cubist-modal-bg {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(30,30,30,0.25);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}
.cubist-modal {
  background: #fff;
  border: 4px solid #111;
  border-radius: 18px 0 18px 0;
  box-shadow: 8px 8px 0 #bbb, 0 0 0 8px #fff inset;
  padding: 32px 32px 24px 32px;
  max-width: 420px;
  min-width: 320px;
  text-align: center;
}
.info-logo {
  width: 72px;
  height: 72px;
  margin-bottom: 18px;
}
.logo {
  display: block;
  margin: 0 auto 16px auto;
  width: 64px;
  height: 64px;
}
.dashboard-logo {
  margin-bottom: 24px;
  width: 48px;
  height: 48px;
}
.cubist-stats {
  margin-bottom: 24px;
  text-align: left;
  border-left: 4px solid #111;
  padding-left: 18px;
  font-size: 1.1em;
}
.cubist-tips {
  background: #f5f5f5;
  border: 2px solid #111;
  border-radius: 8px 0 8px 0;
  padding: 16px;
  margin-bottom: 24px;
  box-shadow: 2px 2px 0 #bbb;
  text-align: left;
}
.logout-btn {
  background: #e53935;
  color: #fff;
  border: 2px solid #111;
  font-weight: bold;
  border-radius: 0;
  box-shadow: 2px 2px 0 #bbb;
}
.nav-tooltip {
  position: absolute;
  left: 50%;
  top: 120%;
  transform: translateX(-50%);
  background: #fff;
  color: #333;
  padding: 6px 12px;
  border-radius: 6px;
  box-shadow: 0 2px 8px #0002;
  white-space: nowrap;
  font-size: 0.95em;
  z-index: 10;
}
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.5s;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
</style>
