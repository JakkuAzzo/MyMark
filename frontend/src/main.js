import { createApp } from 'vue';
import App from './App.vue';
import { createPinia } from 'pinia';

const app = createApp(App);
app.use(createPinia());
app.mount('#app');

// No change needed here, but ensure all fetch requests use credentials: 'include'
