import KeyAppUI
import SwiftUI

struct SendEmptyRowView: View {
    private let image: UIImage
    private let text: String

    init(image: UIImage, text: String) {
        self.image = image
        self.text = text
    }

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .frame(width: 48, height: 48)
                    .foregroundColor(Color(Asset.Colors.rain.color))
                Image(uiImage: image)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .frame(width: 20, height: 20)
            }
            Text(text)
                .apply(style: .text3)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(Color(Asset.Colors.night.color))
        }
    }
}

struct SendEmptyRowView_Previews: PreviewProvider {
    static var previews: some View {
        SendEmptyRowView(image: .user, text: L10n.receive)
    }
}
