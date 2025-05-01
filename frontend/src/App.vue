<template>
  <div style="font-family:sans-serif;">
    <div class="navbar cubist-navbar">
      <img src="/MyMark.svg" alt="MyMark Logo" class="logo navbar-logo" />
      <div class="nav-links">
        <button
          v-for="item in navItems"
          :key="item.name"
          :class="['cubist-btn', page === item.name && 'active']"
          @click="page = item.name"
        >
          {{ item.label }}
        </button>
      </div>
    </div>
    <Dashboard v-if="page === 'dashboard'" @updatePage="page = $event" />
    <Upload v-else-if="page === 'upload'" />
    <Matches v-else-if="page === 'matches'" />
    <Stats v-else-if="page === 'stats'" />
    <Auth v-else-if="page === 'auth'" />
    <Cubist404 v-else @goHome="page = 'dashboard'" />
  </div>
</template>

<script setup>
import { ref } from 'vue';
import Dashboard from './components/Dashboard.vue';
import Upload from './components/Upload.vue';
import Matches from './components/Matches.vue';
import Stats from './components/Stats.vue';
import Auth from './components/Auth.vue';
import Cubist404 from './components/Cubist404.vue';

const page = ref('dashboard');
const navItems = [
  { name: 'auth', label: 'Auth' },
  { name: 'dashboard', label: 'Dashboard' },
  { name: 'upload', label: 'Upload' },
  { name: 'matches', label: 'Matches' },
  { name: 'stats', label: 'Stats' }
];
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
nav {
  display: none;
}
.navbar.cubist-navbar {
  display: flex;
  align-items: center;
  background: #fff;
  border-bottom: 4px solid #222;
  box-shadow: 0 4px 0 #bbb, 0 0 0 8px #fff inset;
  padding: 12px 24px;
  margin-bottom: 32px;
}
.nav-links {
  flex: 1;
  display: flex;
  justify-content: space-around;
  gap: 16px;
}
.logo {
  display: block;
  margin: 0 16px 0 0;
  width: 40px;
  height: 40px;
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
</style>
