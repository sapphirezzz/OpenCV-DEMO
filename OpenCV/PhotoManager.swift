//
//  PhotoManager.swift
//  OpenCV
//
//  Created by zack on 2024/5/10.
//

import Foundation
import PhotosUI

class PhotoManager {

    static let shared = PhotoManager()
    private init() {}
    
    enum PhotoPickResult {

        case image(UIImage)
        case cancel
        case error(Error?)
    }
    
    private var finishPickingHandler: ((PhotoPickResult) -> Void)?

    /// 选择照片
    func selectPhoto(onController controller: UIViewController, finishPickingHandler: ((PhotoPickResult) -> Void)?) {

        self.finishPickingHandler = finishPickingHandler
        
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized, .limited:
            showPhotoPickController(onController: controller)
        case .denied, .restricted:
            showAuthorizationView()
        case .notDetermined:

            PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .authorized, .limited:
                        self?.showPhotoPickController(onController: controller)
                    case .notDetermined, .restricted, .denied:
                        self?.showAuthorizationView()
                    @unknown default:
                        self?.showAuthorizationView()
                    }
                }
            })
        @unknown default:
            showAuthorizationView()
        }
    }
    
    private func showPhotoPickController(onController controller: UIViewController) {

        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .automatic
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.modalPresentationStyle = .fullScreen
        picker.delegate = self
        controller.present(picker, animated: true, completion: nil)
    }
    
    func showAuthorizationView() {
        
    }
}

// MARK: - PHPickerViewControllerDelegate
extension PhotoManager: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        picker.dismiss(animated: true)
        
        guard let result = results.first else {
            DispatchQueue.main.async {
                self.finishPickingHandler?(PhotoPickResult.cancel)
            }
            return
        }

        if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                
                guard let self = self else { return }
                
                DispatchQueue.main.async {

                    guard let image = image as? UIImage else {
                        self.finishPickingHandler?(PhotoPickResult.error(error))
                        return
                    }
                    self.finishPickingHandler?(PhotoPickResult.image(image))
                }
            }
        } else {
            /// https://www.jianshu.com/p/744822aeaaac
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier,
                                                       completionHandler: { [weak self] url, error  in
                
                guard let self = self else {
                    return
                }
                
                DispatchQueue.main.async {
                    
                    do {
                        if let url = url {
                            let imageData = try Data(contentsOf: url)
                            if let image = UIImage(data: imageData) {
                                self.finishPickingHandler?(PhotoPickResult.image(image))
                            } else {
                                self.finishPickingHandler?(PhotoPickResult.error(error))
                            }
                        } else {
                            self.finishPickingHandler?(PhotoPickResult.error(error))
                        }
                    } catch let error {
                        self.finishPickingHandler?(PhotoPickResult.error(error))
                    }
                }
            })
        }
    }
}
