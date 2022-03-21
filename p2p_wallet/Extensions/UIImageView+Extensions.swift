//
//  UIImageView+Extensions.swift
//  p2p_wallet
//
//  Created by Chung Tran on 13/11/2020.
//

import CoreImage.CIFilterBuiltins
import Foundation
import Kingfisher

extension UIImageView {
    static let qrCodeCache = NSCache<NSString, UIImage>()

    func cancelPreviousTask() {
        kf.cancelDownloadTask() // first, cancel currenct download task
        kf.setImage(with: URL(string: "")) // second, prevent kingfisher from setting previous image
    }

    func setImage(urlString: String?, placeholder: UIImage? = nil) {
        let placeholder = placeholder ?? UIColor.gray.image(frame.size)

        guard let urlString = urlString, let url = URL(string: urlString) else {
            image = placeholder
            return
        }
        kf.setImage(with: url, placeholder: placeholder, options: [.processor(ImgProcessor())])
    }

    func with(urlString: String?) -> Self {
        setImage(urlString: urlString)
        return self
    }

    static var walletIntro: UIImageView {
        UIImageView(width: 90, height: 90, image: .walletIntro)
    }
}

private struct ImgProcessor: ImageProcessor {
    public var identifier: String = "com.appidentifier.webpprocessor"
    public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        if let image = DefaultImageProcessor.default.process(item: item, options: options) {
            return image
        }

        switch item {
        case let .image(image):
            debugPrint("already an image")
            return image
        case let .data(data):
            return nil
//            let imsvg = SVGKImage(data: data)
//            return imsvg?.uiImage ?? DefaultImageProcessor.default.process(item: item, options: options)
        }
    }
}
