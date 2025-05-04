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
        <div>
          <!-- Login Form -->
          <div v-if="tab==='login'" class="auth-form cubist-form">
            <!-- Always require username for login -->
            <input v-model="loginUsername" placeholder="Username" class="cubist-input" />
            <button @click="openFaceLogin" class="cubist-btn face-btn">Face Login</button>
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
          </div>
          <!-- Register Form -->
          <div v-if="tab==='register'" class="auth-form cubist-form">
            <input v-model="registerUsername" placeholder="Username" class="cubist-input" />
            <!-- Step 1: Upload or capture ID card -->
            <div v-if="!idImage">
              <label><b>Upload ID document or take a picture of it below:</b></label>
              <input type="file" accept="image/*" @change="onIdFileChange" class="cubist-input" />
              <button @click="openWebcamModal('id')" class="cubist-btn id-btn">Capture ID Document</button>
              <div v-if="idError" style="color:red;">{{ idError }}</div>
            </div>
            <!-- Step 2: Capture face -->
            <div v-else-if="!faceImage">
              <label><b>Take a picture of your face:</b></label>
              <button @click="openWebcamModal('face')" class="cubist-btn face-btn">Capture Face Image</button>
            </div>
            <!-- Step 3: Show match result -->
            <div v-else>
              <p v-if="faceMatch === null">Comparing images…</p>
              <p v-else-if="!faceMatch" style="color:red;">Face images do not match. Please retry.</p>
              <p v-else style="color:green;">Face images match.</p>
            </div>
            <!-- Only show Submit button if images are available and match -->
            <button v-if="faceImage && idImage && faceMatch === true" @click="submitFaceRegister" class="cubist-btn">
              Submit Registration
            </button>
            <!-- Optional: Catchphrase register as additional measure -->
            <div style="margin-top:18px;">
              <label><b>Optional: Add a catchphrase for extra account security</b></label>
              <button @click="openVocalRegister" class="cubist-btn vocal-btn">Catchphrase Register (Optional)</button>
              <div v-if="catchphraseWords.length">
                <p>
                  <b>Your catchphrase:</b>
                  <span style="font-family:monospace;">{{ catchphraseWords.join(' ') }}</span>
                  <br>
                  <small>Record this phrase twice, in two different styles. Keep it safe as a backup password.</small>
                </p>
                <div v-for="(rec, idx) in catchphraseRecordings" :key="idx" style="margin-bottom:8px;">
                  <audio :src="rec.url" controls style="margin-top:8px;"></audio>
                  <button @click="deleteCatchphraseRecording(idx)" class="cubist-btn" style="margin-left:8px;">Delete</button>
                  <span v-if="rec.style">({{ rec.style }})</span>
                </div>
                <div v-if="catchphraseRecordings.length < 2">
                  <button
                    @click="startCatchphraseRecording('normal')"
                    class="cubist-btn"
                    :disabled="recording"
                  >
                    Record (normal)
                  </button>
                  <button
                    @click="startCatchphraseRecording('funny')"
                    class="cubist-btn"
                    :disabled="recording"
                  >
                    Record (funny/other style)
                  </button>
                  <div v-if="recording" class="catchphrase-recording-indicator">
                    <span class="recording-dot"></span>
                    Recording... {{ recordCountdown }}s left
                  </div>
                </div>
                <button v-if="catchphraseRecordings.length === 2" @click="submitVocal" class="cubist-btn">Submit Catchphrase</button>
              </div>
            </div>
          </div>
        </div>
      </transition>
      <p class="status cubist-status">{{ status }}</p>
      <div v-if="showWebcamPrompt" class="webcam-prompt cubist-warning">
        <p>Please allow webcam and/or microphone access for face/catchphrase authentication.</p>
      </div>
      <!-- Webcam Modal for Login/Register -->
      <div v-if="showWebcamModal" class="modal cubist-modal-bg" style="position:relative;">
        <div class="modal-content cubist-modal" style="position:relative;">
          <div style="position: relative; display: inline-block;">
            <video ref="video" autoplay playsinline width="320" height="240" style="background:#222; display:block; z-index:1;"></video>
            <canvas ref="overlay" width="320" height="240"
              style="position:absolute; top:0; left:0; pointer-events:none; z-index:2;"></canvas>
            <!-- Live detection status box (top right) -->
            <div
              style="position:absolute; top:8px; right:8px; z-index:10; background:rgba(255,255,255,0.95); border-radius:8px; padding:8px 14px; border:2px solid #111; min-width:120px; text-align:left; font-size:1em;">
              <div>
                <span :style="{color: ageDetected ? '#0a0' : '#a00', fontWeight:'bold'}">
                  ●
                </span>
                Age:
                <span :style="{color: ageDetected ? '#0a0' : '#a00', fontWeight:'bold'}">
                  {{ detectedAge !== null ? detectedAge : '--' }}
                </span>
              </div>
              <div>
                <span :style="{color: idDetected ? '#0a0' : '#a00', fontWeight:'bold'}">
                  ●
                </span>
                ID:
                <span :style="{color: idDetected ? '#0a0' : '#a00', fontWeight:'bold'}">
                  {{ idDetected ? 'Detected' : 'Not Detected' }}
                </span>
              </div>
            </div>
          </div>
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
          <div v-if="!catchphraseWords.length">
            <button @click="generateCatchphraseWords" class="cubist-btn">Generate Random Catchphrase</button>
          </div>
          <div v-else>
            <p>
              <b>Your catchphrase:</b>
              <span style="font-family:monospace;">{{ catchphraseWords.join(' ') }}</span>
              <br>
              <small>Record this phrase twice, in two different styles. Keep it safe as a backup password.</small>
            </p>
            <div v-for="(rec, idx) in catchphraseRecordings" :key="idx" style="margin-bottom:8px;">
              <audio :src="rec.url" controls style="margin-top:8px;"></audio>
              <button @click="deleteCatchphraseRecording(idx)" class="cubist-btn" style="margin-left:8px;">Delete</button>
              <span v-if="rec.style">({{ rec.style }})</span>
            </div>
            <div v-if="catchphraseRecordings.length < 2">
              <button @click="startCatchphraseRecording('normal')" class="cubist-btn">Record (normal)</button>
              <button @click="startCatchphraseRecording('funny')" class="cubist-btn">Record (funny/other style)</button>
            </div>
            <button v-if="catchphraseRecordings.length === 2" @click="submitVocal" class="cubist-btn">Submit</button>
          </div>
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
import { ref, watch, nextTick, onMounted } from 'vue';
import * as faceapi from 'face-api.js';

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
const overlay = ref(null);
let stream = null;

