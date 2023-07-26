import Foundation
import SwiftUI

struct SpacerReceiveItem {
    var id: String = UUID().uuidString
    var height: CGFloat = 8
    var width: CGFloat = 8
}

extension SpacerReceiveItem: ReceiveRendableItem {
    func render() -> some View {
        Color(UIColor.clear)
            .frame(width: width, height: height)
    }
}
