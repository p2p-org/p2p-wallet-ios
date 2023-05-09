import BEPureLayout
import PureLayout
import UIKit

public class SectionHeader: UICollectionReusableView {
    
    // MARK: -
    
    var expandDirection: ExpandDirection = .none {
        didSet {
            expandImageView.alpha = expandDirection == .none ? 0 : 1
            expandImageView.view?.transform = expandImageView.view?.transform == CGAffineTransform.identity
            ? CGAffineTransform(rotationAngle: .pi) : CGAffineTransform.identity
        }
    }
    private var titleLabel = BERef<UILabel>()
    private var expandImageView = BERef<UIImageView>()
    private let color = Asset.Colors.mountain.color
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let child = build()
        addSubview(child)
        child.autoPinEdgesToSuperviewEdges()
    }
    
    public required init?(coder: NSCoder) {
        fatalError()
    }
    
    // MARK: -
    
    public func toggle(animated: Bool = false) {
        guard expandDirection != .none else { return }
        UIView.animate(withDuration: animated ? 0.2 : 0) {
            self.expandDirection = self.expandDirection == .bottom ? .up : .bottom
        }
    }
    
    public func configure(text: String, expandDirection: ExpandDirection = .none) {
        titleLabel.attributedText = UIFont.text(text, of: .caps).withForegroundColor(color)
        self.expandDirection = expandDirection

        setNeedsLayout()
        layoutIfNeeded()
    }
    
    public func build() -> UIView {
        BEHStack(spacing: 4, alignment: .leading, distribution: .fill) {
            UILabel()
            .bind(titleLabel)
            .setup { label in
                label.setContentHuggingPriority(.defaultLow, for: .horizontal)
                label.setContentCompressionResistancePriority(.required, for: .horizontal)
            }
            UIImageView(image: Asset.MaterialIcon.expandMore.image.withTintColor(self.color, renderingMode: .alwaysOriginal))
                .frame(width: 16, height: 16)
                .bind(expandImageView)
//                BESpacer(.horizontal)
        }.onTap {
            self.toggle(animated: true)
        }
        .padding(.init(top: 16, left: 17, bottom: 0, right: 0))
    }
    
    
    public override func prepareForReuse() {
        titleLabel.attributedText = nil
        expandImageView.view?.alpha = 0.0
        super.prepareForReuse()
    }
    
    // MARK: -
    
    public enum ExpandDirection {
        case none
        case up
        case bottom
    }
    
}
