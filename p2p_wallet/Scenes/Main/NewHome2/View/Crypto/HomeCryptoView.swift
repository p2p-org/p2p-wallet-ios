//
//  HomeCryptoView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 26.06.2023.
//

import KeyAppUI
import SwiftUI

struct HomeCryptoView: View {
    @ObservedObject var viewModel: HomeCryptoViewModel

    var body: some View {
        VStack {
            // Header
            HomeHeaderCard(
                title: "MY CRYPTO",
                balance: viewModel.totalAmountInFiat,
                balanceDetail: .icon(image: .solanaIcon)
            ) {
                HStack(spacing: 12) {
                    NewTextButton(
                        title: "Swap",
                        size: .small,
                        style: .primaryWhite,
                        expandable: true,
                        trailing: UIImage.swap
                    ) {
                        viewModel.actionSubject.send(.swap)
                    }
                    NewTextButton(
                        title: "Receive",
                        size: .small,
                        style: .second,
                        expandable: true,
                        trailing: Asset.MaterialIcon.arrowDownward.image
                    ) {
                        viewModel.actionSubject.send(.receive)
                    }
                }
            }

            HomeAccountListView(viewModel: .init(navigation: viewModel.actionSubject))
        }
    }
}

struct HomeCryptoView_Previews: PreviewProvider {
    static var previews: some View {
        HomeCryptoView(viewModel: .init(totalAmountInFiat: "$25", iconsURL: []))
    }
}
