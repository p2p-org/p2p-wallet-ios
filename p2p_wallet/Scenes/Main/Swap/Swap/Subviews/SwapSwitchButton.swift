import Combine
import SwiftUI

struct SwapSwitchButton: View {
    let action: PassthroughSubject<Void, Never>

    var body: some View {
        Button(action: action.send, label: {
            Image(.swapArrows)
        })
        .accessibilityIdentifier("SwapView.switchButton")
        .background(
            Circle()
                .foregroundColor(Color(.rain))
                .frame(width: 36, height: 36)
        )
    }
}
