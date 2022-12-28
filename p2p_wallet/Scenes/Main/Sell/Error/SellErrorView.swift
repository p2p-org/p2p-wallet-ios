//
//  SellErrorView.swift
//  p2p_wallet
//
//  Created by Ivan on 28.12.2022.
//

import Combine
import SwiftUI
import KeyAppUI

struct SellErrorView: View {
    let goBack: () -> Void

    init(goBack: @escaping () -> Void) {
        self.goBack = goBack
    }
    
    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 30) {
                Image(uiImage: .catFail)
                VStack(spacing: 8) {
                    Text(L10n.sorry)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .title1, weight: .bold))
                    Text(L10n.OurServiceWasRuined.visitThisPageLater)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .text1))
                }
            }
            Spacer()
            TextButtonView(
                title: L10n.goBack,
                style: .primaryWhite,
                size: .large
            ) {
                goBack()
            }
            .frame(height: 56)
            .padding(.bottom, 32)
            .padding(.horizontal, 23)
        }
    }
}
