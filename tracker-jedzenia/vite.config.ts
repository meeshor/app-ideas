/// <reference types="vitest/config" />
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';

export default defineConfig({
  // względne ścieżki: build działa też z podkatalogu (np. GitHub Pages)
  base: './',
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.svg', 'apple-touch-icon.png'],
      manifest: {
        name: 'Zjadłem — tracker jedzenia',
        short_name: 'Zjadłem',
        description: 'Wpisz zwykłym zdaniem, co zjadłeś. Przejrzyste szacunki kalorii i makro, offline.',
        lang: 'pl',
        start_url: './',
        scope: './',
        display: 'standalone',
        background_color: '#f6f5f1',
        theme_color: '#2f7d4f',
        icons: [
          { src: 'icon-192.png', sizes: '192x192', type: 'image/png' },
          { src: 'icon-512.png', sizes: '512x512', type: 'image/png' },
          { src: 'icon-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
        ],
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,svg,png,json,webmanifest}'],
      },
    }),
  ],
  test: {
    include: ['src/**/*.test.ts'],
    environment: 'node',
  },
});
