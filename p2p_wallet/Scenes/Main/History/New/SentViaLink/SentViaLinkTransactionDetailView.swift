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
    
    let onShare: () -> Void
    let onClose: () -> Void
    
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
            
            // One time link info
            oneTimeLinkInfo
            
            // Share button
            shareButton
            
            // Close button
            closeButton
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
    
    private var oneTimeLinkInfo: some View {
        HStack(alignment: .center, spacing: 12) {
            
            Image(uiImage: .infoFill)
                .resizable()
                .frame(width: 20, height: 20)
                .foregroundColor(Color(Asset.Colors.night.color))
                .padding(14)
                .background(Color(Asset.Colors.smoke.color))
                .cornerRadius(radius: 24, corners: .allCorners)
            
            Text(L10n.TheOneTimeLinkCanBeUsedToSendFundsToAnyoneWithoutNeedingAnAddress.theFundsCanBeClaimedByAnyoneWithALink)
                .apply(style: .text4)
        }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(Asset.Colors.cloud.color))
            .cornerRadius(radius: 12, corners: .allCorners)
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
    }
    
    private var shareButton: some View {
        Button {
            onShare()
        } label: {
            HStack {
                Spacer()
                Text(L10n.share)
                    .fontWeight(.semibold)
                    .apply(style: .text3)
                    .foregroundColor(Color(Asset.Colors.snow.color))
                Spacer()
            }
                .padding(.vertical, 16)
                .padding(.horizontal, 19)
                .background(Color(Asset.Colors.night.color))
                .cornerRadius(radius: 12, corners: .allCorners)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
        }

    }
    
    private var closeButton: some View {
        Button {
            onShare()
        } label: {
            HStack {
                Spacer()
                Text(L10n.close)
                    .fontWeight(.semibold)
                    .apply(style: .text3)
                    .foregroundColor(Color(Asset.Colors.night.color))
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 19)
            .cornerRadius(radius: 12, corners: .allCorners)
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }
}

#if DEBUG
struct SentViaLinkTransactionDetailView_Previews: PreviewProvider {
    static var previews: some View {
        SentViaLinkTransactionDetailView(
            transactionPublisher: Just([SendViaLinkTransactionInfo].mocked.first!)
                .eraseToAnyPublisher(),
            onShare: {},
            onClose: {}
        )
    }
}
#endif
