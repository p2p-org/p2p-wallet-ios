//
// Created by Giang Long Tran on 16.02.2022.
//

import BEPureLayout
import RxCocoa
import RxSwift
import UIKit

/// This class is responsible for left and right swipe to show extra actions.
class SwipeableCell: BECompositionView {
    /// The enum describes current swipe state.
    enum Focus {
        case right
        case left
        case center
    }

    /// Leading action view.
    let leadingActions: UIView?

    /// Trailing action view.
    let trailingActions: UIView?

    /// Primary content view.
    let content: UIView

    /// The value determines when view should scroll to nearest action view
    private let scrollTriggerOffset: CGFloat = 30

    /// The value determines when view should change state and disable/enable interaction.
    private let stateTriggerOffset: CGFloat = 2

    private var scrollViewRef = BERef<BEScrollView>()

    /// Current focus state
    fileprivate var focus: Focus = .center {
        didSet {
            switch focus {
            case .left:
                trailingActions?.alpha = 0
            case .right:
                leadingActions?.alpha = 0
            case .center:
                leadingActions?.alpha = 1
                trailingActions?.alpha = 1
            }
        }
    }

    /// Initialize a view that supports swipe for showing extra actions.
    ///
    /// This class listens `contentSize` changes of scroll view to set start position (center).
    /// Unfortunately there is not way to set start position of scroll view before it has been layouted.
    ///
    /// - Parameters:
    ///   - leadingActions: Leading actions view
    ///   - content: Content view
    ///   - trailingActions: Trailing actions view
    init(leadingActions: UIView?, content: UIView, trailingActions: UIView?) {
        self.leadingActions = leadingActions
        self.trailingActions = trailingActions
        self.content = content
        super.init()

        layoutIfNeeded()
    }

    override func build() -> UIView {
        BEZStack {
            BEZStackPosition(mode: .fill) { BEContainer().backgroundColor(color: .f6f6f8) }
            BEZStackPosition(mode: .fill) {
                BEScrollView(axis: .horizontal, showsHorizontalScrollIndicator: false, delegate: self) {
                    BEHStack {
                        // leading action
                        if leadingActions != nil { leadingActions! }

                        // content
                        content
                            .onTap { [unowned self] in centralize() }

                        // trailing action
                        if trailingActions != nil { trailingActions! }
                    }
                }.setup { view in
                    view.scrollView.addObserver(self, forKeyPath: "contentSize", options: [], context: nil)
                }.bind(scrollViewRef)
            }.setup { view in
                content.autoMatch(.width, to: .width, of: view)
            }
        }
    }

    deinit {
        scrollViewRef.view?.scrollView.removeObserver(self, forKeyPath: "contentSize")
    }

    // swiftlint:disable block_based_kvo
    override func observeValue(
        forKeyPath keyPath: String?,
        of _: Any?,
        change _: [NSKeyValueChangeKey: Any]?,
        context _: UnsafeMutableRawPointer?
    ) {
        if keyPath == "contentSize" {
            contentSizeDidUpdate()
        }
    }

    // swiftlint:enable block_based_kvo

    private var isFirstRun = true

    /// This method will be called when content size of scroll view has changed.
    func contentSizeDidUpdate() {
        guard let leadingActions = leadingActions else { return }
        if isFirstRun, leadingActions.frame.width > 0 {
            centralize(animated: false)
            isFirstRun = false
        }
    }

    /// Set center position of swipe
    ///
    /// - Parameter animated: The value used to show animation by centralizing.
    func centralize(animated: Bool = true) {
        guard let leadingActions = leadingActions else {
            scrollViewRef.view?.scrollView.setContentOffset(.zero, animated: animated)
            return
        }
        // Stops the animation if exists
        scrollViewRef.view?.scrollView.setContentOffset(
            .zero,
            animated: false
        )
        scrollViewRef.view?.scrollView.setContentOffset(.init(x: leadingActions.frame.width, y: 0), animated: animated)
    }
}

extension SwipeableCell: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if abs(scrollView.contentOffset.x - content.frame.origin.x) < stateTriggerOffset {
            content.isUserInteractionEnabled = false
        } else {
            content.isUserInteractionEnabled = true
        }
    }

    func nearestAnchor(forContentOffset offset: CGPoint) -> CGPoint {
        let offsetFromCenter = content.frame.origin.x - offset.x

        if offsetFromCenter > scrollTriggerOffset, focus == .center, let leadingActions = leadingActions {
            // left
            return .init(x: leadingActions.frame.origin.x, y: offset.y)
        } else if offsetFromCenter < -scrollTriggerOffset, focus == .center, let trailingActions = trailingActions {
            // right
            return .init(x: trailingActions.frame.origin.x, y: offset.y)
        } else {
            // center
            return .init(x: content.frame.origin.x, y: offset.y)
        }
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let decelerationRate = UIScrollView.DecelerationRate.normal.rawValue
        let offsetProjection = scrollView.contentOffset.project(
            initialVelocity: velocity,
            decelerationRate: decelerationRate
        )
        let targetAnchor = nearestAnchor(forContentOffset: offsetProjection)

        targetContentOffset.pointee = targetAnchor
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollViewFinishScroll(scrollView)
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewFinishScroll(scrollView)
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate { scrollViewFinishScroll(scrollView) }
    }

    func scrollViewFinishScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset.x - content.frame.origin.x

        if offset > stateTriggerOffset {
            focus = .right
        } else if offset < -stateTriggerOffset {
            focus = .left
        } else {
            focus = .center
        }
    }
}

extension FloatingPoint {
    func project(initialVelocity: Self, decelerationRate: Self) -> Self {
        if decelerationRate >= 1 {
            assertionFailure()
            return self
        }
        return self + initialVelocity * decelerationRate / (1 - decelerationRate)
    }
}

extension CGPoint {
    func project(initialVelocity: CGPoint, decelerationRate: CGPoint) -> CGPoint {
        let xProjection = x.project(initialVelocity: initialVelocity.x, decelerationRate: decelerationRate.x)
        let yProjection = y.project(initialVelocity: initialVelocity.y, decelerationRate: decelerationRate.y)
        return CGPoint(x: xProjection, y: yProjection)
    }

    func project(initialVelocity: CGPoint, decelerationRate: CGFloat) -> CGPoint {
        project(initialVelocity: initialVelocity, decelerationRate: CGPoint(x: decelerationRate, y: decelerationRate))
    }
}
