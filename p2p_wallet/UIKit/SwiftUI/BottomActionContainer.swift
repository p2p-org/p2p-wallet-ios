import KeyAppUI
import SwiftUI

struct BottomActionContainer<Content: View>: View {
    @SwiftUI.Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets
    @ViewBuilder let child: Content

    var body: some View {
        child
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, max(safeAreaInsets.bottom, 20))
            .background(Color(Asset.Colors.night.color))
            .cornerRadius(radius: 24, corners: [.topLeft, .topRight])
    }
}
