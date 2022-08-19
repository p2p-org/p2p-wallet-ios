import KeyAppUI
import SwiftUI

extension View {
    func bottomActionsStyle() -> some View {
        padding(.horizontal, 20)
            .padding(.bottom, 34)
            .background(Color(Asset.Colors.night.color))
            .cornerRadius(radius: 24, corners: [.topLeft, .topRight])
    }
}
