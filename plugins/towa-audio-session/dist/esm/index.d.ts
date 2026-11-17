export interface TowaAudioSessionPlugin {
  activate(): Promise<{ ok: boolean }>;
  deactivate(): Promise<{ ok: boolean }>;
}

declare const TowaAudioSession: TowaAudioSessionPlugin;
export { TowaAudioSession };
