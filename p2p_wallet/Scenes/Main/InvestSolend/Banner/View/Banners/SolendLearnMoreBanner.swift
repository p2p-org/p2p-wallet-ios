//
//  SolendLearnMoreBanner.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 05.10.2022.
//

import SwiftUI
import KeyAppUI

struct SolendLearnMoreBanner: View {
    var body: some View {
        VStack(spacing: 12) {
            Text(L10n.depositYourTokensAndEarn)
                .font(uiFont: .font(of: .title3, weight: .semibold))
            Text(L10n.AllYourFundsAreInsured.withdrawYourDepositWithAllRewardsAtAnyTime)
                .font(uiFont: .font(of: .text4))
                .multilineTextAlignment(.center)
            Text(L10n.learnMore)
                .font(uiFont: .font(of: .text2, weight: .semibold))
                .frame(height: 48)
                .frame(maxWidth: .infinity)
                .background(Color(Asset.Colors.snow.color))
                .cornerRadius(12)
                .padding(.top, 8)
        }
        .modifier(SolendBanner(backgroundColor: Color(Asset.Colors.lime.color)))
    }
}

struct SolendLearnMoreBanner_Previews: PreviewProvider {
    static var previews: some View {
        SolendLearnMoreBanner()
    }
}
