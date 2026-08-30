# towa-ios-capacitor — Towa iOS 壳（Capacitor）

加载线上网页 + 原生插件的 iOS 壳。**网页内容更新走 Vercel 部署，壳不需要重打包。**

## 目录

- `capacitor.config.ts` — 壳配置（`server.url` = 线上网址）
- `www/index.html` — Capacitor webDir 占位（运行时实际加载 server.url）
- `.github/workflows/build-ios.yml` — GitHub Actions：macOS 自动构建未签名 ipa

## 构建流程

```bash
npm install                 # 装依赖（core/calendar/local-notifications/haptics/device）
npm run add:ios             # 生成 ios/ 平台（已生成；CI 里会自动补）
npm run sync                # 同步配置 + 插件（CI 里执行 pod install）
```

### 本地/CI 构建（需要 macOS）

推送到 GitHub → Actions 自动跑 `build-ios.yml`：
1. `npx cap sync ios`（含 pod install）
2. `xcodebuild`（`CODE_SIGNING_ALLOWED=NO`，**未签名**）
3. 产出 `Towa-unsigned.ipa` artifact → 下载

### 签名安装（Windows，不需要 Mac）

1. Actions 页面下载 `Towa-unsigned.ipa`
2. **Sideloadly**（账号2）选择 ipa → Apple ID → Start
   或 **AltStore**（挂日本节点）→ My Apps → +
3. 装好后：设置 → 通用 → VPN与设备管理 → 信任

## 以后更新

| 更新类型 | 做法 |
|---|---|
| UI / 功能 / 数据 | 改 towa-chat → 部署 Vercel → **ipa 打开即新版**，不重打包 |
| 加新原生能力（新插件） | 改本仓库 → 推 GitHub → 新 ipa → 重新签名装 |

## 网页端桥调用

网页（towa-chat）里通过 `src/composables/useNative.ts` 调用，浏览器打开时自动降级。

| 能力 | 调用 |
|---|---|
| 日历读取 | `listCalendarEvents(start, end)` → 事件数组 |
| 本地通知 | `scheduleNotification({id, title, body, date})` |
| 震动 | `vibrate('MEDIUM')` |
| 设备信息 | `getDeviceInfo()` |

## 注意事项

- 免费签名支持日历/本地通知/震动/设备（无需 entitlements）
- ❌ 远程推送（APNs）、HealthKit、iCloud 需要付费账号，未用
- 本地通知在 app 被手动强杀后不触发（后台/锁屏正常）
- 首次构建时 `npx cap add ios` 在 CI 里会自愈（`|| true`）
