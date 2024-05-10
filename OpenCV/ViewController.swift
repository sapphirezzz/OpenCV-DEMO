//
//  ViewController.swift
//  OpenCV
//
//  Created by zack on 2024/5/10.
//

import UIKit
import PhotosUI
import SnapKit

class ViewController: UIViewController {

    private let outlineImageView = UIImageView()
    private let exampleImageView = UIImageView()

    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupUI()
    }
}

// MARK: - UI
private extension ViewController {

    func setupUI() {

        outlineImageView.clipsToBounds = true
        outlineImageView.contentMode = .scaleAspectFill
        view.addSubview(outlineImageView)
        outlineImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let button = UIButton()
        button.backgroundColor = .lightGray
        button.layer.cornerRadius = 25
        button.setImage(UIImage(systemName: "photo.badge.plus.fill"), for: .normal)
        button.addTarget(self, action: #selector(onClickAlbum), for: .touchUpInside)
        view.addSubview(button)
        button.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.width.height.equalTo(50)
        }

        exampleImageView.clipsToBounds = true
        exampleImageView.contentMode = .scaleAspectFill
        view.addSubview(exampleImageView)
        exampleImageView.snp.makeConstraints { make in
            make.leading.equalTo(button)
            make.bottom.equalTo(button.snp.top)
            make.width.height.equalTo(100)
        }
    }
    
    @objc func onClickAlbum() {
        
        PhotoManager.shared.selectPhoto(onController: self) { [weak self] result in
            
            switch result {
                
            case .image(let image):
                self?.exampleImageView.image = image
                self?.produceOutline(withImage: image)
            case .error, .cancel:
                break
            }
        }
    }
    
    func produceOutline(withImage image: UIImage) {
        outlineImageView.image = image.outline
    }
}

// MARK: - 逻辑
private extension ViewController {

    func requestAuthorizationIfNeeded(completionHandler: ((Bool) -> Void)?) {

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            completionHandler?(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { result in
                DispatchQueue.main.async {
                    completionHandler?(result)
                }
            })
        case .denied, .restricted:
            completionHandler?(false)
        @unknown default:
            completionHandler?(false)
        }
    }
}

// MARK: - UINavigationControllerDelegate
extension ViewController: UINavigationControllerDelegate {}
