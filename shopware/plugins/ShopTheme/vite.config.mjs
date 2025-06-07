import { defineConfig } from 'vite';
import { resolve } from 'path';
import fs from 'fs-extra';

export default defineConfig({
   build: {
      lib: {
         entry: resolve('src/Resources/app/storefront/src/main.js'),
         name: 'ShopTheme',
         fileName: () => 'shop-theme.js',
         formats: ['iife']
      },
      outDir: resolve('src/Resources/app/storefront/dist/storefront/js/shop-theme'),
      emptyOutDir: false,
      minify: true
   },
   server: {
      watch: {
         usePolling: true
      }
   },
   plugins: [
      {
         name: 'copy-assets',
         apply: 'build',
         buildEnd() {
            const source = resolve('src/Resources/app/storefront/src/assets');
            const destination = resolve('src/Resources/app/storefront/dist/assets');

            fs.removeSync(destination);
            fs.copySync(source, destination);

            console.log(`✔ Assets copied from ${source} to ${destination}`);
         }
      }
   ]
});
