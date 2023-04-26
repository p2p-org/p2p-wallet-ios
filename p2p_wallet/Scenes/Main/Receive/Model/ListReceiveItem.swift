import Foundation
import SwiftUI

struct ListReceiveItem {
    var id: String
    var title: String
    var description: String
    var showTopCorners: Bool
    var showBottomCorners: Bool
    var isShort: Bool
}

extension ListReceiveItem: ReceiveRendableItem {
    func render() -> some View {
        ListReceiveItemView(item: self)
    }
}
