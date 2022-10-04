//
//  EarnBannerView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 30/09/2022.
//

import SwiftUI

struct EarnBannerView: View {
    var showEarnScene: () -> Void
    var closeAction: () -> Void

    var body: some View {
        ZStack {
            VStack {
                Color(._644aff)
                    .cornerRadius(12)
                    .padding(.top, 23)
            }

            HStack {
                Spacer()
                Image(uiImage: .earnBanner)
                    .frame(width: 206, height: 142)
            }
            .frame(maxWidth: .infinity)

            HStack(alignment: .center) {
                VStack(alignment: .leading) {
                    Text(L10n.earnUpTo(4))
                        .font(uiFont: .systemFont(ofSize: 16, weight: .medium))
                        .foregroundColor(.white)

                    Text(L10n.stakeYourTokensAndGetRewardsEveryDay)
                        ._lineHeightMultiple(1.26)
                        .font(uiFont: .systemFont(ofSize: 14))
                        .foregroundColor(Color(.bdbdbd))
                }
                .padding(.top, 23)
                .padding(.leading, 24)

                Spacer(minLength: 32)

                TextButtonView(title: L10n.earn, style: .third, size: .medium, isEnabled: .constant(true)) {
                    showEarnScene()
                }
                .frame(width: 100, height: 32)
                .padding(.top, 56)
                .padding(.trailing, 38)
            }
            .frame(maxWidth: .infinity)

            HStack {
                Spacer()
                VStack {
                    Button {
                        closeAction()
                    } label: {
                        Image(uiImage: .bannerClose)
                            .resizable()
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(PlainButtonStyle()) // prevent getting called on tapping cell
                    .padding(.top, 30)
                    .padding(.trailing, 5)
                    Spacer()
                }
            }
        }
    }
}

struct EarnBannerView_Previews: PreviewProvider {
    static var previews: some View {
        EarnBannerView {} closeAction: {}
    }
}
