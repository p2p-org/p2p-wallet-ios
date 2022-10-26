import KeyAppUI
import SwiftUI

struct BottomActionContainer<Content: View>: View {
    @SwiftUI.Environment(\.safeAreaInsets) private var safeAreaInsets: EdgeInsets
    let topPadding: Double
    let child: Content

    init(topPadding: Double = 20, @ViewBuilder child: () -> Content) {
        self.topPadding = topPadding
        self.child = child()
    }

    var body: some View {
        child
            .padding(.horizontal, 20)
            .padding(.top, topPadding)
            .padding(.bottom, max(safeAreaInsets.bottom, 20))
            .background(Color(Asset.Colors.night.color))
            .cornerRadius(radius: 24, corners: [.topLeft, .topRight])
    }
}
