<template>
  <div class="cubist-card">
    <h2 class="cubist-title">Matches</h2>
    <div v-if="error" class="cubist-status">{{ error }}</div>
    <div v-else>
      <ul>
        <li v-for="(match, idx) in matches" :key="idx">{{ match[0] }}: {{ match[1] }}</li>
      </ul>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';

const matches = ref([]);
const error = ref('');

async function fetchMatches() {
  try {
    const res = await fetch('/api/matches', { credentials: 'include' });
    if (!res.ok) {
      error.value = 'You must be logged in to view matches.';
      return;
    }
    const data = await res.json();
    matches.value = data.matches || [];
  } catch {
    error.value = 'Failed to fetch matches.';
  }
}

onMounted(fetchMatches);
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
