import Foundation
import Capacitor
import Photos
import PhotosUI
import UIKit
import UniformTypeIdentifiers

/**
 * TowaLivePhoto — PHPicker wrapper that returns both the still image and the
 * paired video of an iOS Live Photo.
 *
 * JS:
 *   TowaLivePhoto.pick({ limit: 1 })
 *   -> { items: [{ imagePath, imageBase64, videoPath, videoBase64, isLive }] }
 *
 * Return base64 as well as a temp path: in a remote-URL Capacitor shell the
 * WebView can fail to fetch capacitor:// local file URLs, so the web layer
 * uses base64 first and only falls back to the path.
 */
@objc(TowaLivePhotoPlugin)
public class TowaLivePhotoPlugin: CAPPlugin, CAPBridgedPlugin, PHPickerViewControllerDelegate {
    public let identifier = "TowaLivePhotoPlugin"
    public let jsName = "TowaLivePhoto"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "pick", returnType: CAPPluginReturnPromise)
    ]

    private var pendingCall: CAPPluginCall?
    private let maxVideoBase64Bytes = 15 * 1024 * 1024

    @objc func pick(_ call: CAPPluginCall) {
        guard pendingCall == nil else {
            call.reject("picker already open")
            return
        }
        pendingCall = call
        let limit = max(1, min(9, call.getInt("limit") ?? 1))

        DispatchQueue.main.async {
            var config = PHPickerConfiguration(photoLibrary: PHPhotoLibrary.shared())
            config.filter = .any(of: [.images, .livePhotos])
            config.selectionLimit = limit
            config.preferredAssetRepresentationMode = .current
            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self
            self.bridge?.viewController?.present(picker, animated: true)
        }
    }

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let call = pendingCall else { return }
        pendingCall = nil

        guard !results.isEmpty else {
            call.resolve(["items": []])
            return
        }

        let group = DispatchGroup()
        let lock = NSLock()
        var items: [[String: Any]] = []

        for result in results {
            group.enter()
            extract(result: result) { item in
                lock.lock()
                if let item = item { items.append(item) }
                lock.unlock()
                group.leave()
            }
        }

        group.notify(queue: .main) {
            call.resolve(["items": items])
        }
    }

    private func extract(result: PHPickerResult, completion: @escaping ([String: Any]?) -> Void) {
        // Live Photo: assetIdentifier lets us find the paired video resource.
        if let assetId = result.assetIdentifier {
            let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
            if let asset = assets.firstObject {
                let resources = PHAssetResource.assetResources(for: asset)
                let video = resources.first { $0.type == .pairedVideo }
                if let video = video {
                    let group = DispatchGroup()
                    var imagePath: String?
                    var imageBase64: String?
                    var videoPath: String?
                    var videoBase64: String?

                    group.enter()
                    self.loadImage(result: result, asset: asset) { data in
                        if let data = data {
                            let saved = self.saveImageData(data)
                            imagePath = saved?.0
                            imageBase64 = saved?.1
                        }
                        group.leave()
                    }
                    group.enter()
                    self.copyResource(video) { path, b64 in
                        videoPath = path
                        videoBase64 = b64
                        group.leave()
                    }
                    group.notify(queue: .global()) {
                        guard let imagePath = imagePath, let imageBase64 = imageBase64 else {
                            self.extractImage(result: result, completion: completion)
                            return
                        }
                        var item: [String: Any] = [
                            "imagePath": imagePath,
                            "imageBase64": imageBase64,
                            "isLive": videoPath != nil,
                        ]
                        if let videoPath = videoPath { item["videoPath"] = videoPath }
                        if let videoBase64 = videoBase64 { item["videoBase64"] = videoBase64 }
                        completion(item)
                    }
                    return
                }
            }
        }

        // Not a live photo (or no paired video): return the still only.
        extractImage(result: result, completion: completion)
    }

    private func extractImage(result: PHPickerResult, completion: @escaping ([String: Any]?) -> Void) {
        loadImage(result: result, asset: nil) { data in
            guard let data = data, let saved = self.saveImageData(data) else {
                completion(nil)
                return
            }
            completion([
                "imagePath": saved.0,
                "imageBase64": saved.1,
                "isLive": false,
            ])
        }
    }

    /** 优先用 PHAsset 取静图；没有 asset / 失败再回退到 itemProvider */
    private func loadImage(result: PHPickerResult, asset: PHAsset?, completion: @escaping (Data?) -> Void) {
        if let asset = asset {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            var finished = false
            let lock = NSLock()
            let finish: (Data?) -> Void = { data in
                lock.lock()
                if finished {
                    lock.unlock()
                    return
                }
                finished = true
                lock.unlock()
                completion(data)
            }
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                if let data = data {
                    if let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.92) {
                        finish(jpeg)
                    } else {
                        finish(data)
                    }
                } else {
                    self.loadImageFromProvider(result: result, completion: finish)
                }
            }
            return
        }
        loadImageFromProvider(result: result, completion: completion)
    }

    private func loadImageFromProvider(result: PHPickerResult, completion: @escaping (Data?) -> Void) {
        let provider = result.itemProvider
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                if let image = object as? UIImage, let data = image.jpegData(compressionQuality: 0.92) {
                    completion(data)
                } else {
                    self.loadImageDataRepresentation(provider: provider, completion: completion)
                }
            }
            return
        }
        loadImageDataRepresentation(provider: provider, completion: completion)
    }

    private func loadImageDataRepresentation(provider: NSItemProvider, completion: @escaping (Data?) -> Void) {
        provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
            guard let data = data else { completion(nil); return }
            if let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.92) {
                completion(jpeg)
            } else {
                completion(data)
            }
        }
    }

    /** 返回 (path, base64)；base64 是给远程 URL 壳里的 WebView 兜底用的 */
    private func saveImageData(_ data: Data) -> (String, String)? {
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".jpg")
        do {
            try data.write(to: dest, options: .atomic)
            return (dest.path, data.base64EncodedString())
        } catch {
            return nil
        }
    }

    private func copyResource(_ resource: PHAssetResource, completion: @escaping (String?, String?) -> Void) {
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mov")
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        PHAssetResourceManager.default().writeData(for: resource, toFile: dest, options: options) { error in
            guard error == nil, let data = try? Data(contentsOf: dest) else {
                completion(nil, nil)
                return
            }
            let b64 = data.count <= self.maxVideoBase64Bytes ? data.base64EncodedString() : nil
            completion(dest.path, b64)
        }
    }
}
