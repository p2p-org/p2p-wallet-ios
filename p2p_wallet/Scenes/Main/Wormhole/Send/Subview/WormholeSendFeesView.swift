//
//  WormholeSendFeesView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 24.03.2023.
//

import KeyAppUI
import Send
import SwiftUI

struct WormholeSendFeesView: View {
    @ObservedObject var viewModel: WormholeSendFeesViewModel

    var body: some View {
        ForEach(viewModel.fees) { fee in
            VStack(alignment: .leading, spacing: 4) {
                Text(fee.title)
                    .apply(style: .text3)
                    .foregroundColor(Color(Asset.Colors.night.color))
                HStack {
                    Text(fee.subtitle)
                        .apply(style: .label1)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                    Spacer()
                    Text(fee.detail)
                        .apply(style: .label1)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                }
            }
            .frame(height: 64)
        }
        .padding(.horizontal, 16)
    }
}

struct WormholeSendFeesView_Previews: PreviewProvider {
    static var previews: some View {
        WormholeSendFeesView(
            viewModel: .init(
                fees: [
                    .init(title: "Recipient’s address", subtitle: "0x0ea9f413a9be5afcec51d1bc8fd20b29bef5709c", detail: nil),
                    .init(title: "Network Fees", subtitle: "0.003 WETH", detail: "$ 3.31"),
                    .init(title: "Using Wormhole bridge", subtitle: "0.0005 SOL", detail: "$ 0.05")
                ].compactMap { $0 }
            )
        )
    }
}
