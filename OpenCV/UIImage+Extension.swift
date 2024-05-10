//
//  UIImage+Extension.swift
//  OpenCV
//
//  Created by zack on 2024/5/10.
//

import Foundation

extension UIImage {

    var outline: UIImage? {

        let image = OutlineManager.cannyInputImage(self, value: 10)
        return image
    }
}
