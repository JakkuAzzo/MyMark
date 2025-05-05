<template>
  <div v-if="auth.showWebcamModal" class="cubist-modal-bg webcam-modal-overlay">
    <div class="cubist-modal webcam-modal-content">
      <div v-if="webcamError || modelError" class="cubist-status" style="color:red;">
        {{ webcamError || modelError }}
        <button class="cubist-btn" @click="retryWebcam">Retry</button>
      </div>
      <div v-else style="position: relative; display: inline-block;">
        <video ref="video" autoplay playsinline width="320" height="240" style="background:#222; display:block; z-index:1;"></video>
        <canvas ref="overlay" width="320" height="240"
          style="position:absolute; top:0; left:0; pointer-events:none; z-index:2;"></canvas>
        <div style="position:absolute; top:8px; right:8px; z-index:10; background:rgba(255,255,255,0.95); border-radius:8px; padding:8px 14px; border:2px solid #111; min-width:120px; text-align:left; font-size:1em;">
          <div>
            <span :style="{color: auth.ageDetected ? '#0a0' : '#a00', fontWeight:'bold'}">●</span>
            Age:
            <span :style="{color: auth.ageDetected ? '#0a0' : '#a00', fontWeight:'bold'}">{{ auth.detectedAge !== null ? auth.detectedAge : '--' }}</span>
          </div>
          <div>
            <span :style="{color: auth.idDetected ? '#0a0' : '#a00', fontWeight:'bold'}">●</span>
            ID:
            <span :style="{color: auth.idDetected ? '#0a0' : '#a00', fontWeight:'bold'}">{{ auth.idDetected ? 'Detected' : 'Not Detected' }}</span>
          </div>
        </div>
      </div>
      <div v-if="auth.registerStep === 'id'">
        <p>Show your identification document to the camera, then click Capture.</p>
      </div>
      <div v-else-if="auth.registerStep === 'face'">
        <p>Now show your face to the camera, then click Capture.</p>
      </div>
      <div v-else>
        <p>Show your face to the camera, then click Capture.</p>
      </div>
      <button @click="captureImage" class="cubist-btn">Capture</button>
      <button @click="closeModal" class="cubist-btn">Cancel</button>
    </div>
  </div>
</template>
<script setup>
import { ref, onMounted, onBeforeUnmount, watch } from 'vue';
import { useAuthStore } from '../stores/auth';
import * as faceapi from 'face-api.js';

const auth = useAuthStore();
const video = ref(null);
const overlay = ref(null);
const webcamError = ref('');
const modelError = ref('');
const autoCaptured = ref(false);
let stream = null;
let detectionInterval = null;
let faceapiLoaded = false;
let lastIdCheck = 0;

async function loadFaceApiModels() {
  try {
    if (!faceapi.nets.tinyFaceDetector.params)
      await faceapi.nets.tinyFaceDetector.load('/models/');
    if (!faceapi.nets.faceLandmark68TinyNet.params)
      await faceapi.nets.faceLandmark68TinyNet.load('/models/');
    if (!faceapi.nets.ageGenderNet.params)
      await faceapi.nets.ageGenderNet.load('/models/');
    faceapiLoaded = true;
    modelError.value = '';
  } catch (e) {
    modelError.value = 'Face detection models failed to load. Please ensure /models/ is accessible and contains all required files.';
  }
}

function syncCanvasToVideo() {
  if (!video.value || !overlay.value) return;
  const v = video.value;
  const c = overlay.value;
  // Use actual video size
  c.width = v.videoWidth;
  c.height = v.videoHeight;
  c.style.width = v.clientWidth + 'px';
  c.style.height = v.clientHeight + 'px';
}

function drawLandmarks(canvas, dims, landmarks) {
  if (!canvas || !landmarks) return;
  const ctx = canvas.getContext('2d');
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.save();
  ctx.fillStyle = '#ff1744';
  // face-api.js positions are already in video coordinates
  for (const pt of landmarks.positions) {
    ctx.beginPath();
    ctx.arc(pt.x, pt.y, 2.5, 0, 2 * Math.PI);
    ctx.fill();
  }
  ctx.restore();
}

