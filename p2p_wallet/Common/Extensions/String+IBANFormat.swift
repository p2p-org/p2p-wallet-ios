import Foundation

extension String {
    func formatIBAN() -> String {
        // Remove any spaces or special characters from the input string
        let cleanedIBAN = self.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()

        // Check if the IBAN is empty or not valid (less than 4 characters)
        guard cleanedIBAN.count >= 4 else {
            return cleanedIBAN
        }

        // Create a formatted IBAN by grouping characters in blocks of four
        var formattedIBAN = ""
        var index = cleanedIBAN.startIndex

        while index < cleanedIBAN.endIndex {
            let nextIndex = cleanedIBAN.index(index, offsetBy: 4, limitedBy: cleanedIBAN.endIndex) ?? cleanedIBAN.endIndex
            let block = cleanedIBAN[index..<nextIndex]
            formattedIBAN += String(block)
            if nextIndex != cleanedIBAN.endIndex {
                formattedIBAN += " "
            }
            index = nextIndex
        }

        return formattedIBAN.uppercased()
    }
}
