<template>
  <div class="auth-form cubist-form">
    <input v-model="auth.registerUsername" placeholder="Username" class="cubist-input" />
    <div v-if="!auth.idImage">
      <label><b>Upload ID document or take a picture of it below:</b></label>
      <input type="file" accept="image/*" @change="onIdFileChange" class="cubist-input" />
      <button @click="auth.openWebcamModal('id')" class="cubist-btn id-btn">Capture ID Document</button>
      <div v-if="auth.idError" style="color:red;">{{ auth.idError }}</div>
    </div>
    <div v-else-if="!auth.faceImage">
      <label><b>Take a picture of your face:</b></label>
      <button @click="auth.openWebcamModal('face')" class="cubist-btn face-btn">Capture Face Image</button>
    </div>
    <div v-else>
      <p v-if="auth.faceMatch === null">Comparing images…</p>
      <p v-else-if="!auth.faceMatch" style="color:red;">Face images do not match. Please retry.</p>
      <p v-else style="color:green;">Face images match.</p>
      <div v-if="auth.faceImage && auth.idImage && auth.faceMatch === true" style="margin-top:18px;">
        <label><b>Optional: Add a catchphrase for extra account security</b></label>
        <button @click="auth.openVocalRegister()" class="cubist-btn vocal-btn">Catchphrase Register (Optional)</button>
      </div>
    </div>
    <button v-if="auth.faceImage && auth.idImage && auth.faceMatch === true" @click="auth.submitFaceRegister()" class="cubist-btn">
      Submit Registration
    </button>
    <p class="cubist-status" :style="{color: auth.statusColor}">{{ auth.status }}</p>
  </div>
</template>
<script setup>
import { useAuthStore } from '../stores/auth';
const auth = useAuthStore();
function onIdFileChange(e) {
  // Implement file upload and validation logic using the store
  // Example: auth.handleIdFileChange(e)
}
</script>
<style scoped>
/* ...register-specific styles... */
</style>