// Vocal (catchphrase) logic
const recording = ref(false);
const audioBlob = ref(null);
const typedCatchphrase = ref('');
const audioBlobs = ref([]);
let mediaRecorder = null;
let audioChunks = [];

// New state for login
const loginUsername = ref('');
// New states for registration with Face & ID
const faceMatch = ref(null);
// New state for catchphrase login
const catchphraseLogin = ref(false);
const catchphraseRecordCount = ref(0);
const recordings = ref([]);

// Ensure all models are loaded only once
let modelsLoaded = false;
let modelsLoadingPromise = null;
async function ensureModelsLoaded() {
  if (modelsLoaded) return;
  if (modelsLoadingPromise) return modelsLoadingPromise;
  try {
    // Load all required models for detection and recognition
    modelsLoadingPromise = Promise.all([
      faceapi.nets.tinyFaceDetector.loadFromUri('/models'),
      faceapi.nets.ssdMobilenetv1.loadFromUri('/models'),
      faceapi.nets.faceLandmark68Net.loadFromUri('/models'),
      faceapi.nets.faceLandmark68TinyNet.loadFromUri('/models'),
      faceapi.nets.faceRecognitionNet.loadFromUri('/models'),
      faceapi.nets.faceExpressionNet.loadFromUri('/models'),
      faceapi.nets.ageGenderNet.loadFromUri('/models') // needed for age
    ]);
    await modelsLoadingPromise;
    modelsLoaded = true;
  } catch (e) {
    status.value = "Failed to load face detection/recognition models. Make sure /models is accessible and contains all model files.";
    console.error(e);
    throw e;
  }
}

// Compute FaceNet (face-api.js) embeddings and compare
async function compareFaces(idImgDataUrl, faceImgDataUrl) {
  await ensureModelsLoaded();
  // Helper to get embedding from dataURL
  async function getEmbedding(dataUrl) {
    const img = await faceapi.fetchImage(dataUrl);
    const detection = await faceapi
      .detectSingleFace(img, new faceapi.SsdMobilenetv1Options())
      .withFaceLandmarks()
      .withFaceDescriptor();
    return detection ? detection.descriptor : null;
  }
  const idEmbedding = await getEmbedding(idImgDataUrl);
  const faceEmbedding = await getEmbedding(faceImgDataUrl);
  if (!idEmbedding || !faceEmbedding) return false;
  // Euclidean distance threshold for FaceNet (face-api.js default: 0.6)
  const distance = faceapi.euclideanDistance(idEmbedding, faceEmbedding);
  return distance < 0.6;
}

