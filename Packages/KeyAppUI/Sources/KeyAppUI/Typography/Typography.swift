import UIKit
import SwiftUI

public extension UIFont {
    
    /// Typography styles
    enum Style: String, CaseIterable {
        case label2
        case label1
        case caps
        case text4
        case text3
        case text2
        case text1
        case title3
        case title2
        case title1
        case largeTitle
    }
    
    /// Font by style and weight
    static func font(of style: Style, weight: Weight = .regular) -> UIFont {
        UIFont.systemFont(ofSize: fontSize(of: style), weight: weight)
    }
    
    static func monospaceFont(of style: Style, weight: Weight = .regular) -> UIFont {
        UIFont.monospacedSystemFont(ofSize: fontSize(of: style), weight: weight)
    }
    
    /// Attributed string of selected style and weight
    static func text(_ text: String, of style: Style, weight: Weight = .regular) -> NSAttributedString {
        NSAttributedString.attributedString(with: text, of: style, weight: weight)
    }
    
    // MARK: -
    
    static func fontSize(of style: Style) -> CGFloat {
        var fontSize: CGFloat = 11
        switch style {
        case .label2:
            fontSize = 11
        case .label1, .caps:
            fontSize = 12
        case .text4:
            fontSize = 13
        case .text3:
            fontSize = 15
        case .text2:
            fontSize = 16
        case .text1:
            fontSize = 17
        case .title3:
            fontSize = 20
        case .title2:
            fontSize = 22
        case .title1:
            fontSize = 28
        case .largeTitle:
            fontSize = 34
        }
        return fontSize
    }
    
    static func lineHeight(for style: Style) -> CGFloat {
        let font = UIFont.font(of: style)
        /// figma line height
        var lineHeight: CGFloat = 12
        switch style {
        case .label2:
            lineHeight = 12
        case .label1, .text4, .caps:
            lineHeight = 16
        case .text3, .text2:
            lineHeight = 20
        case .text1, .title3:
            lineHeight = 24
        case .title2:
            lineHeight = 28
        case .title1:
            lineHeight = 32
        case .largeTitle:
            lineHeight = 40
        }
        return max(0, lineHeight - font.lineHeight)
    }
    
    static func letterSpacing(for style: Style) -> CGFloat {
        var letterSpacing = 0.07
        switch style {
        case .label2, .caps:
            letterSpacing = 0.07
        case .label1:
            letterSpacing = 0
        case .text4:
            letterSpacing = -0.08
        case .text3:
            letterSpacing = -0.24
        case .text2:
            letterSpacing = -0.32
        case .text1:
            letterSpacing = -0.41
        case .title3:
            letterSpacing = 0.38
        case .title2:
            letterSpacing = 0.35
        case .title1:
            letterSpacing = 0.36
        case .largeTitle:
            letterSpacing = 0.37
        }
        return letterSpacing
    }
}

public extension NSAttributedString {
    static func attributedString(
        with text: String,
        of style: UIFont.Style,
        weight: UIFont.Weight = .regular,
        alignment: NSTextAlignment = .left,
        monospace: Bool = false
    ) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = UIFont.lineHeight(for: style)
        paragraph.alignment = alignment
        let string = NSAttributedString(string: text, attributes: [
            .font: monospace ? UIFont.monospaceFont(of: style, weight: weight) : UIFont.font(of: style, weight: weight),
            .paragraphStyle: paragraph,
            .kern: UIFont.letterSpacing(for: style)
        ])
        return string
    }
}

public extension Text {
    func apply(style: UIFont.Style) -> some View {
        self.kerning(UIFont.letterSpacing(for: style))
            .font(Font(UIFont.font(of: style).withSize(UIFont.fontSize(of: style)) as CTFont))
            .lineSpacing(UIFont.lineHeight(for: style))
    }
}
