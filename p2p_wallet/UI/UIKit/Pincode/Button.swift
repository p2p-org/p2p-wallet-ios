import BEPureLayout
import UIKit

class NumpadButton: BEView {
    // MARK: - Constant

    private let textSize: CGFloat = 32
    private let customBgColor = PincodeStateColor(normal: .clear, tapped: UIColor(resource: .night))
    private let textColor = PincodeStateColor(normal: UIColor(resource: .night), tapped: UIColor(resource: .snow))

    // MARK: - Subviews

    lazy var label = UILabel(font: .font(of: .largeTitle, weight: .regular), textColor: textColor.normal)

    // MARK: - Methods

    override func commonInit() {
        super.commonInit()
        backgroundColor = customBgColor.normal

        addSubview(label)
        label.autoCenterInSuperview()
    }

    func setHighlight(value: Bool) {
        if value {
            layer.backgroundColor = customBgColor.tapped.cgColor
            label.textColor = textColor.tapped
        } else {
            layer.backgroundColor = customBgColor.normal.cgColor
            label.textColor = textColor.normal
        }
    }

    func animateTapping() {
        layer.backgroundColor = customBgColor.tapped.cgColor
        label.textColor = textColor.tapped
        UIView.animate(withDuration: 0.05) {
            self.layer.backgroundColor = self.customBgColor.normal.cgColor
            self.label.textColor = self.textColor.normal
        }
    }
}
