//
//  SentViaLinkTransactionDetailView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/03/2023.
//

import SwiftUI
import Combine
import KeyAppUI

struct SentViaLinkTransactionDetailView: View {
    // MARK: - Properties
    
    let transactionPublisher: AnyPublisher<SendViaLinkTransactionInfo, Never>
    @State private var transaction: SendViaLinkTransactionInfo?
    
    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Indicator
            RoundedRectangle(cornerRadius: 2)
                .frame(width: 31, height: 4)
                .foregroundColor(Color(Asset.Colors.rain.color))
                .padding(.top, 6)
                .padding(.bottom, 18)
            
            // Header
            Text(L10n.sentViaOneTimeLink)
                .fontWeight(.semibold)
                .apply(style: .title1)
                .padding(.bottom, 4)
            
            // Subtitle
            Text("\(transaction?.creationDayInString ?? L10n.unknownDate) @ \(transaction?.creationTimeInString ?? L10n.unknownTime)")
                .apply(style: .text3)
                .foregroundColor(Color(Asset.Colors.mountain.color))
                .padding(.bottom, 20)
            
            // Tokens info
            tokensInfo
            
            // Links info
            linksInfo
        }
            .cornerRadius(radius: 20, corners: .allCorners)
            .onReceive(transactionPublisher) { transaction in
                self.transaction = transaction
            }
    }
    
    // MARK: - ViewBuilders

    private var tokensInfo: some View {
        VStack(alignment: .center) {
            // Logo
            CoinLogoImageViewRepresentable(
                size: 64,
                token: transaction?.token
            )
            .frame(width: 64, height: 64)
            .cornerRadius(radius: 64/2, corners: .allCorners)
            
            // Amount in fiat
            Text("- \(transaction?.amountInFiat.fiatAmountFormattedString() ?? "")")
                .fontWeight(.bold)
                .apply(style: .largeTitle)
                .padding(.bottom, 4)
            
            // Amount in token
            Text(transaction?.amount.tokenAmountFormattedString(symbol: transaction?.token.symbol ?? ""))
                .apply(style: .text2)
                .foregroundColor(Color(Asset.Colors.mountain.color))
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(Color(Asset.Colors.smoke.color))
    }
    
    private var linksInfo: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(String.sendViaLinkPrefix + "/" + (transaction?.seed ?? ""))
                    .fontWeight(.semibold)
                    .apply(style: .text3)
                Text(L10n.uniqueOneTimeLinkWorksOnceOnly)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            
            Spacer()
            
            Button {
                guard let seed = transaction?.seed else {
                    return
                }
                let pasteboard = UIPasteboard.general
                pasteboard.string = String.sendViaLinkPrefix + "/" + seed
            } label: {
                Image(uiImage: .copyFill)
                    .resizable()
                    .frame(width: 24, height: 24)
            }
        }
            .padding(.init(top: 36, leading: 16, bottom: 32, trailing: 16))
    }
}

#if DEBUG
struct SentViaLinkTransactionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SentViaLinkTransactionDetailView(
            transactionPublisher: Just([SendViaLinkTransactionInfo].mocked.first!)
                .eraseToAnyPublisher()
        )
    }
}
#endif
