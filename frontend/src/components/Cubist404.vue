<template>
  <div class="cubist-404-bg">
    <div class="cubist-404-cube">
      <div class="cube-face cube-front">4</div>
      <div class="cube-face cube-back">0</div>
      <div class="cube-face cube-top">4</div>
      <div class="cube-face cube-bottom">?</div>
      <div class="cube-face cube-left">🟦</div>
      <div class="cube-face cube-right">🟨</div>
    </div>
    <div class="cubist-404-text">
      <h1>404: Lost in the Cubist Multiverse</h1>
      <p>
        Oops! This page is as invisible as our watermarks.<br>
        <span style="font-size:1.5em;">🧊</span> <b>Cube not found!</b> <span style="font-size:1.5em;">🧊</span><br>
        <em>Maybe your image took a wrong turn on the blockchain?</em>
      </p>
      <button class="cubist-btn" @click="$emit('goHome')">Return to Dashboard</button>
    </div>
  </div>
</template>

<script setup>
// No script needed except for goHome event
</script>

<style scoped>
.cubist-404-bg {
  min-height: 100vh;
  background: linear-gradient(135deg, #e0e0e0 0%, #b3e5fc 100%);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  animation: bgmove 8s linear infinite alternate;
}
@keyframes bgmove {
  0% { background-position: 0 0; }
  100% { background-position: 100% 100%; }
}
.cubist-404-cube {
  width: 120px;
  height: 120px;
  margin-bottom: 32px;
  perspective: 600px;
  position: relative;
  animation: cube-spin 3s infinite linear;
}
@keyframes cube-spin {
  0% { transform: rotateX(0deg) rotateY(0deg);}
  100% { transform: rotateX(360deg) rotateY(360deg);}
}
.cube-face {
  position: absolute;
  width: 120px;
  height: 120px;
  background: #fff;
  border: 4px solid #111;
  font-size: 4em;
  font-family: 'Montserrat', 'Arial', sans-serif;
  font-weight: bold;
  color: #0288d1;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 4px 4px 0 #bbb;
  opacity: 0.95;
}
.cube-front  { transform: rotateY(0deg) translateZ(60px);}
.cube-back   { transform: rotateY(180deg) translateZ(60px);}
.cube-top    { transform: rotateX(90deg) translateZ(60px);}
.cube-bottom { transform: rotateX(-90deg) translateZ(60px);}
.cube-left   { transform: rotateY(-90deg) translateZ(60px);}
.cube-right  { transform: rotateY(90deg) translateZ(60px);}
.cubist-404-text {
  text-align: center;
  margin-top: 24px;
}
.cubist-404-text h1 {
  font-family: 'Montserrat', 'Arial', sans-serif;
  font-size: 2.2em;
  color: #111;
  margin-bottom: 12px;
}
.cubist-404-text p {
  font-size: 1.2em;
  color: #0288d1;
  margin-bottom: 24px;
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
.cubist-btn:hover {
  background: #0288d1;
  color: #fff;
}
</style>
