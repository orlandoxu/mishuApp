import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

// 为什么代码上爆红呢？ // Cannot find module 'vite' or its corresponding type declarations.ts(2307)
export default defineConfig({
  plugins: [react(), tailwindcss()],
});
