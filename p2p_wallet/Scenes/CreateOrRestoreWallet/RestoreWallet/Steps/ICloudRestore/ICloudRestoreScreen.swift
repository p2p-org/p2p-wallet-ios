// Copyright 2022 P2P Validator Authors. All rights reserved.
// Use of this source code is governed by a MIT-style license that can be
// found in the LICENSE file.

import KeyAppUI
import SwiftUI

struct ICloudRestoreScreen: View {
    @ObservedObject var viewModel: ICloudRestoreViewModel

    var body: some View {
        VStack {
            Spacer()
            content
            Spacer()
            BottomActionContainer {
                LazyVStack {
                    ForEach(viewModel.accounts) { account in
                        ICloudWalletCell(
                            name: account.name,
                            publicKey: account.publicKey
                        ) {}
                    }
                }
            }
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
        OnboardingContentView(
            data: .init(
                image: .introWelcomeToP2pFamily,
                title: "Choose your wallet",
                subtitle: "3 Wallets found"
            )
        ).padding(.horizontal, 40)
    }
}

struct ICloudRestoreScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ICloudRestoreScreen(
                viewModel: .init(
                    accounts: [
                        .init(
                            name: "kirill.p2p.sol",
                            phrase: "",
                            derivablePath: .default,
                            publicKey: "HAE1oNnc3XBmPudphRcHhyCvGShtgDYtZVzx2MocKEr1"
                        ),
                    ]
                )
            )
        }
    }
}
