<template>
  <div class="auth-root">
    <!-- Info Modal -->
    <div v-if="auth.activePage==='info'" class="cubist-modal-bg">
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
        <button class="cubist-btn" @click="auth.closeInfo">Close</button>
      </div>
    </div>

    <!-- Auth Cards (Login/Register) -->
    <div v-if="!auth.loggedIn && auth.activePage==='auth'" class="auth-container cubist-card">
      <img src="/MyMark.svg" alt="MyMark Logo" class="logo" />
      <h2 class="cubist-title">Welcome to My Mark</h2>
      <div class="auth-tabs cubist-tabs">
        <button :class="['cubist-btn', auth.tab==='login' ? 'active' : 'inactive']" @click="auth.tab='login'">Login</button>
        <button :class="['cubist-btn', auth.tab==='register' ? 'active' : 'inactive']" @click="auth.tab='register'">Register</button>
      </div>
      <transition name="fade">
        <div>
          <AuthLogin v-if="auth.tab==='login'"></AuthLogin>
          <AuthRegister v-else></AuthRegister>
        </div>
      </transition>
      <p class="status cubist-status">{{ auth.status }}</p>
    </div>

    <!-- Webcam and Catchphrase Modals -->
    <div v-if="auth.showWebcamPrompt" class="webcam-prompt cubist-warning">
      <p>Please allow webcam and/or microphone access for face/catchphrase authentication.</p>
    </div>
    <AuthWebcamModal v-if="auth.showWebcamModal"
      :show="auth.showWebcamModal"
      :registerStep="auth.registerStep"
      @close="auth.closeWebcamModal"
      @capture="auth.captureImage"
      :ageDetected="auth.ageDetected"
      :detectedAge="auth.detectedAge"
      :idDetected="auth.idDetected"
    />
    <AuthCatchphraseModal v-if="auth.showVocalModal"
      :show="auth.showVocalModal"
      :catchphraseWords="auth.catchphraseWords"
      :catchphraseRecordings="auth.catchphraseRecordings"
      :recording="auth.recording"
      :recordCountdown="auth.recordCountdown"
      :status="auth.status"
      :statusColor="auth.statusColor"
      @generate-catchphrase="auth.generateCatchphraseWords"
      @start-recording="auth.startCatchphraseRecording"
      @delete-recording="auth.deleteCatchphraseRecording"
      @submit="auth.submitVocal"
      @close="auth.closeVocalModal"
    />

    <!-- Dashboard for logged-in users -->
    <div v-else-if="auth.loggedIn">
      <div class="dashboard cubist-card">
        <img src="/MyMark.svg" alt="MyMark Logo" class="logo dashboard-logo" />
        <h2 class="cubist-title">Dashboard</h2>
        <div class="stats cubist-stats">
          <div><strong>Username:</strong> {{ auth.user.username }}</div>
          <div><strong>Images:</strong> {{ auth.user.images }}</div>
          <div><strong>Matches:</strong> {{ auth.user.matches }}</div>
          <div><strong>Last Scan:</strong> {{ auth.user.last_scan }}</div>
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
        <button @click="auth.logout" class="cubist-btn logout-btn">Logout</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { useAuthStore } from '../stores/auth';
import AuthLogin from './AuthLogin.vue';
import AuthRegister from './AuthRegister.vue';
import AuthWebcamModal from './AuthWebcamModal.vue';
import AuthCatchphraseModal from './AuthCatchphraseModal.vue';
const auth = useAuthStore();
</script>

<style scoped>
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
  border-radius: 0;
  border: none;
  box-shadow: none;
}
.cubist-tabs .cubist-btn {
  flex: 1;
  border-radius: 0;
  margin: 0;
  border-right: none;
  border-top: 2px solid #111;
  border-bottom: 2px solid #111;
  border-left: 2px solid #111;
  background: #e0e0e0;
  color: #111;
  font-weight: bold;
  font-size: 1.1em;
  box-shadow: none;
  transition: background 0.2s, color 0.2s;
}
.cubist-tabs .cubist-btn:last-child {
  border-right: 2px solid #111;
}
.cubist-btn.active {
  background: #111;
  color: #fff;
  z-index: 1;
}
.cubist-btn.inactive {
  background: #e0e0e0;
  color: #111;
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
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.5s;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
.auth-root {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  align-items: stretch;
  justify-content: flex-start;
}
@media (max-width: 600px) {
  .cubist-card, .cubist-modal {
    max-width: 98vw;
    min-width: 0;
    padding: 18px 6px 18px 6px;
    margin: 12px auto;
  }
  .cubist-title {
    font-size: 1.3em;
  }
  .logo, .dashboard-logo, .info-logo {
    width: 44px !important;
    height: 44px !important;
  }
  .cubist-form {
    gap: 10px;
  }
}
@media (min-width: 601px) and (max-width: 900px) {
  .cubist-card, .cubist-modal {
    max-width: 90vw;
    min-width: 0;
    padding: 28px 12px 28px 12px;
    margin: 24px auto;
  }
}
</style>
