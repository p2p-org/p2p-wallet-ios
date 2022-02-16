//
// Created by Giang Long Tran on 16.02.2022.
//

import BEPureLayout
import BECollectionView
import RxSwift
import RxCocoa

protocol SwipeableDelegate {
    var onAction: Signal<Any> { get }
}

class SwipeableCell: BECompositionView {
    let leadingActions: UIView
    let trailingActions: UIView
    let content: UIView
    
    private let scrollTriggerOffset: CGFloat = 30
    private var scrollView = BERef<UIScrollView>()
    
    init(leadingActions: UIView, content: UIView, trailingActions: UIView) {
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
                ContentHuggingScrollView(axis: .horizontal, showsHorizontalScrollIndicator: false, delegate: self) {
                    // leading action
                    leadingActions
                        .withTag(1)
                    
                    // content
                    content
                        .withTag(2)
                        .onTap { [unowned self] in centralize() }
                    
                    // trailing action
                    trailingActions
                        .withTag(3)
                }.setupWithType(ContentHuggingScrollView.self) { view in
                    view.addObserver(self, forKeyPath: "contentSize", options: [], context: nil)
                    
                    leadingActions.autoPinEdge(toSuperviewEdge: .top)
                    leadingActions.autoPinEdge(toSuperviewEdge: .bottom)
                    leadingActions.autoPinEdge(.left, to: .left, of: view.contentView)
                    // leadingActions.autoPinEdge(.right, to: .right, of: view.contentView)
                    
                    content.autoPinEdge(toSuperviewEdge: .top)
                    content.autoPinEdge(toSuperviewEdge: .bottom)
                    content.autoPinEdge(.left, to: .right, of: leadingActions)
                    
                    trailingActions.autoPinEdge(toSuperviewEdge: .top)
                    trailingActions.autoPinEdge(toSuperviewEdge: .bottom)
                    trailingActions.autoPinEdge(.left, to: .right, of: content)
                    trailingActions.autoPinEdge(.right, to: .right, of: view.contentView)
                }.bind(scrollView)
            }.setup { view in
                content.autoMatch(.width, to: .width, of: view)
            }
        }
    }
    
    deinit {
        scrollView.view?.removeObserver(self, forKeyPath: "contentSize")
    }
    
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
    
    private var isFirstRun = true
    
    func contentSizeDidUpdate() {
        if isFirstRun && leadingActions.frame.width > 0 {
            centralize(animated: false)
            isFirstRun = false
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
    }
    
    func centralize(animated: Bool = true) {
        scrollView.view?.setContentOffset(.init(x: leadingActions.frame.width, y: 0), animated: animated)
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
            return .init(x: leadingActions.frame.origin.x, y: offset.y)
        } else if offsetFromCenter < -scrollTriggerOffset {
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