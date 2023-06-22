import Foundation
import SwiftUI

struct InstructionsReceiveCellItem {
    var id: String = UUID().uuidString
    let instructions: [(String, (String, String))]
    let tip: String?
}

extension InstructionsReceiveCellItem: ReceiveRendableItem {
    func render() -> some View {
        InstructionsReceiveView(item: self)
    }
}
