import Foundation

extension String {
    var nonLetters: String { filter("0123456789.,".contains) }
    
    func amountFormat(
        maxAfterComma: Int = 2,
        maxBeforeComma: Int? = nil,
        decimalSeparator: String = "."
    ) -> String {
        var withoutLetters = nonLetters
        
        while
            withoutLetters.first == "0",
            withoutLetters.count >= 2,
            withoutLetters[1] != "," && withoutLetters[1] != "." {
            withoutLetters.removeFirst()
        }
        
        if first == "," || first == "." {
            withoutLetters = "0\(self)"
        }
        
        var set = Set<Character>()
        let withoutRepeatedDots = withoutLetters.filter { ("0"..."9" ~= $0) || set.insert($0).inserted }
        
        let commaFormatted = withoutRepeatedDots
            .replacingOccurrences(of: decimalSeparator == "." ? "," : ".", with: decimalSeparator)
        
        var countFormatted = commaFormatted
        let components = commaFormatted.components(separatedBy: decimalSeparator)
        
        if let beforeComma = components.first {
            countFormatted = beforeComma
            if let maxBeforeComma = maxBeforeComma {
                while countFormatted.count > maxBeforeComma {
                    countFormatted.removeLast()
                }
            }
            
            if components.count == 2, var afterComma = components.last {
                while afterComma.count > maxAfterComma {
                    afterComma.removeLast()
                }
                countFormatted += "\(decimalSeparator)\(afterComma)"
            }
        }
        
        return countFormatted
    }
}

extension String {
    subscript (index: Int) -> Character {
        let charIndex = self.index(self.startIndex, offsetBy: index)
        return self[charIndex]
    }

    subscript (range: Range<Int>) -> Substring {
        let startIndex = self.index(self.startIndex, offsetBy: range.startIndex)
        let stopIndex = self.index(self.startIndex, offsetBy: range.startIndex + range.count)
        return self[startIndex..<stopIndex]
    }
}
