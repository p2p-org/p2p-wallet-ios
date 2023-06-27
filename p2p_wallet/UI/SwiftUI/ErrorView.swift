
import KeyAppUI
import SwiftUI

public struct ErrorView: View {
    public let title: String?
    public let subtitle: String
    public let onTryAgain: (() -> Void)?
    
    public init(
        title: String? = nil,
        subtitle: String? = nil,
        onTryAgain: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle ?? L10n.oopsSomethingHappened
        self.onTryAgain = onTryAgain
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            Image(.catFail)
                .padding(.top, 24)
                .padding(.bottom, title == nil ? 32: 20)

            if let title {
                Text(title)
                    .font(uiFont: .font(of: .largeTitle, weight: .bold))
                    .padding(.bottom, 8)
            }
            
            Text(subtitle)
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)

            if let onTryAgain {
                TextButtonView(title: L10n.tryAgain, style: .second, size: .large) {
                    onTryAgain()
                }
                .frame(height: TextButton.Size.large.height)
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }
}

struct HistoryErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(title: "Sorry") {}
    }
}
