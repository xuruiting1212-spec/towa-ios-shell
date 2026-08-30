import type { CapacitorConfig } from '@capacitor/cli';

/**
 * Towa iOS 壳配置
 * - webDir: 打包进 app 的网页产物（towa-chat 的 dist 构建）
 * - 数据（聊天/日程/账本等）走 Supabase，实时云端同步
 * - UI/代码改动需重新打包（push → 自动构建新 ipa）
 */
const config: CapacitorConfig = {
  appId: 'com.pipedream520.towa',
  appName: 'Towa',
  webDir: 'www',
  ios: {
    contentInset: 'automatic',
  },
};

export default config;
