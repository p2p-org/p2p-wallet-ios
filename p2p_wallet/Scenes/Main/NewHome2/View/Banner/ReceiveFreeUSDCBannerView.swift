//
//  ReceiveFreeUSDCBannerView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 26/06/2023.
//

import KeyAppUI
import SwiftUI

struct ReceiveFreeUSDCBannerView: View {
    let onTap: () -> Void

    var body: some View {
        ZStack(alignment: .leading) {
            Color(UIColor(red: 0.804, green: 0.965, blue: 0.804, alpha: 1))
                .cornerRadius(radius: 16, corners: .allCorners)
            VStack(alignment: .leading, spacing: 8) {
                Text("Receive free USDC ")
                    .fontWeight(.semibold)
                    .apply(style: .text2)
                Text("Get rewarded when you send money to your friends")
                    .apply(style: .label1)

                NewTextButton(title: "Invite friends", size: .small, style: .inverted) {
                    onTap()
                }
                .padding(.top, 6)
            }
            .frame(maxWidth: 170)
            .padding(.vertical, 16)
            .padding(.leading, 16)
        }
        .frame(height: 138)
        .overlay(alignment: .topTrailing) {
            Button {} label: {
                Image(uiImage: UIImage.closeIcon)
            }
            .foregroundColor(Color(Asset.Colors.silver.color))
            .offset(x: -19.33, y: 19.33)
        }
        .overlay(alignment: .trailing) {
            Image(uiImage: UIImage.clap)
        }
    }
}

struct ReceiveFreeUSDCBannerView_Previews: PreviewProvider {
    static var previews: some View {
        ReceiveFreeUSDCBannerView {}
    }
}
