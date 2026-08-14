const CACHE="guy-work-os-v6";
const ASSETS=["./","./index.html","./config.js","./manifest.json"];
self.addEventListener("install",e=>e.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS))));
self.addEventListener("activate",e=>e.waitUntil(self.clients.claim()));
self.addEventListener("fetch",e=>{if(e.request.method!=="GET")return;e.respondWith(fetch(e.request).catch(()=>caches.match(e.request)))});
