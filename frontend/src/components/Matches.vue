<template>
  <div style="padding: 20px;">
    <h2>Matches</h2>
    <button @click="handleScan">Scan Now</button>
    <p style="font-weight: bold;">{{ scanStatus }}</p>
    <div v-if="matches.length">
      <h3>Matches found:</h3>
      <ul>
        <li v-for="(match, idx) in matches" :key="idx">
          <span>{{ match[0] }}</span> (distance: {{ match[1] }})
        </li>
      </ul>
    </div>
    <div v-else>
      <p>No matches found yet.</p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';

const matches = ref([]);
const scanStatus = ref('');

async function fetchMatches() {
  const res = await fetch('http://localhost:5000/api/matches');
  const data = await res.json();
  matches.value = data.matches || [];
}

async function handleScan() {
  scanStatus.value = 'Scanning for matches...';
  await fetch('http://localhost:5000/api/scan', { method: 'POST' });
  scanStatus.value = 'Scan complete!';
  await fetchMatches();
}

fetchMatches();
</script>

<style scoped>
</style>
