var CACHE = "framlin-v1";
self.addEventListener("install", function (e) { self.skipWaiting(); });
self.addEventListener("activate", function (e) {
  e.waitUntil(caches.keys().then(function (keys) {
    return Promise.all(keys.filter(function (k) { return k !== CACHE; }).map(function (k) { return caches.delete(k); }));
  }).then(function () { return self.clients.claim(); }));
});
self.addEventListener("fetch", function (e) {
  if (e.request.method !== "GET") return;
  var url = new URL(e.request.url);
  if (url.pathname === "/" || url.pathname.endsWith(".html")) {
    e.respondWith(fetch(e.request).then(function (r) {
      var c = r.clone(); caches.open(CACHE).then(function (cache) { cache.put(e.request, c); }); return r;
    }).catch(function () { return caches.match(e.request); }));
  } else {
    e.respondWith(caches.match(e.request).then(function (hit) {
      return hit || fetch(e.request).then(function (r) {
        var c = r.clone(); caches.open(CACHE).then(function (cache) { cache.put(e.request, c); }); return r;
      });
    }));
  }
});
