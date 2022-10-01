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
                Button { [weak viewModel] in
                    //use max
                    viewModel?.useMaxTapped()
                    viewModel?.focusSide = .left
                } label: {
                    if viewModel.isUsingMax {
                        Text("✅ Using the MAX amount")
                            .apply(style: .text4)
                            .foregroundColor(Color(Asset.Colors.mountain.color))
                    } else {
                        Text(viewModel.maxText)
                            .apply(style: .text4)
                            .foregroundColor(Color(Asset.Colors.sky.color))
                    }
                }
            }.padding(.horizontal, 8)

          BuyInputOutputView(
            leftTitle: $viewModel.inputToken,
            leftSubtitle: viewModel.invest.asset.symbol,
            rightTitle: $viewModel.inputFiat,
            rightSubtitle: viewModel.fiat.code,
            activeSide: $viewModel.focusSide) { [weak viewModel] side in
                viewModel?.focusSide = side
            }
                .padding(.horizontal, 16)

            Group {
                if viewModel.isButtonEnabled {
                    HStack(spacing: 8) {
                        SliderButtonView(
                            title: "Slide to deposit",
                            image: Asset.MaterialIcon.arrowRight.image,
                            style: .black,
                            isOn: .init(get: {
                                viewModel.isDepositOn
                            }, set: { val in
                                viewModel.isDepositOn = val
                            })
                        )
                        .disabled(viewModel.loading)
                        .frame(height: TextButton.Size.large.height)
                        Button {
                            // Open info
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
                            Circle()
                                .fill(Color(Asset.Colors.rose.color.withAlphaComponent(0.2)))
                                .frame(width: 56, height: 56)
                                .overlay(Image(uiImage: UIImage.solendSubtract))
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
