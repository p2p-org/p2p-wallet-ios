import BEPureLayout
import Foundation
import PureLayout
import UIKit

public class SnackBar: BECompositionView {

    // MARK: - Properties
    var autoHide: Bool = true
    var hideCompletion: (() -> Void)?

    public var title: String? {
        didSet {
            (leadingView.view as? UILabel)?.text = title
        }
    }

    public var text: String {
        didSet { textView.text = text }
    }

    public var icon: UIImage? {
        didSet {
            (leadingView.view as? UIImageView)?.image = icon
        }
    }

    let leadingSpacing = BERef<UIView>()
    let titleView = BERef<UILabel>()
    let textView = BERef<UILabel>()
    let leadingView = BERef<UIView>()
    let trailing: UIView?

    var appearance: Appearance = Appearance(
        titleFontSize: 24.0,
        textFontSize: 15.0,
        textFontWeight: .regular,
        textFont: .systemFont(ofSize: 15.0),
        textColor: .white
    )

    public init(
        title: String? = nil,
        icon: UIImage?,
        text: String,
        trailing: UIView? = nil
    ) {
        self.title = title
        self.icon = icon
        self.text = text
        self.trailing = trailing
        super.init()
    }

    // MARK: -

    override public func build() -> UIView {
        BEContainer {
            BEHStack(spacing: 14, alignment: .center, distribution: .fill) {
                // Leading
                BEContainer()
                    .frame(width: 0)
                    .bind(leadingSpacing)

                if icon != nil {
                    UIImageView(
                        width: 24,
                        height: 24,
                        image: icon,
                        contentMode: .scaleAspectFit,
                        tintColor: appearance.iconTintColor)
                        .frame(width: 24, height: 24)
                        .bind(leadingView)
                }

                if title != nil {
                    UILabel(
                        text: title,
                        textSize: appearance.titleFontSize,
                        textColor: Asset.Colors.snow.color,
                        numberOfLines: appearance.numberOnLines
                    ).bind(leadingView)
                        .margin(.init(only: .left, inset: 6))
                        .setup { view in
                            view.layoutIfNeeded()
                            view.setContentHuggingPriority(.defaultLow, for: .horizontal)
                            view.setContentCompressionResistancePriority(.required, for: .horizontal)
                        }
                }

                UILabel(
                    text: text,
                    font: appearance.textFont,
                    textColor: Asset.Colors.snow.color,
                    numberOfLines: appearance.numberOnLines
                ).bind(textView)
                .margin(.init(top: 20, left: 0, bottom: 20, right: 0))
                .setup { view in
                    view.setContentHuggingPriority(.defaultLow, for: .horizontal)
                    view.setContentCompressionResistancePriority(.required, for: .horizontal)
                }
                
                UIView.spacer

                if let trailing = trailing {
                    trailing
                }
            }
        }.backgroundColor(color: Asset.Colors.night.color)
        .box(cornerRadius: appearance.cornerRadius)
        .border(width: 1, color: appearance.borderColor)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SnackBar {
    /// Structure describing appearance
    struct Appearance {
        var titleFontSize: CGFloat
        var textFontSize: CGFloat
        var textFontWeight: UIFont.Weight
        var textFont: UIFont
        var textColor: UIColor
        var cornerRadius: CGFloat = 13
        var backgroundColor: UIColor = .init(red: 0.167, green: 0.167, blue: 0.167, alpha: 1)
        var borderColor: UIColor = .init(red: 1, green: 1, blue: 1, alpha: 0.2)
        var iconTintColor: UIColor = .init(red: 0, green: 0, blue: 0, alpha: 1)
        var numberOnLines = 3
    }
}
