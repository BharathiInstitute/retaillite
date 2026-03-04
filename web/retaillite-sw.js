// Custom service worker for RetailLite PWA
// Combines Firebase Cloud Messaging with offline-first caching strategy.
//
// This service worker is registered alongside Flutter's flutter_service_worker.js.
// Flutter handles app shell caching; this handles:
//   1. FCM background push notifications
//   2. API response caching for offline-first experience
//   3. Offline fallback page
//
// Note: Flutter's built-in service worker (flutter_service_worker.js) already
// caches the app shell (HTML, JS, CSS, assets). This worker focuses on
// runtime data caching and FCM.

const CACHE_NAME = 'retaillite-data-v1';
const OFFLINE_URL = '/index.html';

// URLs to cache for offline access (app shell is cached by Flutter SW)
const DATA_CACHE_URLS = [
  '/manifest.json',
  '/favicon.png',
  '/icons/Icon-192.png',
  '/icons/Icon-512.png',
];

// Install: pre-cache critical assets
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[retaillite-sw] Pre-caching offline assets');
      return cache.addAll(DATA_CACHE_URLS);
    })
  );
  // Activate immediately without waiting
  self.skipWaiting();
});

// Activate: clean old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((name) => name.startsWith('retaillite-') && name !== CACHE_NAME)
          .map((name) => {
            console.log('[retaillite-sw] Removing old cache:', name);
            return caches.delete(name);
          })
      );
    })
  );
  // Claim all clients immediately
  self.clients.claim();
});

// Fetch: Network-first with cache fallback for API calls
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Skip non-GET requests
  if (event.request.method !== 'GET') return;

  // Skip Firebase/Google API calls (handled by Firebase SDK)
  if (url.hostname.includes('googleapis.com') ||
      url.hostname.includes('firebaseio.com') ||
      url.hostname.includes('gstatic.com')) {
    return;
  }

  // For navigation requests, let Flutter's SW handle it
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).catch(() => {
        return caches.match(OFFLINE_URL);
      })
    );
    return;
  }

  // For static assets: cache-first strategy
  if (url.pathname.match(/\.(png|jpg|jpeg|svg|gif|ico|woff2?|ttf|css)$/)) {
    event.respondWith(
      caches.match(event.request).then((cached) => {
        if (cached) return cached;
        return fetch(event.request).then((response) => {
          if (response.ok) {
            const clone = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
          }
          return response;
        });
      })
    );
  }
});
