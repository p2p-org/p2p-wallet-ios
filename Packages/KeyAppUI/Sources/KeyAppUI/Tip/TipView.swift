import UIKit
import BEPureLayout

final class TipView: BECompositionView {

    // MARK: - Variables

    var nextButtonHandler: (() -> Void)?
    var skipButtonHandler: (() -> Void)?

    private let container = BERef<UIView>()
    private let textLabel = BERef<UILabel>()
    private let countLabel = BERef<UILabel>()
    private let nextButton = BERef<TextButton>()
    private let skipButton = BERef<TextButton>()
    private var pointerLayer: CAShapeLayer?

    private let content: TipContent
    private let appearance: TipAppearance

    // MARK: - Inits

    public init(
        content: TipContent,
        theme: TipTheme,
        pointerPosition: TipPointerPosition
    ) {
        self.content = content
        self.appearance = TipAppearance(
            theme: theme,
            pointerPosition: pointerPosition,
            pointerInset: Constants.pointerSize.height
        )

        super.init()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overriden

    override func layoutSubviews() {
        super.layoutSubviews()
        drawPointerIfNeeded()
        drawShadow()
    }

    override public func build() -> UIView {
        BEContainer {
            BEVStack(spacing: 20) {
                BEHStack(spacing: .zero, alignment: .top) {
                    UILabel(
                        text: content.text,
                        textColor: appearance.textColor,
                        numberOfLines: .zero
                    )
                    .bind(textLabel)
                    .setup { view in
                        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
                        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                    }

                    UILabel(
                        text: "\(content.currentNumber)/\(content.count)",
                        textColor: appearance.countColor
                    )
                    .bind(countLabel)
                    .setup { view in
                        view.setContentHuggingPriority(.required, for: .horizontal)
                        view.setContentCompressionResistancePriority(.required, for: .horizontal)
                    }
                }

                BEHStack(spacing: 8) {
                    TextButton(
                        title: content.nextButtonText,
                        style: appearance.nextButtonStyle,
                        size: .small
                    )
                    .bind(nextButton)
                    .setup { view in
                        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
                        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
                    }
                    .onPressed { [weak self] _ in self?.nextButtonHandler?() }

                    TextButton(
                        title: content.skipButtonText,
                        style: appearance.skipButtonStyle,
                        size: .small
                    )
                    .bind(skipButton)
                    .setup { view in
                        view.setContentHuggingPriority(.required, for: .horizontal)
                        view.setContentCompressionResistancePriority(.required, for: .horizontal)
                    }
                    .onPressed { [weak self] _ in self?.skipButtonHandler?() }
                }
            }
            .margin(UIEdgeInsets(all: 12))
        }.backgroundColor(color: appearance.backgroundColor)
        .box(cornerRadius: Constants.cornerRadius)
        .bind(container)
        .margin(appearance.pointerMarginSide)
    }

    // MARK: - Private

    private func drawPointerIfNeeded() {
        guard pointerLayer == nil else { return }

        let size = Constants.pointerSize
        let margin = Constants.pointerMargin
        let curveYPoint = size.height + 2
        let shapeLayerPosition: CGPoint

        let trianglePath = UIBezierPath()
        trianglePath.lineWidth = 1
        trianglePath.move(to: CGPoint.zero)

        switch appearance.pointerPosition {
        case .topLeft:
            trianglePath.addCurve(to: CGPoint(x: size.width, y: .zero), controlPoint1: CGPoint(x: size.width / 2, y: -curveYPoint), controlPoint2: CGPoint(x: size.width / 2, y: -curveYPoint))
            shapeLayerPosition = CGPoint(x: bounds.minX + margin, y: bounds.minY + size.height)

        case .topCenter:
            trianglePath.addCurve(to: CGPoint(x: size.width, y: .zero), controlPoint1: CGPoint(x: size.width / 2, y: -curveYPoint), controlPoint2: CGPoint(x: size.width / 2, y: -curveYPoint))
            shapeLayerPosition = CGPoint(x: bounds.maxX / 2 - size.width, y: bounds.minY + size.height)

        case .topRight:
            trianglePath.addCurve(to: CGPoint(x: size.width, y: .zero), controlPoint1: CGPoint(x: size.width / 2, y: -curveYPoint), controlPoint2: CGPoint(x: size.width / 2, y: -curveYPoint))
            shapeLayerPosition = CGPoint(x: bounds.maxX - margin - size.width, y: bounds.minY + size.height)

        case .rightTop:
            trianglePath.addCurve(to: CGPoint(x: .zero, y: size.width), controlPoint1: CGPoint(x: curveYPoint, y: size.width / 2), controlPoint2: CGPoint(x: curveYPoint, y: size.width / 2))

            shapeLayerPosition = CGPoint(x: bounds.maxX - size.height, y: bounds.minY + margin - size.width / 2)

        case .rightCenter:
            trianglePath.addCurve(to: CGPoint(x: .zero, y: size.width), controlPoint1: CGPoint(x: curveYPoint, y: size.width / 2), controlPoint2: CGPoint(x: curveYPoint, y: size.width / 2))

            shapeLayerPosition = CGPoint(x: bounds.maxX - size.height, y: bounds.maxY / 2 - size.width / 2)

        case .rightBottom:
            trianglePath.addCurve(to: CGPoint(x: .zero, y: size.width), controlPoint1: CGPoint(x: curveYPoint, y: size.width / 2), controlPoint2: CGPoint(x: curveYPoint, y: size.width / 2))

            shapeLayerPosition = CGPoint(x: bounds.maxX - size.height, y: bounds.maxY - margin - size.width / 2)

        case .bottomLeft:
            trianglePath.addCurve(to: CGPoint(x: size.width, y: .zero), controlPoint1: CGPoint(x: size.width / 2, y: curveYPoint), controlPoint2: CGPoint(x: size.width / 2, y: curveYPoint))

            shapeLayerPosition = CGPoint(x: bounds.minX + margin, y: bounds.maxY - size.height)

        case .bottomCenter:
            trianglePath.addCurve(to: CGPoint(x: size.width, y: .zero), controlPoint1: CGPoint(x: size.width / 2, y: curveYPoint), controlPoint2: CGPoint(x: size.width / 2, y: curveYPoint))

            shapeLayerPosition = CGPoint(x: bounds.maxX / 2 - size.width / 2, y: bounds.maxY -  size.height)

        case .bottomRight:
            trianglePath.addCurve(to: CGPoint(x: size.width, y: .zero), controlPoint1: CGPoint(x: size.width / 2, y: curveYPoint), controlPoint2: CGPoint(x: size.width / 2, y: curveYPoint))

            shapeLayerPosition = CGPoint(x: bounds.maxX - margin, y: bounds.maxY - size.height)

        case .leftTop:
            trianglePath.addCurve(to: CGPoint(x: .zero, y: size.width), controlPoint1: CGPoint(x: -curveYPoint, y: size.width / 2), controlPoint2: CGPoint(x: -curveYPoint, y: size.width / 2))

            shapeLayerPosition = CGPoint(x: bounds.minX + size.height, y: bounds.minY + margin)
            
        case .leftCenter:
            trianglePath.addCurve(to: CGPoint(x: .zero, y: size.width), controlPoint1: CGPoint(x: -curveYPoint, y: size.width / 2), controlPoint2: CGPoint(x: -curveYPoint, y: size.width / 2))

            shapeLayerPosition = CGPoint(x: bounds.minX + size.height, y: bounds.maxY / 2 - size.width)

        case .leftBottom:
            trianglePath.addCurve(to: CGPoint(x: .zero, y: size.width), controlPoint1: CGPoint(x: -curveYPoint, y: size.width / 2), controlPoint2: CGPoint(x: -curveYPoint, y: size.width / 2))

            shapeLayerPosition = CGPoint(x: bounds.minX + size.height, y: bounds.maxY - margin)

        default:
            shapeLayerPosition = .zero
        }

        trianglePath.close()

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = trianglePath.cgPath
        shapeLayer.fillColor = appearance.backgroundColor.cgColor
        shapeLayer.position = shapeLayerPosition

        layer.addSublayer(shapeLayer)
        self.pointerLayer = shapeLayer
    }

    private func drawShadow() {
        layer.shadowColor = UIColor.black.withAlphaComponent(0.08).cgColor
        layer.shadowOpacity = 1.0
        layer.shadowOffset = .init(width: 0, height: 8)
        layer.shadowRadius = 16
    }
}

// MARK: - Constants
extension TipView {
    private enum Constants {
        static let pointerSize = CGSize(width: 12, height: 8)
        static let pointerMargin: CGFloat = 24
        static let cornerRadius: CGFloat = 16
    }
}
