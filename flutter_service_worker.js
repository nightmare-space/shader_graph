'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "24bc71911b75b5f8135c949e27a2984e",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"manifest.json": "0867c3e13649ac4d06fe34b7b3ddce08",
"main.dart.mjs": "0230f4e901e4ab1f79ae09f6d972512a",
"shaders/bufferc.frag": "ae2ee0d7c87c843a96dfedf61b0d5a5f",
"shaders/bufferd.frag": "4bd9706119c71d7684e46a849a7dce94",
"shaders/buffera.frag": "6cc05497e068b5e8dbccfe8a14069551",
"shaders/image.frag": "bb1e76ab1fec4b03731f1e49eb76c2ca",
"shaders/bufferb.frag": "7cd8efd8535d77bc1f3434ce0c8443b5",
"index.html": "6477b1cab8860164c5a630e711add795",
"/": "6477b1cab8860164c5a630e711add795",
"assets/shaders/stretch_effect.frag": "40d68efbbf360632f614c731219e95f0",
"assets/shaders/keyboard/Keyboard%2520Test.frag": "09f98413ba780e11f69026e7f63b38ff",
"assets/shaders/keyboard/Keyboard%2520Debug%2520Overlay.frag": "474d60718cc531b77d33ce2fcb5edd32",
"assets/shaders/touch_simple.frag": "42fca4e601924e32900d8e5e97f68917",
"assets/shaders/text/Text%2520Texture.frag": "dc0a0060e223d55fe405efceb548264a",
"assets/shaders/mouse/Pentagonal%2520Conway's%2520game.frag": "6bcd4340394bb5cb3aba68532033c9a5",
"assets/shaders/mouse/Pentagonal%2520Conway's%2520game%2520BufferA.frag": "ebf69f0807d893c673311944b32dc2d9",
"assets/shaders/multi_pass/expansive%2520reaction-diffusion.frag": "36d5c5d7dd9b362ab3ed2c16760a1804",
"assets/shaders/multi_pass/expansive%2520reaction-diffusion%2520BufferA.frag": "134920cd54a49dd18950a6d4c0d704e2",
"assets/shaders/multi_pass/expansive%2520reaction-diffusion%2520BufferD.frag": "cff2e7b10834da6c27f462d3c4d4ecc9",
"assets/shaders/multi_pass/MacOS%2520Monterey%2520wallpaper.frag": "2cf23ec72997d5cc3e9aff00ea81c354",
"assets/shaders/multi_pass/Static%2520Vec4%2520Grid%2520A.frag": "8d47a72b7331cfda701091c162e0b655",
"assets/shaders/multi_pass/MacOS%2520Monterey%2520wallpaper%2520BufferA.frag": "45c83dd9bf3eb106a938a12e7c10fa38",
"assets/shaders/multi_pass/expansive%2520reaction-diffusion%2520BufferC.frag": "7b128a2b3751ea1496bbc0329b412775",
"assets/shaders/multi_pass/expansive%2520reaction-diffusion%2520BufferB.frag": "c3badb5695e463e58bf0c0053068506b",
"assets/shaders/game_ported/Pacman%2520Game.frag": "77ba57c3b000844eb092f5911979c02a",
"assets/shaders/game_ported/Bricks%2520Game.frag": "c264ecab8af4ada0c1f00756d9783c67",
"assets/shaders/game_ported/Bricks%2520Game%2520BufferB.frag": "edca45a5c5ec65981e4c9a1e92c472da",
"assets/shaders/game_ported/Pacman%2520Game%2520BufferA.frag": "ce62eeff05b7e56ff1d07652b59e3600",
"assets/shaders/game_ported/Pacman%2520Game%2520BufferB.frag": "80e3d55373450be259ac96c83e143a59",
"assets/shaders/game_ported/Bricks%2520Game%2520BufferA.frag": "d7c32897be322e946b7e8b2930c74278",
"assets/shaders/frame/IFrame%2520Test.frag": "d293b3b38606f68470af0e0bf0476290",
"assets/shaders/wrap/Wrap%2520Debug.frag": "e80f9cc18fe9cfa7bd143f7bbc154ea2",
"assets/shaders/wrap/Transition%2520Burning.frag": "b751c6363ae47d66accbb08068286988",
"assets/shaders/wrap/Broken%2520Time%2520Gate.frag": "580e91826875a94a07fbef24f2be741b",
"assets/shaders/wrap/Inverse%2520Bilinear.frag": "8eb3fcd7d1dfc395cf9e4ecb4c71ca80",
"assets/shaders/wrap/Tissue.frag": "da47ab1eca75d6c9797e29f58f569ec3",
"assets/shaders/wrap/Black%2520Hole%2520ODE%2520Geodesic%2520Solver.frag": "26f013d53364fa9b9a1b9bdbbb03c8c3",
"assets/shaders/wrap/Goodbye%2520Dream%2520Clouds.frag": "97e7a9da23fabf13d47cb47cc5c172b6",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin.json": "1777021075fd7ecde5702ab77c942792",
"assets/assets/Wall.jpg": "e7b007e82f41348d226ace03b265a229",
"assets/assets/textures/Rock%2520Tiles.jpg": "9fbf390b43318de68c775e5c4038498b",
"assets/assets/textures/Stars.jpg": "9c5db60dac5368487c5d24229d9e221b",
"assets/assets/textures/Grey%2520Noise%2520Medium.png": "25ef00f73e2e6a8f0e43f8ff5c8ba060",
"assets/assets/textures/Abstract1.jpg": "7b94f293f76b8b2aa311f2ffc27587cf",
"assets/assets/textures/RGBA%2520Noise%2520Medium.png": "7c756fce1f89f24b100bd4f08b36383d",
"assets/assets/textures/Pebbles.png": "96c6b05c3ce5d38401058d241dcd0a4c",
"assets/assets/codepage12.png": "b0625a60927ded509fa13336c69482e2",
"assets/fonts/MaterialIcons-Regular.otf": "d03642d3c557e9c715a17c8ef8c690a3",
"assets/NOTICES": "ecd0381e816482a485546bd18a5e9a7e",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "1b226f9bc0b2134363eeecb6492ae5b3",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin": "9a6a66d1827ec2404a5399173124f6af",
"noise.png": "7c756fce1f89f24b100bd4f08b36383d",
"canvaskit/chromium/canvaskit.wasm": "a726e3f75a84fcdf495a15817c63a35d",
"canvaskit/chromium/canvaskit.js": "a80c765aaa8af8645c9fb1aae53f9abf",
"canvaskit/chromium/canvaskit.js.symbols": "e2d09f0e434bc118bf67dae526737d07",
"canvaskit/skwasm_heavy.wasm": "b0be7910760d205ea4e011458df6ee01",
"canvaskit/skwasm_heavy.js.symbols": "0755b4fb399918388d71b59ad390b055",
"canvaskit/skwasm.js": "8060d46e9a4901ca9991edd3a26be4f0",
"canvaskit/canvaskit.wasm": "9b6a7830bf26959b200594729d73538e",
"canvaskit/skwasm_heavy.js": "740d43a6b8240ef9e23eed8c48840da4",
"canvaskit/canvaskit.js": "8331fe38e66b3a898c4f37648aaf7ee2",
"canvaskit/skwasm.wasm": "7e5f3afdd3b0747a1fd4517cea239898",
"canvaskit/canvaskit.js.symbols": "a3c9f77715b642d0437d9c275caba91e",
"canvaskit/skwasm.js.symbols": "3a4aadf4e8141f284bd524976b1d6bdc",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"main.dart.wasm": "ab7bfec7701d0ceafbd5f596141bd31b",
"three.js.html": "403fd63bb870e0fda8b789d27fa9e139",
"flutter_bootstrap.js": "39c79c0ea817d0696f4d0cc409443d7e",
"version.json": "ff966ab969ba381b900e61629bfb9789",
"main.js": "bae764e45fa7cbf03d7afb561a7db4b4",
"main.dart.js": "b20269c50888bd9fd17b88271be5c1e0",
"combined.html": "84a3041e2c356366b460ec49943ceed8"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"main.dart.wasm",
"main.dart.mjs",
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
