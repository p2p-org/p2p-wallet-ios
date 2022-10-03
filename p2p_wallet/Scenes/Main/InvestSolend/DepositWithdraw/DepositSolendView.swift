import KeyAppUI
import SwiftUI

struct DepositSolendView: View {
    @SwiftUI.Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @StateObject var viewModel: DepositSolendViewModel
    @State private var showingAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            InvestSolendHeaderView(
                title: viewModel.headerViewTitle,
                logoURLString: viewModel.headerViewLogo,
                subtitle: viewModel.headerViewSubtitle,
                rightTitle: viewModel.headerViewRightTitle,
                rightSubtitle: viewModel.headerViewRightSubtitle
            ).padding(.top, 24)

            Spacer()

            HStack {
                Text(L10n.enterTheAmount)
                    .apply(style: .text3)
                Spacer()
                Button { [weak viewModel] in
                    // use max
                    viewModel?.useMaxTapped()
                    viewModel?.focusSide = .left
                } label: {
                    if viewModel.isUsingMax {
                        Text(L10n.usingTheMAXAmount)
                            .apply(style: .text4)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                    } else {
                        Text(viewModel.maxText)
                            .apply(style: .text4)
                            .foregroundColor(Color(Asset.Colors.sky.color))
                    }
                }
            }.padding(.horizontal, 8)

            DepositWithdrawInputView(
                leftTitle: $viewModel.inputToken,
                leftSubtitle: viewModel.invest.asset.symbol,
                rightTitle: $viewModel.inputFiat,
                rightSubtitle: viewModel.fiat.code,
                activeSide: $viewModel.focusSide,
                inputError: $viewModel.hasError
            ) { [weak viewModel] side in
                viewModel?.focusSide = side
            }
            .padding(.horizontal, 16)

            Group {
                if viewModel.isButtonEnabled {
                    HStack(spacing: 8) {
                        SliderButtonView(
                            title: viewModel.sliderTitle,
                            image: UIImage.arrowRight,
                            style: .black,
                            isOn: .init(get: { [weak viewModel] in
                                viewModel?.isSliderOn ?? false
                            }, set: { [weak viewModel] val in
                                viewModel?.isSliderOn = val
                                presentationMode.wrappedValue.dismiss()
                            })
                        )
                            .disabled(viewModel.loading)
                            .frame(height: TextButton.Size.large.height)
//                        NavigationLink(destination: SolendTransactionDetailsView(model: viewModel.detailItem)) {
//                            Circle()
//                                .fill(Color(Asset.Colors.lime.color))
//                                .frame(width: 56, height: 56)
//                                .overlay(Image(uiImage: UIImage.infoStraight))
//                        }
                        Button {
                            viewModel.showDetail()
                        } label: {
                            Circle()
                                .fill(Color(Asset.Colors.lime.color))
                                .frame(width: 56, height: 56)
                                .overlay(Image(uiImage: UIImage.infoStraight))
                        }
                    }
                } else {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerSize: .init(width: 28, height: 28))
                            .fill(Color(Asset.Colors.rain.color))
                            .overlay(Text(viewModel.buttonText))
                            .frame(height: 56)
                            .transition(.asymmetric(insertion: .scale, removal: .scale).combined(with: .opacity))
                        if viewModel.hasError {
                            Button(action: {
                                showingAlert = true
                            }) {
                                Circle()
                                    .fill(Color(Asset.Colors.rose.color.withAlphaComponent(0.2)))
                                    .frame(width: 56, height: 56)
                                    .overlay(Image(uiImage: UIImage.solendSubtract))
                            }
                            .alert(
                                isPresented: $showingAlert
                            ) {
                                Alert(
                                    title: Text(
                                        L10n.YouAreTryingToDepositMoreFundsThanPossible
                                            .ifYouWantToDepositTheMaximumAmountPressDepositMAXAmount
                                    ),
                                    primaryButton: .default(Text(L10n.depositMAXAmount),
                                                            action: { [weak viewModel] in
                                                                viewModel?.useMaxTapped()
                                                                showingAlert = false
                                                            }),
                                    secondaryButton: .default(Text(L10n.cancel))
                                )
                            }
                        }
                    }
                }
            }
            .transition(.asymmetric(insertion: .scale, removal: .scale).combined(with: .opacity))
            .animation(.easeOut(duration: 0.1), value: viewModel.isButtonEnabled)
            .padding(.top, 8)

            HStack {
                Spacer()
                if viewModel.loading {
                    ActivityIndicator(isAnimating: viewModel.loading)
                        .frame(width: 16, height: 16)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                } else {
                    Text(viewModel.feeText)
                        .apply(style: .text4)
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(Asset.Colors.mountain.color))
                        .frame(minHeight: 16)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .navigationTitle(viewModel.title)
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
