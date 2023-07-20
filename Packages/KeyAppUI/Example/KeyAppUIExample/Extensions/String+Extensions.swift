import Foundation

extension String {
    var uppercasedFirst: String {
        prefix(1).uppercased() + lowercased().dropFirst()
    }

    mutating func uppercaseFirst() {
        self = uppercasedFirst
    }

    func replacingLastOccurrenceOfString(
        _ searchString: String,
        with replacementString: String,
        caseInsensitive: Bool = true
    ) -> String {
        let options: String.CompareOptions
        if caseInsensitive {
            options = [.backwards, .caseInsensitive]
        } else {
            options = [.backwards]
        }

        if let range = range(
            of: searchString,
            options: options,
            range: nil,
            locale: nil
        ) {
            return replacingCharacters(in: range, with: replacementString)
        }
        return self
    }
}
