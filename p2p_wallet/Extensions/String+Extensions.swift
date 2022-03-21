//
//  String+Extensions.swift
//  p2p wallet
//
//  Created by Chung Tran on 10/23/20.
//

import Foundation
import Down

extension Optional where Wrapped == String {
    public var orEmpty: String {
        self ?? ""
    }
    
    static func + (left: String?, right: String?) -> String {
        left.orEmpty + right.orEmpty
    }
    
    var double: Double? {
        guard let string = self else { return nil }
        return string.double
    }
}

extension String {
    var firstCharacter: String {
        String(prefix(1))
    }
    public var uppercaseFirst: String {
        firstCharacter.uppercased() + String(dropFirst())
    }
    
    public func onlyUppercaseFirst() -> String {
        lowercased().uppercaseFirst
    }
    
    subscript(bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }
    
    subscript(bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
    
    // swiftlint:disable swiftgen_strings
    func localized() -> String {
        NSLocalizedString(self, comment: "")
    }
    
    // swiftlint:enable swiftgen_strings
    
    func truncatingMiddle(numOfSymbolsRevealed: Int = 4, numOfSymbolsRevealedInSuffix: Int? = nil) -> String {
        if count <= numOfSymbolsRevealed + (numOfSymbolsRevealedInSuffix ?? numOfSymbolsRevealed) { return self }
        return prefix(numOfSymbolsRevealed) + "..." + suffix(numOfSymbolsRevealedInSuffix ?? numOfSymbolsRevealed)
    }
    
    func withNameServiceDomain() -> String {
        guard !self.hasSuffix(Self.nameServiceDomain) else {
            return self
        }
        return self + Self.nameServiceDomain
    }
    
    static var nameServiceDomain: String {
        ".p2p.sol"
    }
    
    static func secretConfig(_ key: String) -> String? {
        Bundle.main.infoDictionary?[key] as? String
    }
}

extension String {
    var double: Double? {
        let formatter = NumberFormatter()
        formatter.locale = Locale.current // USA: Locale(identifier: "en_US")
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        return formatter.number(from: self)?.doubleValue
    }
}

extension String {
    func asMarkdown(textSize: CGFloat? = nil, textColor: UIColor? = nil) -> NSAttributedString {
        let down = Down(markdownString: self)
        
        let fonts = StaticFontCollection(
            body: UIFont.systemFont(ofSize: textSize ?? 15)
        )
        
        let colors = StaticColorCollection(
            body: textColor ?? UIColor.textBlack
        )
        
        var paragraph = StaticParagraphStyleCollection()
        paragraph.body = {
            let p = NSMutableParagraphStyle()
            p.lineSpacing = 0
            return p
        }()
        
        return (try? down.toAttributedString(styler: DownStyler(
            configuration: DownStylerConfiguration(
                fonts: fonts,
                colors: colors,
                paragraphStyles: paragraph
            ))
        )) ?? NSAttributedString()
    }
}
