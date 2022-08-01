import KeyAppUI
import SwiftUI

extension View {
    func bottomActionsStyle() -> some View {
        background(Color(Asset.Colors.night.color))
            .cornerRadius(radius: 16, corners: [.topLeft, .topRight])
    }
}
