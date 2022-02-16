//
// Created by Giang Long Tran on 16.02.2022.
//

import BEPureLayout
import BECollectionView
import RxSwift
import RxCocoa

class SwipeableCell: BECompositionView {
    let leadingActions: UIView
    let trailingActions: UIView
    let content: UIView
    
    private var scrollContainer = BERef<UIView>()
    
    init(leadingActions: UIView, content: UIView, trailingActions: UIView) {
        self.leadingActions = leadingActions
        self.trailingActions = trailingActions
        self.content = content
        super.init()
    }
    
    override func build() -> UIView {
        BEZStack {
            BEZStackPosition(mode: .fill) { BEContainer().backgroundColor(color: .f6f6f8) }
            BEZStackPosition(mode: .fill) {
                BEScrollView(axis: .horizontal, showsHorizontalScrollIndicator: false, delegate: self) {
                    BEHStack {
                        // leading action
                        leadingActions
                        
                        // content
                        content
                        
                        // trailing action
                        trailingActions
                        
                    }.bind(scrollContainer)
                }
            }.setup { view in
                guard let primaryStack = view.viewWithTag(1) else { return }
                primaryStack.autoMatch(.width, to: .width, of: view)
            }
        }
            .frame(height: 63)
    }
}

extension SwipeableCell: UIScrollViewDelegate {
    var maxAnchor: CGPoint {
        CGPoint(x: scrollContainer.view?.frame.width ?? 0, y: 0)
    }
    
    func nearestAnchor(forContentOffset offset: CGPoint) -> CGPoint {
        guard let scrollContainer = scrollContainer.view else { return .zero }
        var candidate = scrollContainer.subviews.map { $0.frame.origin }.min(by: { abs($0.x - offset.x) < abs($1.x - offset.x) })!
        candidate.x = min(candidate.x, maxAnchor.x)
        return candidate
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
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