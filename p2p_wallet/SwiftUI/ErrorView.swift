
import KeyAppUI
import SwiftUI

struct ErrorView: View {
    let title: String?
    let subtitle: String
    let onTryAgain: (() -> Void)?
    
    init(
        title: String? = nil,
        subtitle: String? = nil,
        onTryAgain: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle ?? L10n.oopsSomethingHappened
        self.onTryAgain = onTryAgain
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Image(uiImage: .catFail)
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
