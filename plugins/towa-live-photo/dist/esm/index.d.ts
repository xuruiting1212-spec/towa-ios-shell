export interface PickedLivePhoto {
  imagePath: string;
  videoPath?: string;
  isLive: boolean;
}

export interface TowaLivePhotoPlugin {
  pick(options?: { limit?: number }): Promise<{ items: PickedLivePhoto[] }>;
}

declare const TowaLivePhoto: TowaLivePhotoPlugin;
export { TowaLivePhoto };
