//
//  DepositSolendView.swift
//  p2p_wallet
//
//  Created by Giang Long Tran on 15.09.2022.
//

import KeyAppUI
import SwiftUI

struct DepositSolendView: View {
    @SwiftUI.Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @StateObject var viewModel: DepositSolendViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            InvestSolendCell(
                asset: viewModel.invest.asset,
                deposit: viewModel.invest.userDeposit?.depositedAmount,
                apy: viewModel.invest.market?.supplyInterest
            ).padding(.top, 8)

            Spacer()

            HStack {
                Text(L10n.enterTheAmount)
                    .apply(style: .text3)
                Spacer()
                Text("\(viewModel.inputLamport)")
            }.padding(.horizontal, 24)

            TextField("Deposit amount", text: $viewModel.input)
                .padding(.horizontal, 24)
                .frame(height: 60)
                .background(
                    Color(Asset.Colors.smoke.color)
                        .cornerRadius(radius: 12, corners: .allCorners)
                )
                .padding(.horizontal, 24)

            TextButtonView(
                title: L10n.deposit,
                style: .primary,
                size: .large,
                isEnabled: nil
            ) {
                Task {
                    try await viewModel.deposit()
                    presentationMode.wrappedValue.dismiss()
                }
            }
            .disabled(viewModel.loading)
            .frame(height: TextButton.Size.large.height)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .navigationTitle(L10n.depositIntoSolend)
    }
}

struct DepositSolendView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DepositSolendView(
                viewModel: try! .init(initialAsset: .init(
                    name: "Solana",
                    symbol: "SOL",
                    decimals: 9,
                    mintAddress: "",
                    logo: nil
                ),
                mocked: true)
            )
        }
    }
}
