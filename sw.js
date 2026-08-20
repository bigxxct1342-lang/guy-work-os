const CACHE="guy-work-os-v7-5-3-porkchop-splash";
const ASSETS=["./","./index.html","./config.js","./manifest.json","./favicon.ico","./favicon-32.png","./icon-192.png","./icon-512.png","./porkchop-splash.jpg"];
self.addEventListener("install",e=>{self.skipWaiting();e.waitUntil(caches.open(CACHE).then(c=>c.addAll(ASSETS)))});
self.addEventListener("activate",e=>e.waitUntil(
  caches.keys().then(keys=>Promise.all(keys.filter(k=>k.startsWith("guy-work-os-")&&k!==CACHE).map(k=>caches.delete(k)))).then(()=>self.clients.claim())
));
self.addEventListener("fetch",e=>{if(e.request.method!=="GET")return;e.respondWith(fetch(e.request).catch(()=>caches.match(e.request)))});

self.addEventListener("push",e=>{
  let data={title:"GUY WORK OS",body:"You have tasks to check.",url:"./"};
  try{if(e.data)data={...data,...e.data.json()}}catch(_){}
  e.waitUntil(self.registration.showNotification(data.title,{
    body:data.body,
    icon:"./icon-192.png",
    badge:"./favicon-32.png",
    data:{url:data.url||"./"}
  }));
});

self.addEventListener("notificationclick",e=>{
  e.notification.close();
  const url=e.notification.data?.url||"./";
  e.waitUntil(self.clients.matchAll({type:"window",includeUncontrolled:true}).then(list=>{
    for(const c of list){if("focus" in c)return c.focus()}
    if(self.clients.openWindow)return self.clients.openWindow(url);
  }));
});
