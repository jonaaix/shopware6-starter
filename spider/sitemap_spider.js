const axios = require('axios');
const zlib = require('zlib');
const { XMLParser } = require('fast-xml-parser');
const fs = require('fs/promises');
const yaml = require('js-yaml');

const parser = new XMLParser({ ignoreAttributes: false });

const pools = {};   // { label: [url1, url2, ...] }
const pending = {}; // { label: Set<sitemapUrls> }

function getLabel(url) {
   return url.replace(/^https?:\/\//, '');
}

function shuffle(array) {
   for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [array[i], array[j]] = [array[j], array[i]];
   }
}

async function loadSitemaps(entryUrl) {
   const label = getLabel(entryUrl);
   pending[label] = new Set([entryUrl]);
   pools[label] = [];

   console.log(`\n🌐 Starting pool: ${label}`);
   console.log(`→ Downloading entry sitemap: ${entryUrl}`);

   await processSitemap(entryUrl, label);
}

async function processSitemap(url, label) {
   try {
      console.log(`→ Downloading sitemap: ${url}`);
      const res = await axios.get(url, { responseType: 'arraybuffer' });

      let xmlContent = res.data;
      if (url.endsWith('.gz')) {
         xmlContent = zlib.gunzipSync(xmlContent).toString('utf-8');
      } else {
         xmlContent = Buffer.from(xmlContent).toString('utf-8');
      }

      const parsed = parser.parse(xmlContent);
      const urls = extractLocs(parsed);

      for (const loc of urls) {
         if (loc.endsWith('.xml') || loc.endsWith('.gz')) {
            if (!pending[label].has(loc)) {
               pending[label].add(loc);
               console.log(`↪ Found nested sitemap: ${loc}`);
               await processSitemap(loc, label);
            }
         } else {
            pools[label].push(loc);
         }
      }

      pending[label].delete(url);
   } catch (err) {
      console.error(`❌ Failed to process ${url}:`, err.message);
   }
}

function extractLocs(parsed) {
   const entries = parsed.urlset?.url || parsed.sitemapindex?.sitemap || [];
   return Array.isArray(entries)
      ? entries.map(e => e.loc).filter(Boolean)
      : [entries.loc].filter(Boolean);
}

async function roundRobinCrawl() {
   const concurrency = parseInt(process.env.CONCURRENT_REQUESTS || '4', 10);
   const timeout = parseInt(process.env.URL_REQUEST_TIMEOUT || '1000', 10);

   const globalQueue = [];
   const progress = {};

   for (const [label, urls] of Object.entries(pools)) {
      progress[label] = { total: urls.length, done: 0 };
      for (const url of urls) {
         globalQueue.push({ label, url });
      }
   }

   shuffle(globalQueue);

   console.log(`\n🚀 Starting crawl with ${globalQueue.length} URLs across ${Object.keys(pools).length} pools`);

   const worker = async () => {
      while (globalQueue.length > 0) {
         const item = globalQueue.pop();
         if (!item) break;

         const { label, url } = item;
         const start = process.hrtime.bigint();

         try {
            const response = await axios.get(url, {
               timeout,
               headers: {
                  'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/122 Safari/537.36',
                  'Accept': 'text/html,application/xhtml+xml',
                  'Accept-Language': 'en-US,en;q=0.9',
                  'Referer': 'https://cache-warmup.local'
               }
            });
            const durationMs = Number(process.hrtime.bigint() - start) / 1e6;
            const xCache = response.headers['x-cache'] || 'N/A';

            progress[label].done += 1;

            const emoji = getSpeedEmoji(durationMs, timeout);
            console.log(`${emoji} [${xCache}] [${durationMs.toFixed(0)}ms] ${url}`);
         } catch (err) {
            const durationMs = Number(process.hrtime.bigint() - start) / 1e6;
            const xCache = err.response?.headers?.['x-cache'] || 'N/A';

            progress[label].done += 1;

            const emoji = '❌';
            console.log(`${emoji} [${xCache}] [${durationMs.toFixed(0)}ms] ${url}`);
         }

         // 🎯 Show progress every 50 requests or when done
         if (progress[label].done % 50 === 0 || progress[label].done === progress[label].total) {
            const { total, done } = progress[label];
            logProgressFrame(label, done, total);
         }
      }
   };

   const workers = Array.from({ length: concurrency }, worker);
   await Promise.all(workers);

   console.log('\n✅ All pools completed.\n');

   console.log('\n📊 Final Crawl Summary:');
   for (const [label, { total, done }] of Object.entries(progress)) {
      console.log(`- ${label}: ${done} / ${total} URLs processed`);
   }
}

function logProgressFrame(label, done, total) {
   const bar = renderProgressBar(done, total);
   const percent = Math.round((done / total) * 100);
   const line = `📊 Progress for [${label}]: ${done}/${total} (${percent}%) ${bar}`;

   const padding = 2;
   const contentWidth = line.length + padding * 2;
   const horizontal = '═'.repeat(contentWidth);

   console.log('');
   console.log(`\x1b[1m\x1b[34m╔${horizontal}╗`);
   console.log(`║${' '.repeat(contentWidth)}║`);
   console.log(`║${' '.repeat(padding)}${line}${' '.repeat(padding)}║`);
   console.log(`║${' '.repeat(contentWidth)}║`);
   console.log(`╚${horizontal}╝\x1b[0m`);
   console.log('');
}


function renderProgressBar(done, total, width = 30) {
   const percent = done / total;
   const filled = Math.round(percent * width);
   const empty = width - filled;

   return `[${'■'.repeat(filled)}${'·'.repeat(empty)}] ${Math.round(percent * 100)}%`;
}

function getSpeedEmoji(durationMs, timeoutMs) {
   if (durationMs < 100) return '⚡';
   const ratio = durationMs / timeoutMs;
   if (ratio <= 0.5) return '🟢';
   if (ratio <= 0.75) return '🟡';
   return '🔴';
}

(async () => {
   const content = await fs.readFile('sitemaps.yaml', 'utf8');
   const entrypoints = yaml.load(content);

   console.log(`\n📄 Found ${entrypoints.length} sitemap entrypoints.`);

   for (const entry of entrypoints) {
      await loadSitemaps(entry);
   }

   // Shuffle each pool before crawling
   for (const urls of Object.values(pools)) {
      shuffle(urls);
   }

   await roundRobinCrawl();
})();
