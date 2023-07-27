import BEPureLayout
import UIKit

public class TextField_Deprecated: UITextField {
    // Default padding
    let edgePadding: CGFloat = 16

    // MARK: - Ref

    let coverViewRef = BERef<UIView>()
    let placeholderContainerRef = BERef<UIView>()
    var placeholderRef = BERef<UILabel>()
    var placeholderLeadingRef = BERef<UIView>()
    public var onPaste: (() -> Void)?

    // MARK: -

    override public var font: UIFont? {
        didSet {
            placeholderRef.font = font
        }
    }

    public var constantPlaceholder: String? {
        didSet {
            placeholderRef.text = constantPlaceholder
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        let place = placeholderView()
        insertSubview(place, at: 0)
        insertSubview(placeholderCoverView(), aboveSubview: place)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func placeholderView() -> UIView {
        UILabel(text: constantPlaceholder,
                font: font,
                textColor: UIColor(resource: .night).withAlphaComponent(0.3))
            .bind(placeholderRef)
    }

    func placeholderCoverView() -> UIView {
        UIView().bind(coverViewRef).setup { vv in
            vv.backgroundColor = UIColor(resource: .rain)
            vv.isUserInteractionEnabled = false
        }
    }

    func update() {
        guard let placeholder = constantPlaceholder, let text = text, let font = font else { return }
        let endIndex = min(text.count, placeholder.count)
        let placeholderSubstring = placeholder[0 ..< endIndex]
        coverViewRef.view?.frame = CGRect(
            x: inputLeadingInset,
            y: 12,
            width: placeholderSubstring.widthOfString(usingFont: font),
            height: layer.bounds.height
        )
        placeholderRef.view?.frame = placeholderRect(forBounds: bounds)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        update()
    }

    // MARK: -

    var inputLeadingInset: CGFloat {
        let viewWidth = leftViewRect(forBounds: bounds).width
        return viewWidth + edgePadding + (viewWidth > 0 ? edgePadding / 2 : 0)
    }

    var inputTrailingInset: CGFloat {
        let viewWidth = rightViewRect(forBounds: bounds).width
        return viewWidth + edgePadding + (viewWidth > 0 ? edgePadding / 2 : 0)
    }

    override public func textRect(forBounds bounds: CGRect) -> CGRect {
        CGRect(
            x: inputLeadingInset,
            y: 0,
            width: bounds.width - inputLeadingInset - inputTrailingInset,
            height: bounds.height
        )
    }

    override public func editingRect(forBounds bounds: CGRect) -> CGRect {
        CGRect(
            x: inputLeadingInset,
            y: 0,
            width: bounds.width - inputLeadingInset - inputTrailingInset,
            height: bounds.height
        )
    }

    override public func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        CGRect(
            x: inputLeadingInset,
            y: 0,
            width: bounds.width - inputLeadingInset - inputTrailingInset,
            height: bounds.height
        )
    }

    override public func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.leftViewRect(forBounds: bounds)
        return CGRect(
            x: rect.origin.x + edgePadding,
            y: rect.origin.y,
            width: rect.width,
            height: rect.height
        )
    }

    override public func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.rightViewRect(forBounds: bounds)
        return CGRect(
            x: rect.origin.x - edgePadding,
            y: rect.origin.y,
            width: rect.width,
            height: rect.height
        )
    }

    override public func paste(_ sender: Any?) {
        super.paste(sender)
        onPaste?()
    }
}
