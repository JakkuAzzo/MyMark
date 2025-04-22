<template>
  <div style="padding: 20px;">
    <h2>Auth</h2>
    <div>
      <input v-model="username" placeholder="Username" style="margin-right: 10px;" />
      <input v-model="password" type="password" placeholder="Password" style="margin-right: 10px;" />
      <button @click="handleRegister">Register</button>
      <button @click="handleLogin" style="margin-left: 10px;">Login</button>
    </div>
    <p>{{ status }}</p>
  </div>
</template>

<script setup>
import { ref } from 'vue';

const username = ref('');
const password = ref('');
const status = ref('');

async function handleRegister() {
  status.value = 'Registering...';
  const res = await fetch('http://localhost:5000/api/register', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: username.value, password: password.value })
  });
  const data = await res.json();
  status.value = data.message || 'Registration failed.';
}

async function handleLogin() {
  status.value = 'Logging in...';
  const res = await fetch('http://localhost:5000/api/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: username.value, password: password.value })
  });
  const data = await res.json();
  status.value = data.message || 'Login failed.';
}
</script>

<style scoped>
</style>
