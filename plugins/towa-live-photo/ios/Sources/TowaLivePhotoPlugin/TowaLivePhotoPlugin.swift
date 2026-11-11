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
 *   -> { items: [{ imagePath, videoPath, isLive }] }
 *
 * The paths point at temp files. The web layer converts them via
 * Capacitor.convertFileSrc() and uploads the blobs to Supabase.
 */
@objc(TowaLivePhotoPlugin)
public class TowaLivePhotoPlugin: CAPPlugin, CAPBridgedPlugin, PHPickerViewControllerDelegate {
    public let identifier = "TowaLivePhotoPlugin"
    public let jsName = "TowaLivePhoto"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "pick", returnType: CAPPluginReturnPromise)
    ]

    private var pendingCall: CAPPluginCall?

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
                    var videoPath: String?
                    group.enter()
                    self.extractImagePath(result: result) { p in imagePath = p; group.leave() }
                    group.enter()
                    self.copyResource(video, ext: "mov") { p in videoPath = p; group.leave() }
                    group.notify(queue: .global()) {
                        guard let imagePath = imagePath, let videoPath = videoPath else {
                            self.extractImage(result: result, completion: completion)
                            return
                        }
                        completion([
                            "imagePath": imagePath,
                            "videoPath": videoPath,
                            "isLive": true,
                        ])
                    }
                    return
                }
            }
        }

        // Not a live photo (or no paired video): return the still only.
        extractImage(result: result, completion: completion)
    }

    private func extractImage(result: PHPickerResult, completion: @escaping ([String: Any]?) -> Void) {
        extractImagePath(result: result) { path in
            guard let path = path else {
                completion(nil)
                return
            }
            completion([
                "imagePath": path,
                "isLive": false,
            ])
        }
    }

    private func extractImagePath(result: PHPickerResult, completion: @escaping (String?) -> Void) {
        let provider = result.itemProvider
        if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                guard let image = object as? UIImage,
                      let data = image.jpegData(compressionQuality: 0.92) else {
                    completion(nil)
                    return
                }
                let dest = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString + ".jpg")
                do {
                    try data.write(to: dest, options: .atomic)
                    completion(dest.path)
                } catch {
                    completion(nil)
                }
            }
            return
        }

        provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, _ in
            guard let data = data else { completion(nil); return }
            let dest = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString + ".jpg")
            do {
                try data.write(to: dest, options: .atomic)
                completion(dest.path)
            } catch {
                completion(nil)
            }
        }
    }

    private func copyResource(_ resource: PHAssetResource, ext: String, completion: @escaping (String?) -> Void) {
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + "." + ext)
        let options = PHAssetResourceRequestOptions()
        options.isNetworkAccessAllowed = true
        PHAssetResourceManager.default().writeData(for: resource, toFile: dest, options: options) { error in
            completion(error == nil ? dest.path : nil)
        }
    }
}
