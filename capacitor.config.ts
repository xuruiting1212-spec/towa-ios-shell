import type { CapacitorConfig } from '@capacitor/cli';

/**
 * Towa iOS 壳（远程加载版）
 * - server.url: 加载线上网页；网页更新走 Vercel 部署，ipa 打开即新版（不用重打包）
 * - ios.contentInset: 'never' —— WebView 全屏填满，网页自己的 safe-* 处理刘海/Home条，
 *   避免"自动内缩 + 网页再内缩"造成的上下双重空白
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
    contentInset: 'never',
  },
};

export default config;
