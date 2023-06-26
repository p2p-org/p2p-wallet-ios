//
//  HomeHeaderCard.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 25/06/2023.
//

import KeyAppUI
import SwiftUI

struct HomeHeaderCard<Action: View>: View {
    
    enum BalanceDetail {
        case urls(value: [URL])
        case icon(image: UIImage)
    }
    
    let balance: String
    let balanceDetail: BalanceDetail
    @ViewBuilder var actionView: Action
    
    
    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            VStack(alignment: .leading, spacing: 12) {
                Button {} label: {
                    Text("All Accounts")
                        .font(.custom("SF Pro Text", size: 16))
                        .fontWeight(.regular)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                    Image(uiImage: UIImage.chevronDown)
                        .foregroundColor(Color(Asset.Colors.silver.color))
                }

                HStack(spacing: 4) {
                    Text(balance)
                        .font(.custom("SF Pro Rounded", size: 44))
                    Spacer()
                    switch balanceDetail {
                    case let .icon(image):
                        Image(uiImage: image)
                    case let .urls(value):
                        HorizontalTokenIconView(icons: value)
                    }
                }
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            
            actionView
                .padding(.bottom, 24)
                .padding(.horizontal, 24)
        }
        .background(Color(Asset.Colors.snow.color)).cornerRadius(radius: 20, corners: .allCorners)
        .padding(.horizontal, 16)
    }
}

struct HomeHeaderCard_Previews: PreviewProvider {
    static var previews: some View {
        HomeHeaderCard(balance: "$0", balanceDetail: .icon(image: UIImage.appleIcon)) {
            HStack(spacing: 12) {
                NewTextButton(
                    title: "Add money",
                    size: .small,
                    style: .primaryWhite,
                    expandable: true,
                    trailing: Asset.MaterialIcon.add.image
                ) {}
                NewTextButton(
                    title: "Withdraw",
                    size: .small,
                    style: .second,
                    expandable: true,
                    trailing: Asset.MaterialIcon.arrowUpward.image
                ) {}
            }
        }
    }
}
