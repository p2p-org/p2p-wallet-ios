import KeyAppUI
import SwiftUI

struct SendEmptyRowView: View {
    private let image: ImageResource
    private let text: String
    private let textAccessibilityIdentifier: String

    init(image: ImageResource, text: String, textAccessibilityIdentifier: String) {
        self.image = image
        self.text = text
        self.textAccessibilityIdentifier = textAccessibilityIdentifier
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .frame(width: 48, height: 48)
                    .foregroundColor(Color(.rain))
                Image(image)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color(.mountain))
                    .frame(width: 20, height: 20)
            }
            Text(text)
                .apply(style: .text3)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(Color(.night))
                .accessibilityIdentifier(textAccessibilityIdentifier)
        }
    }
}

struct SendEmptyRowView_Previews: PreviewProvider {
    static var previews: some View {
        SendEmptyRowView(image: .user, text: L10n.receive, textAccessibilityIdentifier: "")
    }
}
