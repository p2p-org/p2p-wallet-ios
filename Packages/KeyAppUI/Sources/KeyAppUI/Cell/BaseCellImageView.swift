import Foundation
import UIKit
import BEPureLayout

public struct BaseCellImageViewItem {
    public var image: UIImage
    public var imageSize: CGSize?
    public var statusImage: UIImage?
    public var secondImage: UIImage?
    
    public init(
        image: UIImage,
        imageSize: CGSize? = nil,
        statusImage: UIImage? = nil,
        secondImage: UIImage? = nil
    ) {
        self.image = image
        self.imageSize = imageSize
        self.statusImage = statusImage
        self.secondImage = secondImage
    }
}

public class BaseCellImageView: BECompositionView {
    
    private(set) var defaultOneImageSize: CGSize = .init(width: 48, height: 48)
    private(set) var defaultStatusImageSize: CGSize = .init(width: 16, height: 16)
    private(set) var defaultTwoImageSize: CGSize = .init(width: 31, height: 31)
    
    public enum Style {
        case oneImage(image: UIImage, size: CGSize?, statusImage: UIImage?)
        /// size is fixed to 30x30 in this case
        case twoImages(topImage: UIImage, bottomImage: UIImage)
    }
    
    private(set) var style: BaseCellImageView.Style
    
    // MARK: - Init
    
    public init(style: BaseCellImageView.Style) {
        self.style = style
        super.init(frame: .zero)
    }
    
    public convenience init(_ item: BaseCellImageViewItem) {
        var style: Style
        if let secondImage = item.secondImage {
            style = .twoImages(topImage: item.image, bottomImage: secondImage)
        } else {
            style = .oneImage(image: item.image, size: item.imageSize, statusImage: item.statusImage)
        }
        self.init(style: style)
    }
    
    // MARK: -
    
    public override func build() -> UIView {
        view(style: self.style)
    }
    
    private func view(style: Style) -> UIView {
        switch style {
        case .oneImage(let image, let size, let statusImage):
            return oneImage(image: image, size: size, statusImage: statusImage)
        case .twoImages(let topImage, let bottomImage):
            return twoImage(top: topImage, bottom: bottomImage)
        }
    }
    
    private func oneImage(image: UIImage, size: CGSize? = nil, statusImage: UIImage? = nil) -> UIView {
        BEZStack {
            BEZStackPosition(mode: .fill) {
                UIImageView(
                    width: size?.width ?? defaultOneImageSize.width,
                    height: size?.height ?? defaultOneImageSize.height,
                    image: image
                ).setup { image in
                    image.heightConstraint?.priority = .defaultHigh
                    if let statusImage = statusImage {
                        let status = UIImageView(
                            width: defaultStatusImageSize.width,
                            height: defaultStatusImageSize.height,
                            image: statusImage
                        )
                        image.addSubview(status)
                        status.autoPinEdge(toSuperviewEdge: .right, withInset: -3)
                        status.autoPinEdge(toSuperviewEdge: .bottom, withInset: -1)
                    }
                }
            }
        }
    }
    
    private func twoImage(top: UIImage, bottom: UIImage) -> UIView {
        BEZStack {
            BEZStackPosition(mode: .pinEdges([.top, .left])) {
                UIImageView(
                    width: defaultTwoImageSize.width,
                    height: defaultTwoImageSize.height,
                    image: top
                ).box(cornerRadius: 9)
            }
            BEZStackPosition(mode: .pinEdges([.right, .bottom])) {
                UIImageView(
                    width: defaultTwoImageSize.width,
                    height: defaultTwoImageSize.height,
                    image: bottom
                ).box(cornerRadius: 9).margin(.init(x: -1, y: -1))
            }
        }
        .frame(width: defaultOneImageSize.width)
//        .centered(.vertical)
//        .frame(width: defaultOneImageSize.width, height: defaultOneImageSize.height)
    }
    
}
