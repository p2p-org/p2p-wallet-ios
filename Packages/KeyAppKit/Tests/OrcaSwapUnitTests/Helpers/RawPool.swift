import Foundation

struct RawPool: Codable {
    init(name: String, reversed: Bool = false) {
        self.name = name
        self.reversed = reversed
    }
    
    let name: String
    let reversed: Bool
}
