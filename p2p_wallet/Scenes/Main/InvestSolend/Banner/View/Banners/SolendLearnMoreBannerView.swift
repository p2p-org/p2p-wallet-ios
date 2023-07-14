//
//  SolendLearnMoreBanner.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.10.2022.
//

import SwiftUI

struct SolendLearnMoreBannerView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text(L10n.depositYourTokensAndEarn)
                .font(uiFont: .font(of: .title3, weight: .semibold))
            Text(L10n.AllYourFundsAreInsured.withdrawYourDepositWithAllRewardsAtAnyTime)
                .font(uiFont: .font(of: .text4))
                .multilineTextAlignment(.center)
                .frame(height: 32)
            Text(L10n.learnMore)
                .font(uiFont: .font(of: .text2, weight: .semibold))
                .frame(height: 48)
                .frame(maxWidth: .infinity)
                .background(Color(.snow))
                .cornerRadius(12)
                .padding(.top, 8)
        }
        .modifier(SolendBannerViewModifier(backgroundColor: Color(.lime)))
    }
}

struct SolendLearnMoreBanner_Previews: PreviewProvider {
    static var previews: some View {
        SolendLearnMoreBannerView()
    }
}