// When both images are set, auto-compare them
watch([idImage, faceImage], async ([idImg, faceImg]) => {
  if (idImg && faceImg) {
    faceMatch.value = null;
    status.value = "Comparing images…";
    try {
      const match = await compareFaces(idImg, faceImg);
      faceMatch.value = match;
      status.value = match ? "Face images match." : "Face images do not match.";
    } catch (e) {
      faceMatch.value = false;
      status.value = "Face comparison failed.";
    }
  }
});

// Modified function for face register submission
async function submitFaceRegister() {
  if (!registerUsername.value || !idImage.value || !faceImage.value) {
    status.value = "Username, ID image and face image are required.";
    return;
  }
  if (faceMatch.value !== true) {
    status.value = "Face images have not been verified yet.";
    return;
  }
  status.value = "Images match. Submitting registration…";
  // Debug: log payload before sending
  console.log("Submitting face register:", {
    username: registerUsername.value,
    id_image: idImage.value?.slice(0, 30) + "...",
    face_image: faceImage.value?.slice(0, 30) + "..."
  });
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
    status.value = data.message || "Registration failed.";
    if (data.status === 'success') {
      await fetchUser();
    }
  } catch {
    status.value = "Registration failed (network error).";
  }
}

// Modified functions for catchphrase login
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
  } catch (err) {
    status.value = "Error recording audio: " + err.message;
  }
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
  if (recordings.value.length !== 2 || !loginUsername.value) {
    status.value = "Username and two recordings are required.";
    return;
  }
  status.value = "Submitting catchphrase login…";
  try {
    const res = await fetch('/api/vocal_login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        username: loginUsername.value,
        catchphrase: recordings.value.join('||')
      }),
      credentials: 'include'
    });
    const data = await res.json();
    status.value = data.message || "Login failed.";
    if (data.status === 'success') {
      await fetchUser();
    }
  } catch {
    status.value = "Login failed (network error).";
  }
}

async function fetchUser() {
  try {
    const res = await fetch('/api/user', { credentials: 'include' });
    if (!res.ok) {
      // Only treat as network/server error if fetch itself fails (caught below)
      // If 401/403, treat as "not logged in" (not an error)
      if (res.status === 401 || res.status === 403) {
        loggedIn.value = false;
        status.value = ""; // No error message, just not logged in
        return;
      }
      // For other HTTP errors, show a generic message
      const errText = await res.text();
      console.error("fetchUser: response not OK:", errText);
      status.value = "Failed to fetch user info.";
      loggedIn.value = false;
      return;
    }
    const data = await res.json();
    if (data.status === 'success') {
      user.value = data;
      loggedIn.value = true;
      status.value = "";
    } else {
      loggedIn.value = false;
      status.value = ""; // No error message, just not logged in
    }
  } catch (err) {
    // Only show this if the network request itself fails (server unreachable)
    console.error("fetchUser: network error", err);
    status.value = "Cannot connect to backend. Please check your network or server.";
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
  if (!video.value || !overlay.value) return;
  const canvasEl = document.createElement('canvas');
  canvasEl.width = video.value.videoWidth;
  canvasEl.height = video.value.videoHeight;
  const ctx = canvasEl.getContext('2d');
  ctx.drawImage(video.value, 0, 0, canvasEl.width, canvasEl.height);
  const dataUrl = canvasEl.toDataURL('image/jpeg');
  if (tab.value === 'login') {
    closeWebcamModal();
    faceLoginWithImage(dataUrl);
  } else if (tab.value === 'register') {
    if (registerStep.value === 'id') {
      // --- NEW: Validate ID card immediately after capture ---
      status.value = "Validating ID card...";
      fetch('/api/validate_id', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id_image: dataUrl }),
        credentials: 'include'
      })
      .then(res => res.json())
      .then(data => {
        if (data.status === 'success') {
          idImage.value = dataUrl;
          idError.value = '';
          openWebcamModal('face');
        } else {
          idError.value = data.message || 'ID card not detected. Please try again.';
          status.value = idError.value;
        }
      })
      .catch(() => {
        idError.value = 'Network error during ID validation.';
        status.value = idError.value;
      });
    } else if (registerStep.value === 'face') {
      faceImage.value = dataUrl;
      closeWebcamModal();
      // Only call faceRegisterWithImages() when user clicks "Submit Registration"
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
          const blob = new Blob(audioChunks, { type: 'audio/webm' });
          const url = URL.createObjectURL(blob);
          audioBlobs.value.push(url);
          audioBlob.value = blob;
          stream.getTracks().forEach(track => track.stop());
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

// Helper: Convert webm Blob to wav Blob using AudioContext
async function blobToWav(blob) {
  const arrayBuffer = await blob.arrayBuffer();
  const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  const audioBuffer = await audioCtx.decodeAudioData(arrayBuffer);
  // Encode to WAV (PCM 16-bit LE)
  const wavBuffer = encodeWAV(audioBuffer);
  audioCtx.close();
  return new Blob([wavBuffer], { type: 'audio/wav' });
}

// WAV encoding helper (PCM 16-bit LE, mono)
function encodeWAV(audioBuffer) {
  const numChannels = 1;
  const sampleRate = audioBuffer.sampleRate;
  const samples = audioBuffer.getChannelData(0);
  const buffer = new ArrayBuffer(44 + samples.length * 2);
  const view = new DataView(buffer);

  function writeString(view, offset, string) {
    for (let i = 0; i < string.length; i++) {
      view.setUint8(offset + i, string.charCodeAt(i));
    }
  }

  writeString(view, 0, 'RIFF');
  view.setUint32(4, 36 + samples.length * 2, true);
  writeString(view, 8, 'WAVE');
  writeString(view, 12, 'fmt ');
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);
  view.setUint16(22, numChannels, true);
  view.setUint32(24, sampleRate, true);
  view.setUint32(28, sampleRate * numChannels * 2, true);
  view.setUint16(32, numChannels * 2, true);
  view.setUint16(34, 16, true);
  writeString(view, 36, 'data');
  view.setUint32(40, samples.length * 2, true);

  // PCM samples
  let offset = 44;
  for (let i = 0; i < samples.length; i++, offset += 2) {
    let s = Math.max(-1, Math.min(1, samples[i]));
    view.setInt16(offset, s < 0 ? s * 0x8000 : s * 0x7FFF, true);
  }
  return buffer;
}

