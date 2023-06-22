//
//  ConnectionErrorVC.swift
//  p2p_wallet
//
//  Created by Chung Tran on 05/05/2021.
//
import Foundation

extension UIView {
    @discardableResult
    func showConnectionErrorView(refreshAction: (() -> Void)?) -> ConnectionErrorView {
        hideConnectionErrorView()

        let errorView = ConnectionErrorView()
        errorView.refreshAction = refreshAction
        addSubview(errorView)
        errorView.autoPinEdge(toSuperviewEdge: .top)
        errorView.autoPinEdge(toSuperviewEdge: .leading)
        errorView.autoPinEdge(toSuperviewEdge: .trailing)
        errorView.autoPinEdge(toSuperviewSafeArea: .bottom)
        return errorView
    }

    func hideConnectionErrorView() {
        subviews.first(where: { $0 is ConnectionErrorView })?.removeFromSuperview()
    }
}

class ConnectionErrorView: BEView {
    // MARK: - Subviews

    private lazy var refreshButton = WLButton.stepButton(
        enabledColor: .eff3ff,
        textColor: .h5887ff,
        label: L10n.refresh
    )
        .onTap { [unowned self] in
            refreshAction?()
        }

    private lazy var contentView: UIView = {
        let view = UIView(backgroundColor: .white)
        let imageView = UIImageView(width: 65, height: 65, image: UIImage(resource: .connectionError))
        let stackView = UIStackView(axis: .vertical, alignment: .fill, distribution: .fill) {
            imageView.centeredHorizontallyView

            BEStackViewSpacing(30)

            UILabel(text: L10n.connectionProblem, textSize: 21, weight: .semibold, textAlignment: .center)

            BEStackViewSpacing(5)

            UILabel(
                text: L10n.yourConnectionToTheInternetHasBeenInterrupted,
                textSize: 17,
                weight: .medium,
                textColor: .textSecondary,
                numberOfLines: 0,
                textAlignment: .center
            )

            BEStackViewSpacing(66)

            refreshButton
        }

        view.addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(x: 20, y: 30))

        // separator
        let separator = UIView.defaultSeparator()
        view.addSubview(separator)
        separator.autoPinEdge(toSuperviewEdge: .leading)
        separator.autoPinEdge(toSuperviewEdge: .trailing)
        separator.autoAlignAxis(.horizontal, toSameAxisOf: imageView)
        return view
    }()

    var refreshAction: (() -> Void)?
    
    // MARK: - Methods

    override func commonInit() {
        super.commonInit()
        // dimming view
        let dimmingView = UIView(backgroundColor: .black.withAlphaComponent(0.5))
        addSubview(dimmingView)
        dimmingView.autoPinEdgesToSuperviewEdges()

        // content view
        addSubview(contentView)
        contentView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.roundCorners([.topLeft, .topRight], radius: 20)
    }
}

class WLButton: UIButton {
    enum StepButtonType: Equatable {
        case black, sub, blue, gray, white
        var backgroundColor: UIColor {
            switch self {
            case .black:
                return .blackButtonBackground
            case .sub:
                return .h2b2b2b
            case .blue:
                return .h5887ff
            case .gray:
                return .grayPanel
            case .white:
                return .white
            }
        }
        
        var disabledColor: UIColor? {
            switch self {
            case .blue:
                return .a3a5ba.onDarkMode(.h404040)
            default:
                return nil
            }
        }
        
        var textColor: UIColor {
            switch self {
            case .gray:
                return .textBlack
            case .sub, .blue, .black:
                return .white
            case .white:
                return .h5887ff
            }
        }
    }
    
    static func stepButton(
        type: StepButtonType,
        label: String?,
        labelFont: UIFont = UIFont.systemFont(ofSize: 17, weight: .semibold),
        labelColor: UIColor? = nil
    ) -> WLButton {
        let button = WLButton(
            backgroundColor: type.backgroundColor,
            cornerRadius: 15,
            label: label,
            labelFont: labelFont,
            textColor: labelColor != nil ? labelColor! : type.textColor
        )
        button.enabledColor = type.backgroundColor
        button.disabledColor = type.disabledColor
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        button.contentEdgeInsets = .init(x: 15, y: 20)
        return button
    }
    
    static func stepButton(enabledColor: UIColor, disabledColor: UIColor? = nil, textColor: UIColor,
                           label: String?) -> WLButton
    {
        let button = WLButton(
            backgroundColor: enabledColor,
            cornerRadius: 15,
            label: label,
            labelFont: .systemFont(ofSize: 17, weight: .semibold),
            textColor: textColor
        )
        button.enabledColor = enabledColor
        button.disabledColor = disabledColor
        
        button.titleLabel?.lineBreakMode = .byWordWrapping
        button.titleLabel?.textAlignment = .center
        button.contentEdgeInsets = .init(x: 15, y: 20)
        return button
    }
    
    var enabledColor: UIColor?
    var disabledColor: UIColor?
    
    override var isEnabled: Bool {
        didSet {
            if let enabledColor = enabledColor, let disabledColor = disabledColor {
                backgroundColor = isEnabled ? enabledColor : disabledColor
            } else {
                isEnabled ? (alpha = 1) : (alpha = 0.5)
            }
        }
    }
}
