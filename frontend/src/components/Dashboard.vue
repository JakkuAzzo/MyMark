<template>
  <div class="dashboard-wrapper">
    <div class="cubist-card dashboard-card">
      <h2 class="cubist-title">Dashboard</h2>
      <p class="dashboard-welcome">Welcome to the MyMask Dashboard. Use the navigation to access features.</p>
    </div>
    <div class="dashboard-cards-row">
      <div class="cubist-card dashboard-subcard dashboard-hover"
           @click="showInfo = true"
           tabindex="0">
        <h3 class="cubist-subtitle">Info</h3>
        <p>
          Learn about MyMask's privacy-first watermarking, copyright protection, and blockchain registration.
        </p>
      </div>
      <div class="cubist-card dashboard-subcard dashboard-hover"
           @click="goToAuth"
           tabindex="0">
        <h3 class="cubist-subtitle">Login/Register</h3>
        <p>
          Access your account or create a new one to start protecting your images and identity.
        </p>
      </div>
      <div class="cubist-card dashboard-subcard dashboard-hover"
           @click="showResearch = true"
           tabindex="0">
        <h3 class="cubist-subtitle">Further Research</h3>
        <p>
          Explore advanced topics: invisible watermarking, decentralized identity, and digital rights management.
        </p>
      </div>
    </div>
    <!-- Info Popup -->
    <div v-if="showInfo" class="cubist-modal-bg dashboard-blur">
      <div class="cubist-modal dashboard-modal-scroll">
        <button class="cubist-btn dashboard-modal-close" @click="showInfo = false">Close</button>
        <h2 class="cubist-title">About MyMask</h2>
        <div class="dashboard-modal-content">
          <p>
            <b>How the app works:</b><br>
            MyMask lets you invisibly watermark your images with a unique, owner-specific fingerprint. When you upload an image, a robust watermark is embedded and a perceptual hash is computed. Both are registered on a decentralized blockchain, providing tamper-proof proof of ownership.<br><br>
            <b>Why it's necessary:</b><br>
            Billions of images are shared online daily, and most are used without permission. MyMask empowers creators to prove ownership, detect unauthorized use, and protect their digital identity—without relying on a central authority.<br><br>
            <b>How your information is kept secure and private:</b><br>
            - Only hashes and watermark codes are stored on-chain, never your original images.<br>
            - All communication is encrypted.<br>
            - You control your data; nothing is shared without your action.<br>
            - No personal data is exposed on the blockchain—only random-looking fingerprints.<br>
            - The app is open source for transparency.<br>
          </p>
        </div>
      </div>
    </div>
    <!-- Further Research Popup -->
    <div v-if="showResearch" class="cubist-modal-bg dashboard-blur">
      <div class="cubist-modal dashboard-modal-scroll">
        <button class="cubist-btn dashboard-modal-close" @click="showResearch = false">Close</button>
        <h2 class="cubist-title">Further Research</h2>
        <div class="dashboard-modal-content">
          <ul class="dashboard-research-list">
            <li>Xiao and He (2024): BB-RICP – Blockchain-based image copyright protection with robust watermarking (Hyperledger Fabric).</li>
            <li>Ren et al. (2021): Blockchain + zero-watermarking for lossless, tamper-proof copyright protection (Ethereum).</li>
            <li>Kim et al. (2021): Photo copyright identification using robust region-of-interest hashing and verification.</li>
            <li>OpenAI CLIP (2021): Contrastive Language-Image Pretraining for semantic image similarity.</li>
            <li>FaceNet (Schroff et al., 2015): Deep face recognition with 128-D embeddings.</li>
            <li>Microsoft PhotoDNA: Industry-standard perceptual hashing for image identification.</li>
            <li>Houston et al. (2023): DETECT – Copyright similarity detection using multimodal models.</li>
            <li>Xie & Tang (2024): Cross-chain blockchain for scalable copyright management.</li>
            <li>IPFS: Decentralized storage for off-chain media.</li>
            <li>Additional references and details in the project proposal.</li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, defineEmits } from 'vue';

const showInfo = ref(false);
const showResearch = ref(false);
const emit = defineEmits(['updatePage']);

function goToAuth() {
  emit("updatePage", "auth");
}
</script>

<style scoped>
.dashboard-wrapper {
  /* Use the logo as the background */
  background: url('/MyMark.svg') no-repeat center center;
  background-size: cover;
  padding: 40px;
}
.cubist-card.dashboard-card {
  /* Semi-transparent background overlay to enhance legibility */
  background: rgba(255, 255, 255, 0.8);
  border: 4px solid #111;
  border-radius: 18px 0 18px 0;
  box-shadow: 8px 8px 0 #bbb, 0 0 0 8px rgba(255,255,255,0.8) inset;
  padding: 40px 32px;
  margin: 40px auto;
  max-width: 520px;
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
  text-align: center;
}
.dashboard-welcome {
  font-size: 1.25em;
  text-align: center;
  margin: 0 auto;
}
.dashboard-cards-row {
  display: flex;
  justify-content: center;
  gap: 24px;
  flex-wrap: wrap;
  margin-bottom: 32px;
}
.cubist-card.dashboard-subcard {
  flex: 1 1 220px;
  max-width: 320px;
  min-width: 220px;
  padding: 28px 18px 18px 18px;
  margin: 0 0 24px 0;
  text-align: center;
  border-radius: 18px 0 18px 0;
  border: 4px solid #222;
  background: linear-gradient(135deg, #f5f5f5 70%, #e0e0e0 100%);
  box-shadow: 6px 6px 0 #bbb, 0 0 0 6px #fff inset;
  transition: transform 0.18s cubic-bezier(.4,2,.6,1), box-shadow 0.18s;
  cursor: pointer;
  position: relative;
  outline: none;
}
.dashboard-hover:hover, .dashboard-hover:focus {
  transform: scale(1.045);
  box-shadow: 10px 10px 0 #222, 0 0 0 8px #fff inset;
  z-index: 2;
}
.cubist-subtitle {
  font-family: 'Montserrat', 'Arial', sans-serif;
  font-weight: 700;
  font-size: 1.25em;
  color: #222;
  margin-bottom: 12px;
  text-align: center;
  letter-spacing: 0.5px;
}
.cubist-modal-bg.dashboard-blur {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(30,30,30,0.25);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}
.cubist-modal.dashboard-modal-scroll {
  background: #fff;
  border: 4px solid #111;
  border-radius: 18px 0 18px 0;
  box-shadow: 8px 8px 0 #bbb, 0 0 0 8px #fff inset;
  padding: 32px 32px 24px 32px;
  max-width: 520px;
  min-width: 320px;
  max-height: 80vh;
  overflow-y: auto;
  text-align: left;
  position: relative;
}
.dashboard-modal-close {
  position: absolute;
  top: 18px;
  right: 18px;
  z-index: 10;
}
.dashboard-modal-content {
  margin-top: 18px;
  font-size: 1.08em;
  color: #222;
  line-height: 1.6;
}
.dashboard-research-list {
  margin: 0 0 0 1em;
  padding: 0;
  font-size: 1em;
}
.dashboard-research-list li {
  margin-bottom: 10px;
  list-style: disc inside;
}
</style>