async function submitVocal() {
  status.value = 'Submitting catchphrase...';
  if (catchphraseRecordings.value.length !== 2) {
    status.value = 'Please record both catchphrase styles.';
    return;
  }
  localStorage.setItem('catchphrase_backup', catchphraseBackup.value);

  // Convert both blobs to WAV and base64 encode
  const blobs = await Promise.all(
    catchphraseRecordings.value.map(async rec => {
      const wavBlob = await blobToWav(rec.blob);
      return new Promise(resolve => {
        const reader = new FileReader();
        reader.onloadend = () => resolve(reader.result.split(',')[1]);
        reader.readAsDataURL(wavBlob);
      });
    })
  );
  try {
    const res = await fetch('/api/vocal_register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        audio1: blobs[0],
        audio2: blobs[1],
        catchphrase: catchphraseBackup.value,
        username: registerUsername.value
      }),
      credentials: 'include'
    });
    const data = await res.json();
    status.value = data.message || 'Catchphrase registration failed.';
    // Only call fetchUser if registration was successful
    if (data.status === 'success') {
      // Do not call fetchUser() here, as user is not logged in by catchphrase registration
      // Instead, show a success message and let user proceed to login
    }
  } catch {
    status.value = 'Catchphrase registration failed (network error).';
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
        stream.getTracks().forEach(track => stop());
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
        stream.getTracks().forEach(track => stop());
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

// New function to handle ID file change
const idError = ref('');
function onIdFileChange(e) {
  const file = e.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = async (evt) => {
    idImage.value = evt.target.result;
    // Optionally, validate ID card on backend
    const res = await fetch('/api/validate_id', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id_image: idImage.value }),
      credentials: 'include'
    });
    const data = await res.json();
    if (data.status !== 'success') {
      idError.value = data.message || 'ID card not detected. Please try again.';
      idImage.value = null;
    } else {
      idError.value = '';
    }
  };
  reader.readAsDataURL(file);
}

// Webcam face detection overlay
async function startFaceDetection() {
  await ensureModelsLoaded();
  detectionLoop();
}

let detectActive = false; // Add this flag at the top-level

