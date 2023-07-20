import BEPureLayout
import PureLayout
import UIKit

public struct BaseCellItem {
    public var image: BaseCellImageViewItem?
    public var title: String?
    public var subtitle: String?
    public var subtitle2: String?
    public var rightView: BaseCellRightViewItem?

    public init(
        image: BaseCellImageViewItem? = nil,
        title: String? = nil,
        subtitle: String? = nil,
        subtitle2: String? = nil,
        rightView: BaseCellRightViewItem? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.subtitle2 = subtitle2
        self.image = image
        self.rightView = rightView
    }
}

open class BaseCell: BECollectionCell {
    
    // MARK: - View References
    
    private let container = BERef<UIView>()
    private var left: BaseCellLeftView?
    private var right: BaseCellRightView?
    
    // MARK: -
    
    // overriding init so it doesn't contain build call, since we're building
    // the view in configure
    override public init(frame: CGRect) {
        super.init()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -
    
    public override func build() -> UIView {
        BEHStack(spacing: 0, alignment: .center, distribution: .fill) {
            if let left = left {
                left.padding(.init(only: .left, inset: 17))
            }
            if let right = right {
                //BESpacer(.horizontal)
                right.padding(.init(only: .right, inset: 19)).setup { view in
                    view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
                }
            }
        }
        .bind(container)
        .padding(.init(top: 12, left: 0, bottom: 12, right: 0))
    }
    
    open func configure(with item: BaseCellItem) {
        let imageView = item.image != nil ? BaseCellImageView(item.image!) : nil

        self.left = .init(
            imageView: imageView,
            title: item.title,
            subtitle: item.subtitle,
            subtitle2: item.subtitle2
        )

        let rightItem = BaseCellRightViewItem(
            text: item.rightView?.text,
            subtext: item.rightView?.subtext,
            image: item.rightView?.image,
            isChevronVisible: item.rightView?.isChevronVisible ?? false,
            badge: item.rightView?.badge,
            yellowBadge: item.rightView?.yellowBadge,
            checkbox: item.rightView?.checkbox,
            switch: item.rightView?.`switch`,
            isCheckmark: item.rightView?.isCheckmark ?? false,
            buttonTitle: item.rightView?.buttonTitle
        )
        
        self.right = .init(item: rightItem)

        let child = build()
        contentView.addSubview(child)
        child.autoPinEdgesToSuperviewEdges()

        setNeedsLayout()
        layoutIfNeeded()
    }
    
    open override func prepareForReuse() {
        // removing subviews so we can add them in `build` again
        contentView.subviews.forEach { $0.removeFromSuperview() }
        super.prepareForReuse()
    }
    
    open override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        // Self-sizing is required in the vertical dimension.
        let size: CGSize = super.systemLayoutSizeFitting(
            layoutAttributes.size,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        layoutAttributes.size = size
        return layoutAttributes
    }
}
