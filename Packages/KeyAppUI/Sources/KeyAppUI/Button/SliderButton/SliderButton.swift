import UIKit
import SwiftUI
import BEPureLayout

public struct SliderButtonView: UIViewRepresentable {
    let title: String
    let image: UIImage
    let style: SliderButton.Style
    @Binding var isOn: Bool

    public init(title: String, image: UIImage, style: SliderButton.Style, isOn: Binding<Bool>) {
        self.title = title
        self.image = image
        self.style = style
        self._isOn = isOn
    }

    public func makeUIView(context: Context) -> SliderButton {
        SliderButton(image: image, title: title, style: style)
            .onChanged { self.isOn = $0 }
    }

    public func updateUIView(_ uiView: SliderButton, context: Context) {
        uiView.title = title
        uiView.image = image
        uiView.set(isOn: isOn)
    }
}

public final class SliderButton: BEView {

    // MARK: - Public variables
    public var isOn: Bool = false
    public var onChanged: ((Bool) -> Void)?

    public var image: UIImage {
        didSet {
            imageView.image = image
        }
    }

    public var title: String? {
        didSet {
            titleView.text = title
        }
    }

    @discardableResult
    public func onChanged(_ callback: ((Bool) -> Void)?) -> Self {
        onChanged = callback
        return self
    }

    // MARK: - Private variables

    private var initialPoint: CGPoint = .zero
    private let containerMaskLayer = CAShapeLayer()
    private let shimmerLayer = CAGradientLayer()
    private let gradientLayer = CAGradientLayer()

    private let imageView = UIImageView(forAutoLayout: ())
    private let titleView = BERef<UILabel>()
    private var progressTitleView: UILabel?
    private let container = BERef<UIView>()
    private let imageControl: UIView = UIView()

    private let theme: SliderButtonAppearance

    // MARK: - Init

    public init(image: UIImage, title: String? = nil, theme: SliderButtonAppearance) {
        self.image = image
        self.title = title
        self.theme = theme
        super.init(frame: .zero)
    }

    public override func commonInit() {
        super.commonInit()
        let child = build()
        addSubview(child)
        child.autoPinEdgesToSuperviewEdges()
        setupImageControl()
    }

    // MARK: - Public

    public func set(isOn: Bool) {
        guard isOn != self.isOn else { return }
        animateGradientAndControl(moveToLeft: !isOn)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        addImageControl()
        addMaskLayer()
        addShimmerLayer()
        addProgressLabelIfNeeded()
    }

    // MARK: - Private

    private func build() -> UIView {
        SliderContainer {
            UILabel(text: title, font: theme.font, textColor: theme.titleColor, textAlignment: .center)
                .bind(titleView)
        }
        .bind(container)
        .backgroundColor(color: theme.backgroundColor)
        .frame(height: Constants.imageControlSize.height + Constants.padding * 2)
    }

    private func addImageControl() {
        guard let frame = container.view?.frame.size, frame.width > .zero, container.view?.subviews.contains(imageControl) == false else { return }

        container.view?.addSubview(imageControl)
        imageControl.frame = CGRect(origin: Constants.position, size: Constants.imageControlSize)
    }

