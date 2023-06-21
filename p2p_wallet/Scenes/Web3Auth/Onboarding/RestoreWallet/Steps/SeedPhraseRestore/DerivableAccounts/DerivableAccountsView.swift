import SwiftUI
import KeyAppUI

struct DerivableAccountsView: View {

    @ObservedObject private var viewModel: DerivableAccountsViewModel

    init(viewModel: DerivableAccountsViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 16) {
            DerivableAccountsCardView(derivationPath: viewModel.selectedDerivablePath.title)
                .padding(.top, 8)
                .padding(.horizontal, 16)
                .onTapGesture {
                    viewModel.selectDerivableType.send(viewModel.selectedDerivablePath)
                }

            Text(L10n.ThisIsTheThingYouUseToGetAllYourAccountsFromYourMnemonicPhrase.byDefaultKeyAppWillUseM4450100AsTheDerivationPathForTheMainWallet)
                .apply(style: .text3)
                .foregroundColor(Color(Asset.Colors.night.color))
                .padding(.all, 18)
                .background(Color(Asset.Colors.cloud.color))
                .cornerRadius(radius: 12, corners: .allCorners)
                .padding(.horizontal, 16)

            WrappedList {
                ForEach(viewModel.data) { account in
                    DerivableAccountsItemView(account: account)
                        .frame(height: 72)
                        .padding(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                        .disabled(viewModel.loading)
                        .onTapGesture {
                            viewModel.selectDerivablePath(account.derivablePath)
                        }
                }
            }
        }
        .onboardingNavigationBar(title: L10n.derivableAccounts, onBack: { [weak viewModel] in
            viewModel?.back.send()
        })
    }
}
