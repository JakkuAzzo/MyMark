<template>
  <div style="padding: 20px;">
    <h2>Statistics</h2>
    <div>
      <span>Images tracked: {{ stats.images }}</span><br />
      <span>Matches found: {{ stats.matches }}</span><br />
      <span>Last scan: {{ stats.last_scan || '-' }}</span>
    </div>
    <button @click="fetchStats" style="margin-top: 10px;">Refresh Stats</button>
  </div>
</template>

<script setup>
import { ref } from 'vue';

const stats = ref({ images: 0, matches: 0, last_scan: null });

async function fetchStats() {
  const res = await fetch('http://localhost:5000/api/stats');
  const data = await res.json();
  stats.value = data;
}

fetchStats();
</script>

<style scoped>
</style>
