import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
   build: {
      lib: {
         entry: resolve(__dirname, 'src/Resources/app/storefront/src/main.js'),
         name: 'ShopFeatures',
         fileName: () => 'shop-features-plugin.js',
         formats: ['iife'],
      },
      outDir: resolve(__dirname, 'src/Resources/app/storefront/dist/storefront/js/shop-features-plugin'),
      emptyOutDir: false,
      minify: true,
   },
   server: {
      watch: {
         usePolling: true,
      },
   },
});
