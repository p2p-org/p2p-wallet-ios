//
//  ReserveTextViewChangesFilter.swift
//  p2p_wallet
//
//  Created by Andrew Vasiliev on 08.12.2021.
//

final class ReserveTextViewChangesFilter: TextChangesFilter {
    private let maxSymbols = 15

    func isValid(textContainer: ContainsText, string: String, range: NSRange) -> Bool {
        guard let stringRange = Range(range, in: textContainer.getText() ?? "") else { return false }
        let updatedText = (textContainer.getText() ?? "").replacingCharacters(in: stringRange, with: string)

        return isValid(string: updatedText)
    }

    func isValid(string: String) -> Bool {
        let set = NSCharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-")
            .inverted
        let containsOnlyAllowedCharacters = string.rangeOfCharacter(from: set) == nil

        let hyphenDoesNotStandInTheBeginingOfTheText = !string.starts(with: "-")
        let doNotContains2HyphensNextToEachOther = !string.contains("--")
        let hasNotMoreSymbols = string.count <= maxSymbols

        return containsOnlyAllowedCharacters && hyphenDoesNotStandInTheBeginingOfTheText &&
            doNotContains2HyphensNextToEachOther &&
            hasNotMoreSymbols
    }
}
