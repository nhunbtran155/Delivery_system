/* ======================================================
   🔥 Firebase Messaging Service Worker – Web Push Setup
   ====================================================== */

importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

/* ======================================================
   ✅ Firebase Project Config (sos-prj)
   ====================================================== */
firebase.initializeApp({
  apiKey: "AIzaSyDt2Wryz_70sRQXaYvAObmd-RY0M445gFo",
  authDomain: "sos-prj.firebaseapp.com",
  projectId: "sos-prj",
  storageBucket: "sos-prj.appspot.com",
  messagingSenderId: "678872102873",
  appId: "1:678872102873:web:1b2b9c21a4058a28adcbc8",
});

/* ======================================================
   ⚙️ Initialize Messaging
   ====================================================== */
const messaging = firebase.messaging();

/* ======================================================
   📦 Background Message Handler
   ====================================================== */
messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] 🎯 Received background message:', payload);

  const notificationTitle = payload.notification?.title || 'Thông báo mới';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});

/* ======================================================
   🖱️ Handle Notification Clicks
   ====================================================== */
self.addEventListener('notificationclick', (event) => {
  console.log('[firebase-messaging-sw.js] 🖱️ Notification click event:', event);
  event.notification.close();

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      // Nếu tab app đang mở → focus tab đó
      for (const client of clientList) {
        if (client.url.includes('/') && 'focus' in client) return client.focus();
      }
      // Nếu chưa có tab → mở mới
      if (clients.openWindow) return clients.openWindow('/');
    })
  );
});

/* ======================================================
   ✅ Debug Log
   ====================================================== */
console.log('✅ [Service Worker] Firebase Messaging loaded successfully');
