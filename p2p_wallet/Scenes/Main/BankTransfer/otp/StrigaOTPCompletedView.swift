import KeyAppUI
import SwiftUI

struct StrigaOTPCompletedView: View {
    let image: UIImage
    let title: String?
    let subtitle: String
    let actionTitle: String
    let onAction: (() -> Void)?
    let onHelp: (() -> Void)?

    public init(
        image: UIImage,
        title: String? = nil,
        subtitle: String? = nil,
        actionTitle: String,
        onAction: (() -> Void)? = nil,
        onHelp: (() -> Void)? = nil
    ) {
        self.image = image
        self.title = title
        self.subtitle = subtitle ?? ""
        self.actionTitle = actionTitle
        self.onAction = onAction
        self.onHelp = onHelp
    }

    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Image(uiImage: image)
                    .padding(.top, 135.adaptiveHeight)
                    .padding(.bottom, title == nil ? 32: 16)

                if let title {
                    Text(title)
                        .fontWeight(.bold)
                        .apply(style: .title2)
                        .padding(.bottom, 12)
                }

                Text(subtitle)
                    .apply(style: .text1)
                    .multilineTextAlignment(.center)

                Spacer()
                if let onAction {
                    NewTextButton(
                        title: actionTitle,
                        style: .primaryWhite,
                        trailing: .arrowForward,
                        action: onAction
                    )
                }
            }
            .padding(.bottom, 66)
            .padding(.horizontal, 16)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    onHelp?()
                } label: {
                    Image(uiImage: Asset.MaterialIcon.helpOutline.image)
                }
            }
        }
    }
}
