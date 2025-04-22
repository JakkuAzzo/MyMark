<template>
  <div style="padding: 20px;">
    <h2>Upload</h2>
    <p style="color: red; font-weight: bold;">
      Please ensure you only upload pictures of yourself.
    </p>
    <div style="margin-bottom: 20px;">
      <input type="file" accept="image/*" @change="handleFileChange" />
      <button @click="handleUpload" style="margin-left: 10px;">Upload Image</button>
    </div>
    <p>{{ uploadStatus }}</p>
    <div v-if="downloadLink">
      <p>Download your watermarked image:</p>
      <a :href="downloadLink" target="_blank" rel="noreferrer" download>Download</a>
    </div>
    <div style="display: flex; gap: 20px; margin-top: 20px;">
      <div style="flex: 1; border: 1px solid #ddd; padding: 10px; border-radius: 5px;">
        <h3>Generate Watermark</h3>
        <div style="border: 2px dashed #bbb; padding: 20px; text-align: center; margin-bottom: 10px;">
          <p>Drop image here to fingerprint</p>
          <input type="file" accept="image/*" style="width: 100%;" />
        </div>
        <div style="margin-bottom: 10px;">
          <button>Check for Watermark</button>
        </div>
        <div style="margin-bottom: 10px;">
          <p>Download watermarked image:</p>
          <a href="#" download>Download</a>
        </div>
        <div>
          <p>Compare two images for watermark and likeness:</p>
          <div style="display: flex; gap: 5%;">
            <input type="file" accept="image/*" style="width: 48%;" />
            <input type="file" accept="image/*" style="width: 48%;" />
          </div>
          <div style="margin-top: 10px;">
            <p>Similarity: [statistics]</p>
          </div>
        </div>
      </div>
      <div style="flex: 1; border: 1px solid #ddd; padding: 10px; border-radius: 5px;">
        <h3>Improve Likeness</h3>
        <div style="border: 2px dashed #bbb; padding: 20px; text-align: center;">
          <p>Drop additional images of yourself here</p>
          <input type="file" accept="image/*" multiple style="width: 100%;" />
        </div>
        <div style="margin-top: 10px;">
          <p>[Additional features to enhance likeness recognition]</p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue';

const selectedFile = ref(null);
const uploadStatus = ref('');
const downloadLink = ref(null);

function handleFileChange(e) {
  if (e.target.files && e.target.files.length > 0) {
    selectedFile.value = e.target.files[0];
  }
}

async function handleUpload() {
  if (!selectedFile.value) {
    uploadStatus.value = 'Please select a file first.';
    return;
  }
  uploadStatus.value = 'Uploading image...';
  const formData = new FormData();
  formData.append('image', selectedFile.value);
  formData.append('owner', 'user@example.com'); // Replace with actual owner/email if needed
  try {
    const response = await fetch('http://localhost:5000/api/upload', {
      method: 'POST',
      body: formData
    });
    if (response.ok) {
      const blob = await response.blob();
      downloadLink.value = URL.createObjectURL(blob);
      uploadStatus.value = 'Image uploaded and fingerprinted successfully!';
    } else {
      uploadStatus.value = 'Image upload failed.';
    }
  } catch (err) {
    uploadStatus.value = 'Error uploading image.';
  }
}
</script>

<style scoped>
/* Add any scoped styles here if needed */
</style>
