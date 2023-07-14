import SwiftUI

struct ICloudWalletCell: View {
    let name: String?
    let publicKey: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }, label: {
            HStack {
                Image(.accountBalanceWalletOutlined)
                    .aspectRatio(1, contentMode: .fit)
                    .foregroundColor(Color(.mountain))
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color(.rain)))
                    .padding(.leading, 16)

                if let name = name {
                    // With name
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(uiFont: UIFont.font(of: .text2, weight: .regular))
                        HStack(spacing: 0) {
                            Text(String(publicKey.dropLast(4)))
                                .foregroundColor(Color(.mountain))
                                .lineLimit(1)
                            Text(publicKey.suffix(4))
                                .foregroundColor(Color(.mountain))
                                .lineLimit(1)
                        }.font(uiFont: UIFont.font(of: .label1, weight: .regular))
                    }
                    .padding(.leading, 12)
                    .padding(.trailing, 8)
                } else {
                    // Without name
                    HStack(spacing: 0) {
                        Text(String(publicKey.dropLast(4)))
                        Text(publicKey.suffix(4))
                    }
                    .foregroundColor(Color(.night))
                    .font(uiFont: UIFont.font(of: .text2, weight: .regular))
                    .lineLimit(1)
                }

                Spacer()
                Image(.chevronRight)
                    .foregroundColor(Color(.mountain))
                    .padding(.trailing, 14)
            }
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.snow))
            )
        }).buttonStyle(CustomHighlightColor())
    }
}

private struct CustomHighlightColor: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration
            .label
            .overlay(configuration.isPressed ? Color(.mountain).opacity(0.2) : Color.clear)
    }
}

struct ICloudWalletCell_Previews: PreviewProvider {
    static var previews: some View {
        ICloudWalletCell(
            name: "kirill.p2p.sol",
            publicKey: "FG4Y3yX4AAchp1HvNZ7LfzFTrdpT"
        ) {}
            .previewLayout(.sizeThatFits)
            .background(Color.black)
    }
}
