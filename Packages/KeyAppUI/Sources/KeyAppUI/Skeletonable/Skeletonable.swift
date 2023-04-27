import UIKit
import SkeletonView
import BEPureLayout

public class SkeletonAppearance {
    public static let color = Asset.Colors.rain.color
    public static let labelCornerRadius: Int = 10
    public static let imageCornerRadius: Float = 10
}

public protocol Skeletonable {
    func makeSkeletonable()
}

public protocol CustomSkeletonable {
    func makeCustomSkeletonable()
}

extension UIView: Skeletonable {

    public func makeSkeletonable() {
        if let custom = self as? CustomSkeletonable {
            custom.makeCustomSkeletonable()
            return
        }
        isSkeletonable = true
        if let label = self as? UILabel {
            label.lastLineFillPercent = 85
            label.linesCornerRadius = SkeletonAppearance.labelCornerRadius
        } else if let image = self as? UIImageView {
            image.skeletonCornerRadius = max(self.superview != nil ? Float(image.bounds.height/2) : SkeletonAppearance.imageCornerRadius, SkeletonAppearance.imageCornerRadius)
        } else if let stack = self as? UIStackView {
            stack.arrangedSubviews.forEach { $0.makeSkeletonable() }
        }
        
        subviews.forEach { $0.makeSkeletonable() }
    }
}

public extension UIView {
    
    func showDefaultAnimatedSkeleton() {
        makeSkeletonable()
        showAnimatedSkeleton(usingColor: SkeletonAppearance.color)
    }
    
    func showDefaultSkeleton() {
        makeSkeletonable()
        showSkeleton(usingColor: SkeletonAppearance.color)
    }
    
}


extension IconButton: CustomSkeletonable {
    
    public func makeCustomSkeletonable() {
        isSkeletonable = true
        imageView.view?.isSkeletonable = true
        titleView.view?.isSkeletonable = true
        titleView.view?.linesCornerRadius = SkeletonAppearance.labelCornerRadius
        titleView.view?.lastLineFillPercent = 100
        titleSpacing.view?.isSkeletonable = false
        (subviews.first as? UIStackView)?.isSkeletonable = true
        (subviews.first as? UIStackView)?.arrangedSubviews.forEach {$0.isSkeletonable = true}
    }
}

//extension BESpacer: CustomSkeletonable {
//    public func makeCustomSkeletonable() {
//        isSkeletonable = false
//    }
//}
