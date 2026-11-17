import Foundation
import Capacitor
import AVFoundation

/**
 * TowaAudioSession — 把 App 的音频会话设成播放模式。
 *
 * 解决：iPhone 侧边静音拨片打开时，<audio> / WebAudio 被系统静音。
 * category = .playback 时，App 自己播放的音频不受静音拨片影响。
 *
 * JS: TowaAudioSession.activate()
 */
@objc(TowaAudioSessionPlugin)
public class TowaAudioSessionPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "TowaAudioSessionPlugin"
    public let jsName = "TowaAudioSession"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "activate", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "deactivate", returnType: CAPPluginReturnPromise)
    ]

    @objc func activate(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            do {
                let session = AVAudioSession.sharedInstance()
                try session.setCategory(.playback, mode: .default, options: [])
                try session.setActive(true)
                call.resolve(["ok": true])
            } catch {
                call.reject("audio session activate failed: \(error.localizedDescription)")
            }
        }
    }

    @objc func deactivate(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            do {
                try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
                call.resolve(["ok": true])
            } catch {
                call.reject("audio session deactivate failed: \(error.localizedDescription)")
            }
        }
    }
}