    private func addMaskLayer() {
        guard self.bounds != containerMaskLayer.bounds else { return }
        let roundPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: 32)
        containerMaskLayer.path = roundPath.cgPath
        self.layer.mask = containerMaskLayer
    }

    private func setupImageControl() {
        imageControl.layer.cornerRadius = Constants.imageControlSize.width / 2
        imageControl.backgroundColor = theme.iconBackgroundColor
        imageControl.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(panned(_:))))
        imageControl.layer.anchorPoint = .zero

        imageView.image = image
        imageView.contentMode = .center
        imageView.tintColor = theme.iconColor
        imageControl.addSubview(imageView)
        imageView.autoCenterInSuperview()
    }

    // MARK: - Shimmer

    private func addShimmerLayer() {
        guard let sublayers = imageControl.layer.sublayers, !sublayers.contains(shimmerLayer) else { return }

        func color(alpha: CGFloat) -> CGColor {
            Asset.Colors.snow.color.withAlphaComponent(alpha).cgColor
        }

        shimmerLayer.cornerRadius = imageControl.bounds.width / 2
        shimmerLayer.frame = imageControl.bounds
        shimmerLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
        shimmerLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        shimmerLayer.colors = [color(alpha: 0), color(alpha: 0.5), color(alpha: 0)]
        shimmerLayer.locations = [-1.0, -0.5, 0.0]
        imageControl.layer.addSublayer(shimmerLayer)

        animateShimmer()
    }

    private func animateShimmer() {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1
        animation.fillMode = .forwards

        let group = CAAnimationGroup()
        group.animations = [animation]
        group.duration = 1.5
        group.repeatCount = .infinity
        shimmerLayer.add(group, forKey: "shimmer")
    }

    // This label is needed if the filled color is not gradient
    private func addProgressLabelIfNeeded() {
        guard !theme.isGradient && progressTitleView?.superview == nil else { return }
        let label = UILabel(frame: .zero)
        label.lineBreakMode = .byClipping
        label.text = title
        label.font = theme.font
        label.textColor = theme.progressColor
        container.view?.addSubview(label)
        progressTitleView = label
    }

    // MARK: - Pan Gesture

    @objc private func panned(_ sender: UIPanGestureRecognizer) {
        guard let rootView = container.view else { return }
        let translation = sender.translation(in: imageControl)
        let controlX = translation.x
        let controlCenterX = controlX > 0 ? controlX + Constants.imageControlSize.width/2 :  controlX - Constants.imageControlSize.width / 2

        let moveToLeft = (controlX > 0 && controlCenterX < rootView.center.x) || (controlX < 0 && abs(controlCenterX) > rootView.center.x)

        switch sender.state {
        case .began:
            initialPoint = imageControl.frame.origin

        case .changed:
            if isOn && (controlX >= 0 || imageControl.frame.minX <= Constants.padding) {
                return
            }
            else if !isOn && (controlX <= 0 || imageControl.frame.maxX >= rootView.frame.width - Constants.padding) {
                return
            }
            else {
                changeGradientAndControl(translation: translation)
            }

        case .ended, .cancelled:
            if isOn && controlX >= 0 {
                animateGradientAndControl(moveToLeft: false)
            }
            else if !isOn && controlX <= 0 {
                animateGradientAndControl(moveToLeft: true)
            }
            else {
                animateGradientAndControl(moveToLeft: moveToLeft)
            }

        default:
            break
        }
    }

    // Change control with gradient while pan gesture is going
    private func changeGradientAndControl(translation: CGPoint) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        imageControl.frame.origin = CGPoint(x: initialPoint.x + translation.x, y: initialPoint.y)
        gradientLayer.frame = CGRect(
            origin: Constants.position,
            size: CGSize(width: imageControl.frame.maxX - Constants.padding * 2, height: Constants.imageControlSize.height)
        )
        fillProgressLabelIfNeeded(translation: translation)
        CATransaction.commit()
        drawGradientLayerIfNeeded()
    }

    // Animate progressLabel in solid themes
    private func fillProgressLabelIfNeeded(translation: CGPoint) {
        guard let progressTitleView = progressTitleView, let titleView = titleView.view else { return }

        if translation.x >= titleView.frame.minX {
            var newWidth = translation.x - titleView.frame.minX
            newWidth = newWidth >= titleView.frame.width ? titleView.frame.width : newWidth

            let newSize = CGSize(width: newWidth, height: titleView.frame.height)
            progressTitleView.bounds = CGRect(origin: .zero, size: newSize)
            progressTitleView.frame = CGRect(origin: titleView.frame.origin, size: newSize)
        } else if translation.x < 0 && abs(translation.x) + Constants.imageControlSize.width > (container.frame.maxX - titleView.frame.maxX) {
            var newWidth = titleView.frame.maxX + translation.x - Constants.imageControlSize.width
            newWidth = newWidth < 0 ? 0 : newWidth

            let newSize = CGSize(width: newWidth, height: titleView.frame.height)
            progressTitleView.bounds = CGRect(origin: .zero, size: newSize)
            progressTitleView.frame = CGRect(origin: titleView.frame.origin, size: newSize)
        }
    }

    // Animate control move after pan gesture is ended or cancelled
    private func animateGradientAndControl(moveToLeft: Bool) {
        guard let containerView = container.view else { return }

        let padding = Constants.padding

        let newGradientLayerWidth = moveToLeft ? Constants.imageControlSize.width : containerView.frame.maxX - padding * 2
        let bounds = CGRect(origin: .zero, size: CGSize(width: newGradientLayerWidth, height: Constants.imageControlSize.height))

        let newImageControlPosition = moveToLeft ? Constants.position : CGPoint(x: containerView.frame.maxX - imageControl.frame.width - padding, y: padding)

        CATransaction.begin()
        CATransaction.setCompletionBlock { self.updateIfNeeded() }
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
        CATransaction.setAnimationDuration(Constants.duration)

        let gradientLayerAnimation = CABasicAnimation(keyPath: "bounds")
        gradientLayerAnimation.fromValue = gradientLayer.bounds
        gradientLayerAnimation.toValue = bounds
        gradientLayer.bounds = bounds
        gradientLayer.add(gradientLayerAnimation, forKey: "bounds")
        gradientLayer.frame = CGRect(origin: Constants.position, size: bounds.size)
        gradientLayerAnimation.isRemovedOnCompletion = false

        let imageControlAnimation = CABasicAnimation(keyPath: "position")
        imageControlAnimation.fromValue = imageControl.layer.position
        imageControlAnimation.toValue = newImageControlPosition
        imageControl.layer.position = newImageControlPosition
        imageControl.layer.add(imageControlAnimation, forKey: "position")
        imageControlAnimation.isRemovedOnCompletion = false

        animateProgressLabelIfNeeded(moveToLeft: moveToLeft)

        CATransaction.commit()
    }

    private func animateProgressLabelIfNeeded(moveToLeft: Bool) {
        guard let progressTitleView = progressTitleView, let titleView = titleView.view else { return }

        let isLeftMoveNotEnded = moveToLeft && progressTitleView.frame.width > 0
        let isRightMoveNotEnded = !moveToLeft && progressTitleView.frame.width < titleView.frame.width

        guard isLeftMoveNotEnded || isRightMoveNotEnded else { return }

        let newLabelBounds = CGRect(origin: .zero, size: CGSize(width: moveToLeft ? 0 : titleView.frame.width, height: titleView.frame.height))

        let labelAnimation = CABasicAnimation(keyPath: "bounds")
        labelAnimation.fromValue = progressTitleView.bounds
        labelAnimation.toValue = newLabelBounds
        progressTitleView.bounds = newLabelBounds
        progressTitleView.layer.add(labelAnimation, forKey: "bounds")
        progressTitleView.frame = CGRect(origin: titleView.frame.origin, size: newLabelBounds.size)

        labelAnimation.isRemovedOnCompletion = false
    }

    // Update isOn value if control position was changed from left to right or right to left
    private func updateIfNeeded() {
        let isLeft = imageControl.layer.position == Constants.position
        guard isOn == isLeft else { return }
        isOn = !isLeft
        onChanged?(!isLeft)
        vibrate()
    }

    // MARK: - Gradient layer

    private func drawGradientLayerIfNeeded() {
        guard let sublayers = container.view?.layer.sublayers, !sublayers.contains(gradientLayer) else { return }

        container.view?.layer.insertSublayer(
            gradientLayer,
            below: container.view?.layer.sublayers?.first(where: { $0 == imageControl.layer.superlayer })
        )
        container.view?.sendSubviewToBack(titleView.view!)

        let size = CGSize(width: imageControl.frame.maxX - Constants.padding * 2, height: Constants.imageControlSize.height)
        gradientLayer.frame = CGRect(origin: Constants.position, size: size)
        gradientLayer.anchorPoint = .zero
        gradientLayer.masksToBounds = true
        if theme.isGradient {
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 1.0)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
            gradientLayer.locations = [0.0, 1.0]
            gradientLayer.colors = [Asset.Colors.lime.color.cgColor, Asset.Colors.lime.color.withAlphaComponent(0).cgColor]
        } else {
            gradientLayer.backgroundColor = Asset.Colors.lime.color.cgColor
        }
        gradientLayer.cornerRadius = size.height / 2

    }

    private func vibrate() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

private enum Constants {
    static let imageControlSize = CGSize(width: 48, height: 48)
    static let padding: CGFloat = 4
    static let position = CGPoint(x: Constants.padding, y: Constants.padding)
    static let duration = 0.5
}

private class SliderContainer: BEView {
    private let child: UIView

    required public init(@BEViewBuilder builder: Builder) {
        child = builder().build()
        super.init(frame: .zero)
    }

    final public override func commonInit() {
        super.commonInit()
        super.addSubview(child)
        child.autoCenterInSuperview()
    }
}
