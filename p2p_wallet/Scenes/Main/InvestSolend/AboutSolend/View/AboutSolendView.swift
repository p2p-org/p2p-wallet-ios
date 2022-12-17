//
//  AboutSolendView.swift
//  p2p_wallet
//
//  Created by Ivan on 03.10.2022.
//

import Combine
import KeyAppUI
import SwiftUI

struct AboutSolendView: View {
    private let cancelSubject = PassthroughSubject<Void, Never>()
    var cancel: AnyPublisher<Void, Never> { cancelSubject.eraseToAnyPublisher() }

    var body: some View {
        VStack(spacing: 26) {
            PagingView(
                fillColor: Color(Asset.Colors.night.color),
                content: [
                    PageContent {
                        AboutSolendSlideView(
                            image: .whatIsSolendFirst,
                            title: L10n.easyWayToInvest,
                            subtitle: L10n
                                .solendIsOneOfTheMostScalableFastestAndLowestFeeDeFiLendingProtocolThatAllowsYouToEarnInterestOnYourAssets
                        )
                    },
                    PageContent {
                        AboutSolendSlideView(
                            image: .whatIsSolendSecond,
                            title: L10n.earnInterestOnYourCrypto,
                            subtitle: L10n.WeProvideYouWithThePossibilityToUseSecureAndTrustedProtocols.depositUSDTAndUSDCToEarnInterest
                        )
                    },
                    PageContent {
                        AboutSolendSlideView(
                            image: .whatIsSolendThird,
                            title: L10n.yourCryptoIsUnderControl,
                            subtitle: L10n.keepControlOfYourAssetsWithInstantWithdrawalsAtAnyTime
                        )
                    }
                ]
            )
            .padding(.top, 16)
            Button(
                action: {
                    cancelSubject.send()
                },
                label: {
                    Text(L10n.cancel)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .text2, weight: .semibold))
                        .frame(height: 56)
                        .frame(maxWidth: .infinity)
                        .background(Color(Asset.Colors.rain.color))
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }
            )
        }
        .padding(.bottom, 16)
        .sheetHeader(title: L10n.whatIsSolend) {
            cancelSubject.send()
        }
    }
}

// MARK: - View Height

extension AboutSolendView {
    var viewHeight: CGFloat { 543 }
}
