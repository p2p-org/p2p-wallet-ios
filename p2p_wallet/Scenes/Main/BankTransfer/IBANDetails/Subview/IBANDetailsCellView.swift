import SwiftUI
import KeyAppUI

struct IBANDetailsCellViewItem: Identifiable {
    let title: String
    let subtitle: String
    let copyAction: (() -> Void)?
    var id: String { title }
}

extension IBANDetailsCellViewItem: Renderable {
    func render() -> some View {
        IBANDetailsCellView(data: self)
    }
}

struct IBANDetailsCellView: View {
    let data: IBANDetailsCellViewItem

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(data.title)
                    .apply(style: .text3, weight: .semibold)
                    .foregroundColor(Color(asset: Asset.Colors.night))

                Text(data.subtitle)
                    .apply(style: .label1)
                    .foregroundColor(Color(asset: Asset.Colors.mountain))
            }

            Spacer()

            if let action = data.copyAction {
                Button(action: action) {
                    Image(uiImage: .copyLined)
                        .padding(.all, 8)
                }
            }
        }
        .padding(.all, 16)
    }
}
