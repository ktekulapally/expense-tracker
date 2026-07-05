// Minimal service worker: caches the app shell (HTML/CSS/JS/icons) so the
// app has something to show even with a flaky connection, and so Android
// Chrome reliably offers the "Install app" prompt. It does NOT cache your
// Supabase data — that always goes over the network, live.
//
// Bump CACHE_NAME any time you change one of the precached files below, so
// returning visitors get the fresh version instead of a stale cached one.
const CACHE_NAME = "ledger-shell-v1";

const PRECACHE_URLS = [
  "./index.html",
  "./income.html",
  "./recurring.html",
  "./reset-password.html",
  "./styles.css?v=2",
  "./supabase-config.js",
  "./session-guard.js",
  "./manifest.json",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(PRECACHE_URLS))
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  const url = new URL(event.request.url);

  // Only handle our own same-origin app-shell files. Everything else
  // (Supabase API calls, CDN scripts for Chart.js/jsPDF/etc.) goes straight
  // to the network untouched — we never want to serve stale data or an old
  // library version from cache.
  if (url.origin !== self.location.origin) return;

  event.respondWith(
    caches.match(event.request).then((cached) => {
      const network = fetch(event.request)
        .then((response) => {
          if (response && response.ok) {
            const clone = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, clone));
          }
          return response;
        })
        .catch(() => cached);
      return cached || network;
    })
  );
});
