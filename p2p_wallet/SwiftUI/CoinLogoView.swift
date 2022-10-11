import Combine
import SkeletonUI
import SwiftSVG
import SwiftUI

struct CoinLogoView: UIViewRepresentable {
    let size: CGFloat
    let cornerRadius: CGFloat
    let backgroundColor: UIColor?
    let image: UIImage?
    let urlString: String?
    let wrappedByImage: UIImage?
    let placeholder: UIImage?

    init(
        size: CGFloat,
        cornerRadius: CGFloat = 12,
        backgroundColor: UIColor? = nil,
        image: UIImage? = nil,
        urlString: String? = nil,
        wrappedByImage: UIImage? = nil,
        placeholder: UIImage? = nil
    ) {
        self.size = size
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.image = image
        self.urlString = urlString
        self.wrappedByImage = wrappedByImage
        self.placeholder = placeholder
    }

    func makeUIView(context _: Context) -> CoinLogoViewWrapper {
        CoinLogoViewWrapper(
            size: size,
            cornerRadius: cornerRadius,
            backgroundColor: backgroundColor,
            image: image,
            urlString: urlString,
            wrappedByImage: wrappedByImage,
            placeholder: placeholder
        )
    }

    func updateUIView(_: CoinLogoViewWrapper, context _: Context) {}

    typealias UIViewType = CoinLogoViewWrapper
}

class CoinLogoViewWrapper: BEView {
    static var cachedJazziconSeeds = [String: UInt32]()

    // MARK: - Properties

    private let size: CGFloat

    // MARK: - Subviews

    lazy var tokenIcon = UIImageView(tintColor: .textBlack)
    lazy var wrappingTokenIcon = UIImageView(width: 16, height: 16, cornerRadius: 4)
        .border(width: 1, color: .h464646)
    lazy var wrappingView: BERoundedCornerShadowView = {
        let view = BERoundedCornerShadowView(
            shadowColor: UIColor.textWhite.withAlphaComponent(0.25),
            radius: 2,
            offset: CGSize(width: 0, height: 2),
            opacity: 1,
            cornerRadius: 4
        )

        view.addSubview(wrappingTokenIcon)
        wrappingTokenIcon.autoPinEdgesToSuperviewEdges()

        return view
    }()

    // MARK: - Initializer

    init(
        size: CGFloat,
        cornerRadius: CGFloat = 12,
        backgroundColor: UIColor? = nil,
        image: UIImage?,
        urlString: String?,
        wrappedByImage: UIImage? = nil,
        placeholder: UIImage? = nil
    ) {
        self.size = size
        super.init(frame: .zero)
        configureForAutoLayout()
        autoSetDimensions(to: .init(width: size, height: size))

        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true

        self.backgroundColor = backgroundColor ?? .gray

        setUp(image: image, url: urlString, wrappedByImage: wrappedByImage, placeholder: placeholder)
    }

    override func commonInit() {
        super.commonInit()

        addSubview(tokenIcon)
        tokenIcon.autoPinEdgesToSuperviewEdges()

        addSubview(wrappingView)
        wrappingView.autoPinEdge(toSuperviewEdge: .trailing)
        wrappingView.autoPinEdge(toSuperviewEdge: .bottom)
        wrappingView.alpha = 0 // UNKNOWN: isHidden not working
    }

    func setUp(image: UIImage? = nil, url: String? = nil, wrappedByImage: UIImage? = nil, placeholder: UIImage? = nil) {
        // default
        wrappingView.alpha = 0
        backgroundColor = .clear
        tokenIcon.isHidden = false

        // with token
        if let image = image {
            tokenIcon.image = image
        } else if let url = url {
            tokenIcon.setImage(urlString: url) { [weak self] result in
                switch result {
                case .success:
                    self?.tokenIcon.isHidden = false
                case .failure:
                    self?.tokenIcon.isHidden = true
                }
            }
        } else {
            tokenIcon.image = placeholder
        }

        // wrapped by
        if let wrappedBy = wrappedByImage {
            wrappingView.alpha = 1
            wrappingTokenIcon.image = wrappedBy
        }
    }
}
