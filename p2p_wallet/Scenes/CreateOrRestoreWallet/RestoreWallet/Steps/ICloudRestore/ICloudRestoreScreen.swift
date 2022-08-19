// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
import Onboarding
import SwiftUI

struct ICloudRestoreScreen: View {
    @ObservedObject var viewModel: ICloudRestoreViewModel

    var body: some View {
        VStack {
            Spacer()
            content
            Spacer()
            bottomAction
        }
        .navigationBarTitle(Text(L10n.createANewWallet), displayMode: .inline)
        .navigationBarItems(
            leading: Button(
                action: { [weak viewModel] in viewModel?.back() },
                label: {
                    Image(uiImage: Asset.MaterialIcon.arrowBackIos.image)
                        .foregroundColor(Color(Asset.Colors.night.color))
                }
            ),
            trailing: Button(
                action: { [weak viewModel] in viewModel?.info() },
                label: {
                    Image(uiImage: Asset.MaterialIcon.helpOutline.image)
                        .foregroundColor(Color(Asset.Colors.night.color))
                }
            )
        )
        .background(Color(Asset.Colors.lime.color))
        .edgesIgnoringSafeArea(.all)
        .frame(maxHeight: .infinity)
    }

    var content: some View {
        VStack(spacing: .zero) {
            if viewModel.accounts.count <= 5 {
                Image(uiImage: .introWelcomeToP2pFamily)
                    .resizable()
                    .scaledToFit()
                    .frame(minHeight: viewModel.accounts.count < 3 ? 200 : 90)
            }

            Text(L10n.chooseYourWallet)
                .font(.system(size: UIFont.fontSize(of: .largeTitle), weight: .bold))
                .foregroundColor(Color(Asset.Colors.night.color))
                .multilineTextAlignment(.center)
                .padding(.top, 24)

            Text("\(viewModel.accounts.count) Wallets found")
                .font(.system(size: UIFont.fontSize(of: .title3), weight: .regular))
                .foregroundColor(Color(Asset.Colors.night.color))
                .multilineTextAlignment(.center)
                .padding(.top, 16)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 40)
        .padding(.top, 54)
    }

    var bottomAction: some View {
        BottomActionContainer(topPadding: 0) {
            if viewModel.accounts.count <= 5 {
                VStack {
                    ForEach(viewModel.accounts) { account in
                        walletCell(account: account)
                    }
                }.padding(.top, 20)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack {
                        ForEach(viewModel.accounts) { account in
                            walletCell(account: account)
                        }
                    }.padding(.top, 20)
                }
            }
        }.disabled(viewModel.loading == true)
    }

    func walletCell(account: ICloudAccount) -> some View {
        ICloudWalletCell(
            name: account.name,
            publicKey: account.publicKey
        ) { [weak viewModel] in viewModel?.restore(account: account) }
    }
}

struct ICloudRestoreScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ICloudRestoreScreen(
                viewModel: .init(
                    accounts: (0 ..< 16).map { i in
                        .init(
                            name: i % 2 == 0 ? "kirill.p2p.sol" : nil,
                            phrase: "",
                            derivablePath: .default,
                            publicKey: randomString(length: 32)
                        )
                    }
                )
            )
        }
    }
}

private func randomString(length: Int) -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0 ..< length).map { _ in letters.randomElement()! })
}
