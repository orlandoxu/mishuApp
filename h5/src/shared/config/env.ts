export const env = {
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:3000',
  appStoreUrl: import.meta.env.VITE_APP_STORE_URL ?? 'https://apps.apple.com/',
  universalLinkBaseUrl: import.meta.env.VITE_UNIVERSAL_LINK_BASE_URL ?? 'https://wx-server.spreadwin.com/app',
};
