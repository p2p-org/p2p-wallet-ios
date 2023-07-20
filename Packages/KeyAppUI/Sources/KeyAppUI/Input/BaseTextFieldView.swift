import UIKit
import BEPureLayout

open class BaseTextFieldView: BECompositionView {
    
    // MARK: -
    
    private(set) var isBig = false
    
    public var leftView: UIView? {
        didSet {
            inputFieldRef.view?.leftView = leftView
        }
    }
    
    public var leftViewMode: UITextField.ViewMode = .never {
        didSet {
            textField?.leftViewMode = leftViewMode
        }
    }
    
    public var rightView: UIView? {
        didSet {
            inputFieldRef.view?.rightView = rightView
        }
    }
    
    public var rightViewMode: UITextField.ViewMode = .never {
        didSet {
            textField?.rightViewMode = rightViewMode
        }
    }
    
    var topTipLabel = BERef<UILabel>()
    var bottomTipLabel = BERef<UILabel>()
    var container = BERef<UIView>()
    var inputFieldRef = BERef<TextField>()
    
    public var textField: UITextField? {
        return inputFieldRef.view
    }
    
    /// Set input text
    public var text: String? {
        didSet {
            inputFieldRef.text = text
        }
    }
    
    /// Set placeholder text
    public var placeholder: String? {
        didSet {
            inputFieldRef.placeholder = placeholder
        }
    }
    
    /// Placeholder which doesn't disappear while typing
    public var constantPlaceholder: String? {
        didSet {
            inputFieldRef.constantPlaceholder = constantPlaceholder
        }
    }
    
    public var style: Style = .default {
        didSet {
            updateView()
        }
    }
    
    // MARK: - Public
    
    public func topTip(_ tip: String) {
        topTipLabel.view?.attributedText = .attributedString(
            with: tip,
            of: .label1,
            weight: .regular
        ).withForegroundColor(Asset.Colors.mountain.color)
    }
    
    public func bottomTip(_ tip: String) {
        bottomTipLabel.view?.attributedText = .attributedString(
            with: tip,
            of: .label1,
            weight: .regular
        ).withForegroundColor(bottomTipColor())
    }
    
    public override func build() -> UIView {
        BEVStack {
            UILabel().withAttributedText(
                .attributedString(with: "", of: .label1, weight: .regular)
                .withForegroundColor(Asset.Colors.mountain.color)
            ).bind(topTipLabel).padding(.init(top: 0, left: 8, bottom: 6, right: 0))
            
            inputField.setup { input in
                input.backgroundColor = Asset.Colors.rain.color
            }.box(cornerRadius: 12).bind(container)
            
            UILabel().withAttributedText(
                .attributedString(with: "", of: .label1, weight: .regular)
                .withForegroundColor(Asset.Colors.mountain.color)
            ).bind(bottomTipLabel).padding(.init(top: 5, left: 8, bottom: 0, right: 0))
        }
    }
    
    // MARK: -
    
    private var inputField: UIView {
        BEVStack {
            TextField(
                backgroundColor: Asset.Colors.rain.color,
                font: UIFont.monospaceFont(of: .title1, weight: .bold),
                textColor: Asset.Colors.night.color,
                textAlignment: .left,
                keyboardType: .default,
                placeholder: "",
                placeholderTextColor: Asset.Colors.night.color.withAlphaComponent(0.3)
            ).bind(inputFieldRef).frame(height: isBig ? 58 : 46).setup { input in
                input.constantPlaceholder = constantPlaceholder
                input.setContentHuggingPriority(.defaultLow, for: .horizontal)
                input.setContentCompressionResistancePriority(.required, for: .horizontal)
            }
        }.setup { input in
            input.layer.cornerRadius = 12
            input.layer.masksToBounds = true
        }
    }
    
    // MARK: -
    
    public init(leftView: UIView? = nil, rightView: UIView? = nil, isBig: Bool = false) {
        self.leftView = leftView
        self.inputFieldRef.view?.leftView = self.leftView
        self.rightView = rightView
        self.inputFieldRef.view?.rightView = self.rightView
        self.isBig = isBig
        super.init(frame: .zero)
        updateView()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -
    
    private func updateView() {
        bottomTipLabel.view?.textColor = bottomTipColor()
        container.view?.layer.borderWidth = 1
        container.view?.layer.borderColor = borderColor().cgColor
        container.view?.layer.masksToBounds = true
        inputFieldRef.view?.leftView = leftView
        inputFieldRef.view?.rightView = rightView
    }
    
    private func bottomTipColor() -> UIColor {
        switch style {
        case .default:
            return Asset.Colors.mountain.color
        case .error:
            return Asset.Colors.rose.color
        case .success:
            return Asset.Colors.mint.color
        }
    }
    
    private func borderColor() -> UIColor {
        switch style {
        case .default:
            return UIColor.clear
        case .error:
            return Asset.Colors.rose.color
        case .success:
            return Asset.Colors.mint.color
        }
    }
    
    // MARK: -
    
    public enum Style: CaseIterable {
        case `default`
        case success
        case error
    }
    
}
