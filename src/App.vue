<template>
  <div style="font-family:sans-serif;">
    <nav style="margin-bottom: 2rem;">
      <button @click="page = 'dashboard'">Dashboard</button>
      <button @click="page = 'upload'">Upload</button>
      <button @click="page = 'matches'">Matches</button>
      <button @click="page = 'stats'">Stats</button>
      <button @click="page = 'auth'">Auth</button>
    </nav>
    <Dashboard v-if="page === 'dashboard'" />
    <Upload v-else-if="page === 'upload'" />
    <Matches v-else-if="page === 'matches'" />
    <Stats v-else-if="page === 'stats'" />
    <Auth v-else-if="page === 'auth'" />
  </div>
</template>

<script setup>
import { ref } from 'vue';
import Dashboard from './components/Dashboard.vue';
import Upload from './components/Upload.vue';
import Matches from './components/Matches.vue';
import Stats from './components/Stats.vue';
import Auth from './components/Auth.vue';

const page = ref('dashboard');
</script>

<style scoped>
nav button {
  margin-right: 1rem;
  padding: 0.5rem 1rem;
  font-size: 1rem;
  border: 1px solid #ccc;
  background: #f8f8f8;
  border-radius: 4px;
  cursor: pointer;
}
nav button:hover {
  background: #e0e0e0;
}
</style>
