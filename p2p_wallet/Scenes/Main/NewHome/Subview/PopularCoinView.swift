import SwiftUI

struct PopularCoinView: View {
    let title: String
    let subtitle: String?
    let actionTitle: String
    let image: ImageResource

    init(
        title: String,
        subtitle: String?,
        actionTitle: String,
        image: ImageResource
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.image = image
    }

    var body: some View {
        ZStack {
            Color(.snow)
                .frame(height: 74)
                .cornerRadius(16)
            HStack {
                HStack(spacing: 12) {
                    Image(image)
                        .frame(width: 48, height: 48)
                        .cornerRadius(16)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .foregroundColor(Color(.night))
                            .font(uiFont: .font(of: .text2))
                        if let subtitle {
                            Text(subtitle)
                                .foregroundColor(Color(.mountain))
                                .font(uiFont: .font(of: .label1))
                        }
                    }
                    .font(uiFont: .font(of: .text1, weight: .semibold))
                }
                .padding(.leading, 16)
                Spacer()
                Text(actionTitle)
                    .foregroundColor(Color(.night))
                    .font(uiFont: .font(of: .text4, weight: .semibold))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.rain))
                    .cornerRadius(8)
                    .frame(height: 32)
                    .padding(.trailing, 16)
            }
        }
    }
}

struct PopularCoinView_Previews: PreviewProvider {
    static var previews: some View {
        PopularCoinView(title: "USDC", subtitle: "USD Coint", actionTitle: "Buy", image: .usdc)
    }
}
