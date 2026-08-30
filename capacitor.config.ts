import type { CapacitorConfig } from '@capacitor/cli';

/**
 * Towa iOS 壳配置
 * - server.url: 加载线上网页（改这里 = 壳加载别的地址）
 * - 网页内容更新走 Vercel 部署，壳不需要重打包
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
    // 本地通知 / 日历 / 震动 / 设备信息 都是免费签名可用，无需特殊 entitlements
    contentInset: 'automatic',
  },
};

export default config;
