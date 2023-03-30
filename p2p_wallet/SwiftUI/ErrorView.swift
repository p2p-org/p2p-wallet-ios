
import KeyAppUI
import SwiftUI

public struct ErrorView: View {
    public let onTryAgain: () -> Void
    
    public init(onTryAgain: @escaping () -> Void) {
        self.onTryAgain = onTryAgain
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: .catFail)
                .padding(.top, 24)

            Text(L10n.oopsSomethingHappened)
                .padding(.top, 32)
                .padding(.bottom, 24)

            TextButtonView(title: L10n.tryAgain, style: .second, size: .large) {
                onTryAgain()
            }
            .frame(height: TextButton.Size.large.height)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
    }
}

struct HistoryErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView() {}
    }
}
