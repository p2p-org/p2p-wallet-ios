import Foundation

extension String {
    private func removingExtraSpaces() -> String {
        return self.replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression, range: nil)
    }
    private var lettersAndSpaces: String {
        return String(unicodeScalars.filter({ scalar in
            CharacterSet.englishLowercaseLetters.contains(scalar) ||
            CharacterSet(charactersIn: " ").contains(scalar)
        }))
    }
    public var seedPhraseFormatted: String {
        lowercased()
            .lettersAndSpaces
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .removingExtraSpaces()
    }
}

extension CharacterSet {
    static var englishLowercaseLetters: CharacterSet {
        CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz")
    }
}
