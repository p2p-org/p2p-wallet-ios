import SwiftUI
import KeyAppUI
import Combine

struct SwapSwitchButton: View {
    let action: PassthroughSubject<Void, Never>

    var body: some View {
        Button(action: action.send, label: {
            Image(uiImage: .swapArrows)
        })
        .accessibilityIdentifier("SwapView.switchButton")
        .background(
            Circle()
                .foregroundColor(Color(Asset.Colors.rain.color))
                .frame(width: 36, height: 36)
        )
    }
}