async function startDetectionLoop() {
  if (!faceapiLoaded) return;
  if (!video.value) return;
  detectionInterval = setInterval(async () => {
    if (!video.value || video.value.readyState !== 4) return;
    syncCanvasToVideo();
    const result = await faceapi.detectSingleFace(video.value, new faceapi.TinyFaceDetectorOptions())
      .withFaceLandmarks(true)
      .withAgeAndGender();
    if (result) {
      auth.ageDetected = true;
      auth.detectedAge = Math.round(result.age);
      drawLandmarks(overlay.value, result.detection.box, result.landmarks);
      if (auth.registerStep === 'id') {
        const now = Date.now();
        if (!autoCaptured.value && now - lastIdCheck > 2000) {
          lastIdCheck = now;
          // Validate ID document before auto-capturing
          const tempCanvas = document.createElement('canvas');
          tempCanvas.width = video.value.videoWidth || 320;
          tempCanvas.height = video.value.videoHeight || 240;
          tempCanvas.getContext('2d').drawImage(video.value, 0, 0, tempCanvas.width, tempCanvas.height);
          const dataUrl = tempCanvas.toDataURL('image/jpeg', 0.95);
          fetch('/api/validate_id', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ id_image: dataUrl })
          })
            .then(res => res.json())
            .then(data => {
              if (data.status === 'success') {
                auth.idDetected = true;
                autoCaptured.value = true;
                auth.status = 'Valid ID Card captured!';
                auth.statusColor = '#43a047';
                auth.idImage = dataUrl;
                setTimeout(() => {
                  closeModal();
                  auth.setRegisterStep('face');
                }, 400);
              } else {
                auth.idDetected = false;
                autoCaptured.value = false;
                auth.status = 'Please verify your ID document before capturing your face.';
                auth.statusColor = '#e53935';
              }
            })
            .catch(() => {
              auth.idDetected = false;
              autoCaptured.value = false;
              auth.status = 'Please verify your ID document before capturing your face.';
              auth.statusColor = '#e53935';
            });
        }
      } else if (auth.registerStep === 'face') {
        // Auto-capture face if detected and not already captured
        if (!autoCaptured.value) {
          autoCaptured.value = true;
          setTimeout(() => {
            captureImage();
            auth.setRegisterStep('catchphrase');
          }, 400);
        }
      }
    } else {
      auth.ageDetected = false;
      auth.detectedAge = null;
      auth.idDetected = false;
      if (overlay.value) overlay.value.getContext('2d').clearRect(0, 0, overlay.value.width, overlay.value.height);
      autoCaptured.value = false;
    }
  }, 200);
}

function stopDetectionLoop() {
  if (detectionInterval) {
    clearInterval(detectionInterval);
    detectionInterval = null;
  }
  if (overlay.value) {
    overlay.value.getContext('2d').clearRect(0, 0, overlay.value.width, overlay.value.height);
  }
}

function startWebcam() {
  webcamError.value = '';
  autoCaptured.value = false;
  navigator.mediaDevices.getUserMedia({ video: true })
    .then(s => {
      stream = s;
      if (video.value) {
        video.value.srcObject = stream;
      }
      loadFaceApiModels().then(startDetectionLoop);
    })
    .catch(err => {
      webcamError.value = 'Webcam access denied or unavailable.';
    });
}

function stopWebcam() {
  if (stream) {
    stream.getTracks().forEach(track => track.stop());
    stream = null;
  }
  if (video.value) {
    video.value.srcObject = null;
  }
  stopDetectionLoop();
}

function captureImage() {
  if (!video.value) return;
  const canvas = document.createElement('canvas');
  canvas.width = video.value.videoWidth || 320;
  canvas.height = video.value.videoHeight || 240;
  const ctx = canvas.getContext('2d');
  ctx.drawImage(video.value, 0, 0, canvas.width, canvas.height);
  const dataUrl = canvas.toDataURL('image/jpeg', 0.95);
  if (auth.registerStep === 'id') {
    auth.idImage = dataUrl;
    auth.status = 'Valid ID Card captured!';
    auth.statusColor = '#43a047';
    // Optionally, close modal or advance step here
    closeModal();
  } else if (auth.registerStep === 'face') {
    auth.faceImage = dataUrl;
    closeModal();
  }
}

function closeModal() {
  stopWebcam();
  auth.closeWebcamModal();
}

function retryWebcam() {
  webcamError.value = '';
  modelError.value = '';
  stopWebcam();
  startWebcam();
}

onMounted(() => {
  if (auth.showWebcamModal) {
    startWebcam();
  }
});

onBeforeUnmount(() => {
  stopWebcam();
});

watch(() => auth.showWebcamModal, (val) => {
  if (val) {
    startWebcam();
  } else {
    stopWebcam();
  }
});
</script>
<style scoped>
.cubist-modal-bg.webcam-modal-overlay {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(30,30,30,0.25);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
}
.cubist-modal.webcam-modal-content {
  background: #fff;
  border: 4px solid #111;
  border-radius: 18px 0 18px 0;
  width: 400px;
  max-width: 98vw;
  padding: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  box-shadow: 8px 8px 0 #bbb, 0 0 0 8px #fff inset;
}
video, canvas {
  width: 100% !important;
  height: auto !important;
  max-width: 400px;
  border-radius: 12px;
  background: #222;
  display: block;
}
.cubist-modal-content > *:not(:last-child) {
  margin-bottom: 12px;
}
.cubist-btn {
  margin: 8px 0 0 0;
  width: 90%;
  max-width: 320px;
}
@media (max-width: 600px) {
  .cubist-modal.webcam-modal-content {
    width: 98vw;
    max-width: 98vw;
    padding: 0;
  }
  video, canvas {
    max-width: 98vw;
  }
}
</style>