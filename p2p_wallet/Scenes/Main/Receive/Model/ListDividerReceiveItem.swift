import Foundation
import SwiftUI

struct ListDividerReceiveItem {
    var id: String = UUID().uuidString
}

extension ListDividerReceiveItem: ReceiveRendableItem {
    func render() -> some View {
        ListDividerReceiveView()
    }
}
