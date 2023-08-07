import Foundation
import SwiftUI

struct RefundBannerReceiveItem {
    var id: String = UUID().uuidString
    let text: String
}

extension RefundBannerReceiveItem: ReceiveRendableItem {
    func render() -> some View {
        RefundBannerReceiveView(item: self)
    }
}
