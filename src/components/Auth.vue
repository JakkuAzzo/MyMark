<template>
  <div style="padding: 20px;">
    <h2>Auth</h2>
    <div>
      <input autocomplete="off" v-model="username" placeholder="Username" style="margin-right: 10px;" />
      <input v-model="password" type="password" placeholder="Password" style="margin-right: 10px;" />
      <button @click="handleRegister">Register</button>
      <button @click="handleLogin" style="margin-left: 10px;">Login</button>
    </div>
    <p>{{ status }}</p>
  </div>
  <!-- Webcam Modal for Login/Register -->
  <div v-if="showWebcamModal" class="modal cubist-modal-bg" style="position:relative;">
    <div class="modal-content cubist-modal">
      <!-- Overlay canvas absolutely positioned over video -->
      <div style="position: relative; display: inline-block;">
        <video ref="video" autoplay playsinline width="320" height="240" style="background:#222; display:block;"></video>
        <canvas ref="overlay" width="320" height="240"
          style="position:absolute; top:0; left:0; pointer-events:none; z-index:2;"></canvas>
      </div>
      <div v-if="registerStep === 'id'">
        <p>Show your identification document, then click Capture.</p>
      </div>
      <div v-else-if="registerStep === 'face'">
        <p>Now show your face, then click Capture.</p>
      </div>
      <div v-else>
        <p>Show your face, then click Capture.</p>
      </div>
      <button @click="captureImage" class="cubist-btn">Capture</button>
      <button @click="closeWebcamModal" class="cubist-btn">Cancel</button>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, nextTick, onMounted } from 'vue';
import * as faceapi from 'face-api.js';

const username = ref('');
const password = ref('');
const status = ref('');
const video = ref(null);
const overlay = ref(null);
const showWebcamModal = ref(false);
const registerStep = ref('id'); // or 'face', etc.

// Change: Use relative URL for registration endpoint
async function handleRegister() {
  status.value = 'Registering...';
  const res = await fetch('/api/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: username.value, password: password.value })
  });
  const data = await res.json();
  status.value = data.message || 'Registration failed.';
}

// Change: Use relative URL for login endpoint
async function handleLogin() {
  status.value = 'Logging in...';
  const res = await fetch('/api/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: username.value, password: password.value })
  });
  const data = await res.json();
  status.value = data.message || 'Login failed.';
}

// Change: In fetchUser, use relative URL "/api/user"
async function fetchUser() {
  try {
    const res = await fetch('/api/user', { credentials: 'include' });
    if (!res.ok) {
      console.error("fetchUser: response not OK:", await res.text());
      status.value = "User not logged in.";
      return;
    }
    const data = await res.json();
    // ...existing code...
  } catch (err) {
    console.error("fetchUser: network error", err);
    status.value = "Failed to fetch user (network error).";
  }
}

// Change: In faceRegisterWithImages, use relative URL for face register endpoint
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

// Ensure models are loaded only once
let modelsLoaded = false;
async function ensureModelsLoaded() {
  if (modelsLoaded) return;
  try {
    await faceapi.nets.tinyFaceDetector.loadFromUri('/models');
    await faceapi.nets.faceLandmark68TinyNet.loadFromUri('/models'); // <-- this is correct
    modelsLoaded = true;
  } catch (e) {
    status.value = "Failed to load face detection models. Check that /models contains all required files.";
    console.error(e);
  }
}

async function startFaceDetection() {
  await ensureModelsLoaded();
  detectionLoop();
}

function detectionLoop() {
  if (!video.value || !overlay.value) return;
  const displaySize = { width: video.value.width, height: video.value.height };
  faceapi.matchDimensions(overlay.value, displaySize);
  const detect = async () => {
    if (!video.value || video.value.readyState < 2) {
      requestAnimationFrame(detect);
      return;
    }
    const detections = await faceapi
      .detectAllFaces(video.value, new faceapi.TinyFaceDetectorOptions())
      .withFaceLandmarks(true);
    const resized = faceapi.resizeResults(detections, displaySize);
    const ctx = overlay.value.getContext('2d');
    ctx.clearRect(0, 0, overlay.value.width, overlay.value.height);
    if (resized && resized.length > 0) {
      faceapi.draw.drawDetections(overlay.value, resized);
      faceapi.draw.drawFaceLandmarks(overlay.value, resized);
    }
    requestAnimationFrame(detect);
  };
  detect();
}

watch(showWebcamModal, async (isOpen) => {
  if (isOpen) {
    await nextTick();
    if (video.value) {
      video.value.play();
      startFaceDetection();
    }
  } else {
    if (overlay.value) {
      overlay.value.getContext('2d').clearRect(0, 0, overlay.value.width, overlay.value.height);
    }
  }
});
</script>

<style scoped>
/* Ensure overlay is always above video */
.modal-content .overlay {
  z-index: 2;
}
</style>
