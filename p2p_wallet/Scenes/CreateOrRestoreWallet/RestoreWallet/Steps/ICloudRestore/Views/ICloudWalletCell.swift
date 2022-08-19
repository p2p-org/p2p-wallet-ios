//
//  ICloudWalletCell.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 18.08.2022.
//

import KeyAppUI
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
                Image(uiImage: Asset.MaterialIcon.accountBalanceWalletOutlined.image)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(Color(Asset.Colors.rain.color)))
                    .padding(.leading, 16)

                if let name = name {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(uiFont: UIFont.font(of: .text2, weight: .regular))
                        HStack(spacing: 0) {
                            Text(String(publicKey.dropLast(4)))
                                .foregroundColor(Color(Asset.Colors.mountain.color))
                                .lineLimit(1)
                            Text(publicKey.suffix(4))
                                .foregroundColor(Color(Asset.Colors.mountain.color))
                                .lineLimit(1)
                        }.font(uiFont: UIFont.font(of: .label1, weight: .regular))
                    }
                    .padding(.leading, 12)
                    .padding(.trailing, 8)
                }

                Image(uiImage: Asset.MaterialIcon.chevronRight.image)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .padding(.trailing, 14)
            }
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(Asset.Colors.snow.color))
            )
        }).buttonStyle(CustomHighlightColor())
    }
}

private struct CustomHighlightColor: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration
            .label
            .overlay(configuration.isPressed ? Color(Asset.Colors.mountain.color.withAlphaComponent(0.2)) : Color.clear)
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
