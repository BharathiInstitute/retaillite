'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "6e634299c90842ecf0d22264f17c3150",
"assets/AssetManifest.bin.json": "ec87331fd31ce020345c20f5cbe91277",
"assets/AssetManifest.json": "b2bc459e552a63f8bc61d52cad4bf73d",
"assets/assets/fonts/NotoSansDevanagari-Bold.ttf": "44e0b243bd0ac5430fca8b45ddd9e040",
"assets/assets/fonts/NotoSansDevanagari-Regular.ttf": "44e0b243bd0ac5430fca8b45ddd9e040",
"assets/assets/icons/google_logo.svg": "d5ad2680412a20714086dd9a575cab00",
"assets/assets/images/app_icon.png": "3eb826263c3dc305059284ea6deb7a2d",
"assets/assets/images/app_icon_foreground.png": "22d42ee61ed336ff0e878f6197af415d",
"assets/assets/images/new%2520icon.png": "e54a564d6acd483d8f3ef20848d32543",
"assets/assets/images/splash_logo.png": "06fae96e9f5d1c7c84ce87cd67e63155",
"assets/FontManifest.json": "b65d97cef95095cf4c78b5007b633a66",
"assets/fonts/MaterialIcons-Regular.otf": "5432f7c11292e5fd1e80478bcd3b9dc8",
"assets/NOTICES": "f0e793f8825afa93ad0b5b47a6963cea",
"assets/packages/fluttertoast/assets/toastify.css": "a85675050054f179444bc5ad70ffc635",
"assets/packages/fluttertoast/assets/toastify.js": "56e2c9cedd97f10e7e5f1cebd85d53e3",
"assets/packages/win_ble/assets/BLEServer.exe": "28aa0e2566083c860f029ff4bc32c4ce",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "140ccb7d34d0a55065fbd422b843add6",
"canvaskit/canvaskit.js.symbols": "58832fbed59e00d2190aa295c4d70360",
"canvaskit/canvaskit.wasm": "07b9f5853202304d3b0749d9306573cc",
"canvaskit/chromium/canvaskit.js": "5e27aae346eee469027c80af0751d53d",
"canvaskit/chromium/canvaskit.js.symbols": "193deaca1a1424049326d4a91ad1d88d",
"canvaskit/chromium/canvaskit.wasm": "24c77e750a7fa6d474198905249ff506",
"canvaskit/skwasm.js": "1ef3ea3a0fec4569e5d531da25f34095",
"canvaskit/skwasm.js.symbols": "0088242d10d7e7d6d2649d1fe1bda7c1",
"canvaskit/skwasm.wasm": "264db41426307cfc7fa44b95a7772109",
"canvaskit/skwasm_heavy.js": "413f5b2b2d9345f37de148e2544f584f",
"canvaskit/skwasm_heavy.js.symbols": "3c01ec03b5de6d62c34e17014d1decd3",
"canvaskit/skwasm_heavy.wasm": "8034ad26ba2485dab2fd49bdd786837b",
"desktop-login.html": "05fcf68b9ea5853ac50f71f180068430",
"favicon.png": "55a6cc292df388871aecf5fcb80112e4",
"firebase-messaging-sw.js": "04b576c503ebb77dbc63fab1f6fc01e4",
"flutter.js": "888483df48293866f9f41d3d9274a779",
"flutter_bootstrap.js": "b1c540036bbf4a73db6b4366590258e0",
"icons/Icon-192.png": "8ab669b81356d2485279181faed530c7",
"icons/Icon-512.png": "bbbaa65c5bbcf39b30cb8c8ae5824df6",
"icons/Icon-maskable-192.png": "8ab669b81356d2485279181faed530c7",
"icons/Icon-maskable-512.png": "bbbaa65c5bbcf39b30cb8c8ae5824df6",
"index.html": "bca42c2a66ffb9dceb5e4352aa8f5902",
"/": "bca42c2a66ffb9dceb5e4352aa8f5902",
"main.dart.js": "350d20a666f3fb0636e577236af88dc3",
"manifest.json": "cc3ba12e76564a31231a894db7fbd5b8",
"retaillite-sw.js": "0ee3fd185d55c4f67b975ccf83f1c6a4",
"splash/img/dark-1x.png": "8b17e3391cc99ba6a34ce81ec4b40b3b",
"splash/img/dark-2x.png": "d16fc454456423bdd3651981695a89d8",
"splash/img/dark-3x.png": "0bddabbf2ba718bda68859c0f118b5fc",
"splash/img/dark-4x.png": "368d352b41e1fc664b8d53c58ff7ea4d",
"splash/img/light-1x.png": "8b17e3391cc99ba6a34ce81ec4b40b3b",
"splash/img/light-2x.png": "d16fc454456423bdd3651981695a89d8",
"splash/img/light-3x.png": "0bddabbf2ba718bda68859c0f118b5fc",
"splash/img/light-4x.png": "368d352b41e1fc664b8d53c58ff7ea4d",
"version.json": "a629687cddf870975b016a1b45775ce9"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
