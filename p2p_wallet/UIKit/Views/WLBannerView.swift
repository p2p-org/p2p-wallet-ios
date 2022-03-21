//
//  WLBannerView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 07/10/2021.
//

import Foundation

class WLBannerView: BEView {
    // MARK: - Properties

    var titleText: String? {
        didSet {
            titleLabel.text = titleText
        }
    }

    var descriptionText: String? {
        didSet {
            descriptionLabel.text = descriptionText
        }
    }

    var closeButtonCompletion: (() -> Void)?

    // MARK: - Subviews

    private lazy var imageLayer: CALayer = {
        let image1 = UIImage.bannerBackground.cgImage
        let layer = CALayer()
        layer.contents = image1
        layer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(a: 1, b: 0, c: 0, d: 3.19, tx: 0, ty: -1.1))
        return layer
    }()

    private lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.colors = [
            UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor,
            UIColor(red: 1, green: 1, blue: 1, alpha: 0).cgColor,
        ]

        layer.locations = [0, 1]
        layer.transform = CATransform3DMakeAffineTransform(CGAffineTransform(a: -0.5, b: 1, c: -1, d: -5.09, tx: 1.5, ty: 2.54))
        return layer
    }()

    private lazy var titleLabel = UILabel(text: L10n.reserveYourP2PUsernameNow, textSize: 15, weight: .medium, textColor: .black, numberOfLines: 0)
    private lazy var descriptionLabel = UILabel(text: L10n.anyTokenCanBeReceivedUsingUsernameRegardlessOfWhetherItIsInYourWalletSList, textSize: 13, textColor: .black, numberOfLines: 0)

    // MARK: - Initializers

    init(title: String? = nil, description: String? = nil) {
        titleText = title
        descriptionText = description
        super.init(frame: .zero)
        configureForAutoLayout()
    }

    override func commonInit() {
        super.commonInit()
        layer.addSublayer(imageLayer)
        layer.addSublayer(gradientLayer)
        layer.cornerRadius = 12
        layer.masksToBounds = true

        let stackView = UIStackView(axis: .horizontal, spacing: 8, alignment: .top, distribution: .fill) {
            UIStackView(axis: .vertical, spacing: 8, alignment: .fill, distribution: .fill) {
                titleLabel
                descriptionLabel
            }
            UIImageView(width: 32, height: 32, image: .closeBanner)
                .onTap(self, action: #selector(closeButtonDidTouch))
        }
        addSubview(stackView)
        stackView.autoPinEdgesToSuperviewEdges(with: .init(top: 18, left: 15, bottom: 29, right: 12))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageLayer.bounds = bounds.insetBy(dx: -20, dy: 0)
        imageLayer.position = center

        gradientLayer.position = center
        gradientLayer.bounds = bounds.insetBy(dx: -0.5 * bounds.size.width, dy: -0.5 * bounds.size.height)

        let points = gradientPoints(size: gradientLayer.bounds.size, cssAngle: 258.88)
        gradientLayer.startPoint = points.start
        gradientLayer.endPoint = points.end
    }

    @objc func closeButtonDidTouch() {
        closeButtonCompletion?()
    }
}

// handy radians
private func radian(degree: Double) -> Double { return degree * Double.pi / 180 }
private func radian(degree: CGFloat) -> CGFloat { return degree * CGFloat(Double.pi / 180) }

private func gradientPoints(size: CGSize, cssAngle: CGFloat) -> (start: CGPoint, end: CGPoint) {
    // default value of gradients from CAGradientLayer
    var start = CGPoint(x: 0.0, y: 1.0)
    var end = CGPoint(x: 0.0, y: 0.0)

    // we must to make normolization the angle (if angle over 360deg)
    let normalizedAngle = cssAngle.truncatingRemainder(dividingBy: 360) // if value lower than 360, truncating return the same
    // special tuple for computation angle and flag, indicating top side angle or not (see picture)
    var directionAngle: (angle: CGFloat, topSide: Bool) = (normalizedAngle, true)

    let angleDiff: CGFloat = abs(normalizedAngle) > 270.0 ? 360.0 : 180.0 // shorthand for diff for equathion
    // next we should computate the angle and their side (top side or not) by considering the sign of incoming angle
    if (90.0 ... 270.0).contains(normalizedAngle) { // these angles - bottom side of half
        directionAngle = (normalizedAngle - angleDiff, false) // differ used for additional normalization angle for this range (90...270)
    }
    // the angles, which is more then of pi, we make it as top angle (diff = 360), so we get nagative angle value
    else if normalizedAngle > 270 { directionAngle = (normalizedAngle - angleDiff, true) }
    // and we make the same for negative anlges
    else if normalizedAngle < -90, normalizedAngle > -270 {
        directionAngle = (abs(abs(normalizedAngle) - angleDiff), false) // note: here,we use ABS to cast the valid angle to bottom side, unlike 90..270 positive angles (see above)
    } else if normalizedAngle <= -270 { directionAngle = (abs(abs(normalizedAngle) - angleDiff), true) } // in fact the same rules
    else {
        directionAngle = normalizedAngle > 0 ? (normalizedAngle, true) : (normalizedAngle, true) // other angles between -90 and 90
    }

    // for that point we get angle betwwen -90 and 90 and the side (top or bottoms)
    switch directionAngle.angle {
    case 90, -90.0: // simples values
        start = CGPoint(x: (90 - directionAngle.angle) / 180, y: 0.5)
        end = CGPoint(x: (90 + directionAngle.angle) / 180, y: 0.5)
    case -90 ..< 90:
        var angle = radian(degree: directionAngle.angle)
        var tAngle = tan(angle)
        guard !tAngle.isNaN else {
            start = CGPoint(x: 1, y: 0.5)
            end = CGPoint(x: 0, y: 0.5)
            break
        }
        // set default values for closest range
        start.y = 1
        end.y = 0
        // computate the part of head or tile by angle and sizings (see pic)
        let valueX = (size.width / 2 - (size.height / 2 * tAngle)) / size.width

        // computate next pair values of points
        start.x = valueX < 0 ? 0 : (valueX >= 1 ? 1 : valueX) // perl come with me
        end.x = valueX < 0 ? 1 : (valueX >= 1 ? 0 : 1 - valueX)

        // next we must check some special cases for too many angles (see pic)
        if valueX < 0 || valueX > 1 {
            angle = radian(degree: 90 - abs(directionAngle.angle))
            tAngle = tan(angle)
            let valueY = (size.height / 2 - (size.width / 2 * tAngle)) / size.height
            start.y = 1 - valueY
            end.y = valueY
        }
    default:
        break
    }
    // if topside == false, we need swap start and end points
    return directionAngle.topSide ? (start, end) : (end, start)
}
