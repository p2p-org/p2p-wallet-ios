//
//  SentViaLinkTransactionDetailView.swift
//  p2p_wallet
//
//  Created by Chung Tran on 22/03/2023.
//

import SwiftUI
import Combine
import KeyAppUI
import Resolver
import Send

struct SentViaLinkTransactionDetailView: View {
    // MARK: - Dependencies

    @Injected private var notificationService: NotificationService
    @Injected private var sendViaLinkDataService: SendViaLinkDataService
    
    // MARK: - Properties
    
    let transactionPublisher: AnyPublisher<SendViaLinkTransactionInfo, Never>
    @State private var transaction: SendViaLinkTransactionInfo?
    
    let onShare: () -> Void
    let onClose: () -> Void
    
    // MARK: - Computed properties

    var link: String? {
        guard let seed = transaction?.seed,
              let link = sendViaLinkDataService.createURL(givenSeed: seed)?.absoluteString
        else {
            return nil
        }
        return link
    }
    
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
                .apply(style: .title3)
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
            if let urlString = transaction?.token.logoURI,
               let url = URL(string: urlString)
            {
                TransactionDetailIconView(icon: .single(url))
            }
            
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
                Text(link)
                    .fontWeight(.semibold)
                    .apply(style: .text3)
                Text(L10n.uniqueOneTimeLinkWorksOnceOnly)
                    .apply(style: .label1)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
            }
            
            Spacer()
            
            Button {
                let pasteboard = UIPasteboard.general
                pasteboard.string = link
                notificationService.showInAppNotification(.done(L10n.copiedToClipboard))
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
            
            Text(L10n.TheOneTimeLinkCanBeUsedToSendFundsToAnyoneWithoutNeedingAnAddress
                .theFundsCanBeClaimedByAnyoneWithALink
            )
                .apply(style: .text4)
                .frame(height: 70)
        }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
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
            onClose()
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
            .padding(.bottom, 8)
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
