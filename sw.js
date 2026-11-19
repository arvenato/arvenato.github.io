// Uygulama dosyalarını önbelleğe alır. Sayfa her açılışta internetten en güncel sürümü alır;
// internet yoksa son kaydedilen sürüm açılır. Veriler (Supabase) önbelleğe alınmaz.
const SURUM = "v27";
const KABUK = ["./", "./index.html", "./config.js", "./manifest.webmanifest", "./icon-192.png", "./icon-512.png", "./logo-yatay.png", "./logo.jpg"];
self.addEventListener("install", e => { e.waitUntil(caches.open(SURUM).then(c => c.addAll(KABUK)).then(() => self.skipWaiting())); });
self.addEventListener("activate", e => { e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== SURUM).map(k => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener("fetch", e => {
  const u = new URL(e.request.url);
  if (e.request.method !== "GET" || u.hostname.endsWith("supabase.co")) return;
  const ayniKaynak = u.origin === self.location.origin;
  const kutuphane = /cdnjs\.cloudflare\.com|cdn\.jsdelivr\.net|fonts\.(googleapis|gstatic)\.com/.test(u.hostname);
  if (ayniKaynak) {
    // cache:'no-cache' → tarayıcının HTTP önbelleği atlanır, sunucuya "değişti mi?" sorulur (yeni sürüm hemen gelir)
    e.respondWith(fetch(e.request.url, { cache: "no-cache", credentials: "same-origin" }).then(r => { if (r.ok) { const k = r.clone(); caches.open(SURUM).then(c => c.put(e.request, k)); } return r; })
      .catch(() => caches.match(e.request, { ignoreSearch: true }).then(r => r || caches.match("./index.html"))));
  } else if (kutuphane) {
    e.respondWith(caches.match(e.request).then(r => r || fetch(e.request).then(res => { const k = res.clone(); caches.open(SURUM).then(c => c.put(e.request, k)); return res; })));
  }
});
