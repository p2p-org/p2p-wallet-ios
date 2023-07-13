import CoreImage.CIFilterBuiltins
import Foundation
import Kingfisher
import UIKit

extension UIImageView {
    static let qrCodeCache = NSCache<NSString, UIImage>()

    func cancelPreviousTask() {
        kf.cancelDownloadTask() // first, cancel currenct download task
        kf.setImage(with: URL(string: "")) // second, prevent kingfisher from setting previous image
    }

    func setImage(
        urlString: String?,
        placeholder: UIImage? = nil,
        completionHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil
    ) {
        let placeholder = placeholder ?? UIColor.gray.image(frame.size)

        guard let urlString = urlString, let url = URL(string: urlString) else {
            image = placeholder
            return
        }
        kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [.processor(ImgProcessor())],
            completionHandler: completionHandler
        )
    }
}

private struct ImgProcessor: ImageProcessor {
    var identifier: String = "com.appidentifier.webpprocessor"
    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        if let image = DefaultImageProcessor.default.process(item: item, options: options) {
            return image
        }

        switch item {
        case let .image(image):
            debugPrint("already an image")
            return image
        case .data:
            return nil
//            let imsvg = SVGKImage(data: data)
//            return imsvg?.uiImage ?? DefaultImageProcessor.default.process(item: item, options: options)
        }
    }
}
