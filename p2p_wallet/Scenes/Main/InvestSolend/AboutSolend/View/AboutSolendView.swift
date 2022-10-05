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

    @State private var index = 0

    var body: some View {
        VStack(spacing: 26) {
            PagingView(
                index: $index.animation(),
                maxIndex: 2,
                fillColor: Color(Asset.Colors.night.color),
                withSpacers: false
            ) {
                AboutSolendSlideView(
                    image: .whatIsSolendFirst,
                    subtitle: L10n
                        .SolendIsTheMostScalableDeFiLendingProtocolWhichAllowsToEarnInterestAndBorrowAssetsWithTheLowestFee
                        .thatSWhyWeIntegrateIt
                )
                AboutSolendSlideView(
                    image: .whatIsSolendSecond,
                    subtitle: L10n.depositWithInterestDepositUSDTOrUSDCAndGetYourGuaranteedYieldOnIt
                )
                AboutSolendSlideView(
                    image: .whatIsSolendThird,
                    subtitle: L10n
                        .ControlYourAssetsLowRisksAllYourAssetsAreUnderYourControl
                        .instantWithdrawalWithAllRewards
                )
            }
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
    var viewHeight: CGFloat { 514 }
}
