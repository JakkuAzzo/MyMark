<template>
  <div class="auth-form cubist-form">
    <input v-model="auth.registerUsername" placeholder="Username" class="cubist-input" />
    <div v-if="auth.registerStep === 'id'">
      <label><b>Upload ID document or take a picture of it below:</b></label>
      <input type="file" accept="image/*" @change="onIdFileChange" class="cubist-input" />
      <button @click="auth.openWebcamModal('id')" class="cubist-btn id-btn">Capture ID Document</button>
      <div v-if="auth.idError" class="cubist-status" style="color:red;">{{ auth.idError }}</div>
    </div>
    <div v-else-if="auth.registerStep === 'face'">
      <label><b>Take a picture of your face:</b></label>
      <button @click="auth.openWebcamModal('face')" class="cubist-btn face-btn">Capture Face Image</button>
      <div v-if="auth.faceImage">
        <img :src="auth.faceImage" alt="Face Preview" style="max-width:120px; margin-top:8px; border-radius:8px;" />
      </div>
    </div>
    <div v-else-if="auth.registerStep === 'catchphrase'">
      <label><b>Optional: Add a catchphrase for extra account security</b></label>
      <button @click="auth.openVocalRegister()" class="cubist-btn vocal-btn">Catchphrase Register (Optional)</button>
      <button @click="auth.setRegisterStep('submit')" class="cubist-btn">Skip</button>
    </div>
    <div v-else-if="auth.registerStep === 'submit'">
      <button @click="auth.submitFaceRegister()" class="cubist-btn">Submit Registration</button>
    </div>
    <p class="cubist-status" :style="{color: auth.statusColor}">{{ auth.status }}</p>
  </div>
</template>
<script setup>
import { useAuthStore } from '../stores/auth';
const auth = useAuthStore();

async function onIdFileChange(e) {
  const file = e.target.files[0];
  if (!file) return;
  const reader = new FileReader();
  reader.onload = async (evt) => {
    auth.idImage = evt.target.result;
    // Immediately verify ID document
    auth.idError = '';
    auth.status = 'Verifying ID document...';
    try {
      const res = await fetch('/api/validate_id', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id_image: auth.idImage })
      });
      const data = await res.json();
      if (data.status === 'success') {
        auth.status = 'ID document verified!';
        auth.statusColor = '#43a047';
        auth.idError = '';
        auth.setRegisterStep('face');
      } else {
        auth.status = '';
        auth.idError = data.message || 'ID document not valid.';
        auth.idImage = null;
      }
    } catch {
      auth.status = '';
      auth.idError = 'Network error during ID verification.';
      auth.idImage = null;
    }
  };
  reader.readAsDataURL(file);
}

function openFaceWebcamModal() {
  auth.openWebcamModal('face');
}
</script>
<style scoped>
.cubist-form {
  /* example property added to avoid an empty ruleset */
  margin: 0;
}
.cubist-btn.id-btn {
  background: #b3e5fc;
  color: #111;
  border: 2px solid #0288d1;
}
.cubist-btn.face-btn {
  background: #ffe082;
  color: #111;
  border: 2px solid #fbc02d;
}
.cubist-btn.vocal-btn {
  background: #f8bbd0;
  color: #111;
  border: 2px solid #c2185b;
}
</style>
