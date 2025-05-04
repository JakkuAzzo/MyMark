<template>
  <div class="cubist-card">
    <h2 class="cubist-title">Upload Image</h2>
    <div v-if="error" class="cubist-status">{{ error }}</div>
    <div v-else>
      <form @submit.prevent="handleUpload" class="cubist-form">
        <input type="file" @change="onFileChange" class="cubist-input" />
        <input v-model="owner" placeholder="Owner" class="cubist-input" />
        <button type="submit" class="cubist-btn">Upload & Watermark</button>
      </form>
      <div v-if="status" class="cubist-status">{{ status }}</div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';

const file = ref(null);
const owner = ref('');
const status = ref('');
const error = ref('');

function onFileChange(e) {
  file.value = e.target.files[0];
}

async function handleUpload() {
  if (!file.value || !owner.value) {
    status.value = 'Please select a file and enter owner.';
    return;
  }
  const formData = new FormData();
  formData.append('image', file.value);
  formData.append('owner', owner.value);
  try {
    const res = await fetch('/api/upload', {
      method: 'POST',
      body: formData,
      credentials: 'include'
    });
    if (!res.ok) {
      status.value = 'Upload failed (auth required).';
      return;
    }
    status.value = 'Upload successful!';
  } catch {
    status.value = 'Upload failed (network error).';
  }
}

onMounted(async () => {
  try {
    const res = await fetch('/api/user', { credentials: 'include' });
    if (!res.ok) {
      error.value = 'You must be logged in to view upload.';
      return;
    }
    const data = await res.json();
    if (data.status !== 'success') {
      error.value = 'You must be logged in to view upload.';
    }
  } catch {
    error.value = 'You must be logged in to view upload.';
  }
});
</script>

<style scoped>
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
  color: #111;
}
.cubist-title {
  font-family: 'Montserrat', 'Arial', sans-serif;
  font-weight: 900;
  font-size: 2em;
  color: #111;
  margin-bottom: 18px;
  letter-spacing: 1px;
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
.cubist-status {
  color: #e53935;
  font-weight: bold;
  min-height: 24px;
}
@media (max-width: 600px) {
  .cubist-card {
    max-width: 98vw;
    min-width: 0;
    padding: 18px 6px 18px 6px;
    margin: 12px auto;
  }
  .cubist-title {
    font-size: 1.3em;
  }
  .cubist-form {
    gap: 10px;
  }
}
@media (min-width: 601px) and (max-width: 900px) {
  .cubist-card {
    max-width: 90vw;
    min-width: 0;
    padding: 28px 12px 28px 12px;
    margin: 24px auto;
  }
}
</style>