function detectionLoop() {
  if (!video.value || !overlay.value) return;
  const displaySize = { width: video.value.width, height: video.value.height };
  // Defensive: ensure overlay.value and context exist before using
  const ctx = overlay.value.getContext('2d', { willReadFrequently: true });
  if (!ctx) {
    console.warn("Overlay canvas context is null");
    return;
  }
  faceapi.matchDimensions(overlay.value, displaySize);

  const detect = async () => {
    if (!video.value || !overlay.value || video.value.readyState < 2) {
      requestAnimationFrame(detect);
      return;
    }
    // Detect faces with age/gender
    const detections = await faceapi
      .detectAllFaces(video.value, new faceapi.TinyFaceDetectorOptions())
      .withFaceLandmarks(true)
      .withAgeAndGender();
    const resized = faceapi.resizeResults(detections, displaySize);
    ctx.clearRect(0, 0, overlay.value.width, overlay.value.height);
    if (resized && resized.length > 0) {
      faceapi.draw.drawDetections(overlay.value, resized);
      faceapi.draw.drawFaceLandmarks(overlay.value, resized);
      // Age detection: use first face
      const age = resized[0]?.age;
      detectedAge.value = age ? Math.round(age) : null;
      ageDetected.value = !!age;
    } else {
      detectedAge.value = null;
      ageDetected.value = false;
    }

    // --- Live ID document detection (OCR) ---
    // Only run every ~1s to avoid lag
    if (!detect._lastIdCheck || Date.now() - detect._lastIdCheck > 1000) {
      detect._lastIdCheck = Date.now();
      // Grab current frame as image
      const tempCanvas = document.createElement('canvas');
      tempCanvas.width = video.value.videoWidth;
      tempCanvas.height = video.value.videoHeight;
      const tempCtx = tempCanvas.getContext('2d');
      tempCtx.drawImage(video.value, 0, 0, tempCanvas.width, tempCanvas.height);
      const dataUrl = tempCanvas.toDataURL('image/jpeg');
      // Send to backend for OCR/ID check (async, don't block UI)
      fetch('/api/validate_id', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id_image: dataUrl }),
        credentials: 'include'
      })
      .then(res => res.json())
      .then(data => {
        idDetected.value = data.status === 'success';
      })
      .catch(() => {
        idDetected.value = false;
      });
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
      const ctx = overlay.value.getContext('2d');
      if (ctx) ctx.clearRect(0, 0, overlay.value.width, overlay.value.height);
    }
  }
});

// --- Catchphrase logic with random words, two styles, playback, delete ---
const detectedAge = ref(null);
const ageDetected = ref(false);
const idDetected = ref(false);
const catchphraseWords = ref([]);
const catchphraseRecordings = ref([]); // {url, blob, style}
const catchphraseBackup = ref('');
let catchphraseMediaRecorder = null;
let catchphraseChunks = [];
const recordCountdown = ref(3);
let recordTimer = null;

function generateCatchphraseWords() {
  // Example word list; use a larger list in production
  const words = ["apple", "river", "mountain", "cloud", "zebra", "orange", "piano", "rocket", "forest", "moon"];
  let chosen = [];
  while (chosen.length < 3) {
    const w = words[Math.floor(Math.random() * words.length)];
    if (!chosen.includes(w)) chosen.push(w);
  }
  catchphraseWords.value = chosen;
  catchphraseBackup.value = chosen.join(' ');
}

function startCatchphraseRecording(style) {
  if (!catchphraseWords.value.length || recording.value) return;
  navigator.mediaDevices.getUserMedia({ audio: true }).then(stream => {
    catchphraseMediaRecorder = new window.MediaRecorder(stream);
    catchphraseChunks = [];
    catchphraseMediaRecorder.ondataavailable = e => catchphraseChunks.push(e.data);
    catchphraseMediaRecorder.onstop = () => {
      const blob = new Blob(catchphraseChunks, { type: 'audio/webm' });
      const url = URL.createObjectURL(blob);
      catchphraseRecordings.value.push({ url, blob, style });
      stream.getTracks().forEach(track => track.stop());
      recording.value = false;
      recordCountdown.value = 3;
      clearInterval(recordTimer);
    };
    catchphraseMediaRecorder.start();
    recording.value = true;
    recordCountdown.value = 3;
    recordTimer = setInterval(() => {
      recordCountdown.value -= 1;
      if (recordCountdown.value <= 0) {
        if (catchphraseMediaRecorder && recording.value) {
          catchphraseMediaRecorder.stop();
        }
        clearInterval(recordTimer);
      }
    }, 1000);
  });
}

function deleteCatchphraseRecording(idx) {
  catchphraseRecordings.value.splice(idx, 1);
}

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
.id-btn {
  background: #b3e5fc;
  color: #111;
  border: 2px solid #0288d1;
}
.face-btn {
  background: #ffe082;
  color: #111;
  border: 2px solid #fbc02d;
}
.catchphrase-recording-indicator {
  margin-top: 10px;
  font-weight: bold;
  color: #e53935;
  display: flex;
  align-items: center;
  gap: 8px;
}
.recording-dot {
  display: inline-block;
  width: 14px;
  height: 14px;
  background: #e53935;
  border-radius: 50%;
  margin-right: 6px;
  animation: blink 1s infinite;
}
@keyframes blink {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.3; }
}
</style>
