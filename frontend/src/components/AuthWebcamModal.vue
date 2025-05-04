<template>
  <div v-if="auth.showWebcamModal" class="modal cubist-modal-bg" style="position:relative;">
    <div class="modal-content cubist-modal" style="position:relative;">
      <div style="position: relative; display: inline-block;">
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
      <button @click="auth.captureImage()" class="cubist-btn">Capture</button>
      <button @click="auth.closeWebcamModal()" class="cubist-btn">Cancel</button>
    </div>
  </div>
</template>
<script setup>
import { useAuthStore } from '../stores/auth';
const auth = useAuthStore();
// Webcam logic can be managed in the store or here as needed
</script>
<style scoped>
/* ...webcam modal-specific styles... */
</style>
