// Firebase Cloud Messaging service worker for web push notifications.
// This file must be in web/ root for FCM to handle background messages.

importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: "AIzaSyAA5Y-43RM2IItOsWpbygeHQhVbU2zFe48",
    authDomain: "login-radha.firebaseapp.com",
    projectId: "login-radha",
    storageBucket: "login-radha.firebasestorage.app",
    messagingSenderId: "576503526807",
    appId: "1:576503526807:web:23cf36d320396b512300d2",
});

const messaging = firebase.messaging();

// Handle background messages (when tab is not focused)
messaging.onBackgroundMessage(function (payload) {
    console.log('[firebase-messaging-sw.js] Background message received:', payload);

    const notificationTitle = payload.notification?.title || 'New Notification';
    const notificationOptions = {
        body: payload.notification?.body || '',
        icon: '/icons/Icon-192.png',
        badge: '/icons/Icon-192.png',
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
});
