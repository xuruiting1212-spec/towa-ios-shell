import type { CapacitorConfig } from '@capacitor/cli';

/**
 * Towa iOS 壳（远程加载版）
 * - server.url: 加载线上网页；网页更新走 Vercel 部署，ipa 打开即新版（不用重打包）
 * - 桥已加 waitForBridge()（等桥就绪再调用，避免白屏竞态）
 */
const config: CapacitorConfig = {
  appId: 'com.pipedream520.towa',
  appName: 'Towa',
  webDir: 'www',
  server: {
    url: 'https://chat.pipedream520towa.cn/',
    cleartext: false,
  },
  ios: {
    contentInset: 'automatic',
  },
};

export default config;
