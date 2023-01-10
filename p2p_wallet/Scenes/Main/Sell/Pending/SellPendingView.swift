import Combine
import SwiftUI
import KeyAppUI
import Sell

struct SellPendingView: View {
    @ObservedObject var viewModel: SellPendingViewModel

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            VStack {
                VStack(spacing: 28) {
                    Text(L10n.pleaseSendCryptoToMoonPayAddress)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(Asset.Colors.night.color))
                        .font(uiFont: .font(of: .title2, weight: .bold))
                        .padding(.horizontal, 20)
                        .padding(.top, 13)
                    tokenView
                    VStack(spacing: 16) {
                        infoBlockView
                        textView
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, 16)
                }
                Spacer()
                VStack(spacing: 12) {
                    Button(
                        action: {
                            viewModel.sendClicked()
                        },
                        label: {
                            Text("\(L10n.send) \(viewModel.model.tokenSymbol)")
                                .foregroundColor(Color(Asset.Colors.snow.color))
                                .font(uiFont: .font(of: .text2, weight: .semibold))
                                .frame(height: 56)
                                .frame(maxWidth: .infinity)
                                .background(Color(Asset.Colors.night.color))
                                .cornerRadius(12)
                                .padding(.horizontal, 24)
                        }
                    )
                    .disabled(viewModel.isRemoving)

                    if !viewModel.model.shouldHideRemoveButtonOnFirstAppearance {
                        Button(
                            action: {
                                viewModel.removeClicked()
                            },
                            label: {
                                Group {
                                    if viewModel.isRemoving {
                                        ProgressView()
                                    } else {
                                        Text(L10n.removeFromHistory)
                                    }
                                }
                                .foregroundColor(Color(Asset.Colors.night.color))
                                .font(uiFont: .font(of: .text2, weight: .semibold))
                                .frame(height: 56)
                                
                            }
                        )
                        .disabled(viewModel.isRemoving)
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .onAppear {
            viewModel.viewDidAppear()
        }
        .navigationBarBackButtonHidden(true)
    }

    private var backgroundColor: Color {
        Color(Asset.Colors.smoke.color)
    }

    private var tokenView: some View {
        VStack(spacing: 16) {
            Image(uiImage: viewModel.model.tokenImage)
                .resizable()
                .frame(width: 64, height: 64)
                .cornerRadius(32)
            VStack(spacing: 4) {
                Text(viewModel.tokenAmount)
                    .foregroundColor(Color(Asset.Colors.night.color))
                    .font(uiFont: .font(of: .largeTitle, weight: .bold))
                Text(viewModel.fiatAmount)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .font(uiFont: .font(of: .text2))
            }
        }
    }

    private var infoBlockView: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(uiImage: .sellPendingWarning)
            Text(L10n
                .ToFinishProcessingYourRequestYouNeedToSendSOLToTheAddressInTheDescription
                .after7DaysThisTransactionWillBeAutomaticallyDeclined
            )
            .foregroundColor(Color(Asset.Colors.night.color))
            .font(uiFont: .font(of: .text3))
        }
        .padding(12)
        .background(Color(Asset.Colors.rain.color))
        .cornerRadius(12)
    }

    private var textView: some View {
        HStack {
            Text(L10n.sendTo)
                .foregroundColor(Color(Asset.Colors.night.color))
                .font(uiFont: .font(of: .text3))
            Spacer()
            HStack(spacing: 8) {
                Text(viewModel.receiverAddress)
                    .foregroundColor(Color(Asset.Colors.mountain.color))
                    .font(uiFont: .font(of: .label1))
                Image(uiImage: .copyReceiverAddress)
            }
            .disabled(viewModel.isRemoving)
            .onTapGesture {
                viewModel.addressCopied()
            }
        }
        .padding(16)
        .background(Color(Asset.Colors.snow.color))
        .cornerRadius(12)
    }
}

struct SellPendingView_Previews: PreviewProvider {
    static var previews: some View {
        SellPendingView(
            viewModel: SellPendingViewModel(
                model: SellPendingViewModel.Model(
                    id: "",
                    tokenImage: .usdc,
                    tokenSymbol: "SOL",
                    tokenAmount: 5,
                    fiatAmount: 300.05,
                    currency: MoonpaySellDataServiceProvider.MoonpayFiat.eur,
                    receiverAddress: "FfRBerfgeritjg43fBeJEr",
                    shouldHideRemoveButtonOnFirstAppearance: false
                )
            )
        )
    }
}
