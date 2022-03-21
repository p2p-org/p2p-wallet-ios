//
// Created by Giang Long Tran on 16.02.2022.
//

import BEPureLayout
import BECollectionView
import RxSwift
import RxCocoa

class SwipeableCell: BECompositionView {
    let leadingActions: UIView?
    let trailingActions: UIView?
    let content: UIView
    
    private let scrollTriggerOffset: CGFloat = 30
    private var scrollViewRef = BERef<BEScrollView>()
    
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
                }.setupWithType(BEScrollView.self) { view in
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
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "contentSize" {
            contentSizeDidUpdate()
        }
    }
    // swiftlint:enable block_based_kvo
    
    private var isFirstRun = true
    
    func contentSizeDidUpdate() {
        guard let leadingActions = leadingActions else { return }
        if isFirstRun && leadingActions.frame.width > 0 {
            centralize(animated: false)
            isFirstRun = false
        }
    }

    func centralize(animated: Bool = true) {
        guard let leadingActions = leadingActions else {
            scrollViewRef.view?.scrollView.setContentOffset(.zero, animated: animated)
            return
        }
        scrollViewRef.view?.scrollView.setContentOffset(.init(x: leadingActions.frame.width, y: 0), animated: animated)
    }
}

extension SwipeableCell: UIScrollViewDelegate {
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if abs(scrollView.contentOffset.x - content.frame.origin.x) < 2 {
            content.isUserInteractionEnabled = false
        } else {
            content.isUserInteractionEnabled = true
        }
    }
    
    func nearestAnchor(forContentOffset offset: CGPoint) -> CGPoint {
        let offsetFromCenter = content.frame.origin.x - offset.x
        
        if offsetFromCenter > scrollTriggerOffset {
            // left
            guard let leadingActions = leadingActions else { return .zero}
            return .init(x: leadingActions.frame.origin.x, y: offset.y)
        } else if offsetFromCenter < -scrollTriggerOffset {
            // right
            guard let trailingActions = trailingActions else { return .zero}
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
        let offsetProjection = scrollView.contentOffset.project(initialVelocity: velocity, decelerationRate: decelerationRate)
        let targetAnchor = nearestAnchor(forContentOffset: offsetProjection)
        
        targetContentOffset.pointee = targetAnchor
    }
}

extension FloatingPoint {
    func project(initialVelocity: Self, decelerationRate: Self) -> Self {
        if decelerationRate >= 1 {
            assert(false)
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
